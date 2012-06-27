{ObjectID}   = require 'mongodb'
{Collection} = require 'photos/util/database'
assert       = require 'assert'
_            = require 'underscore'
bcrypt       = require 'bcrypt'

{error, parseDocId, requireJson} = require './helpers'
{check, sanitize}                = require('validator')


parseUser = (data) ->
   """
   User validation and base object type
   """
   # Validate the input data
   check(data.name)
   check(data.email).isEmail()

   # Create the User
   return {
      name:  sanitize(data.name).xss().trim()
      email: sanitize(data.email).xss().trim()
      }


_storeUser = (user, cb) ->
   """
   Helper which
   """
   await Collection('user', defer(err, collection))
   if err then return cb('DB error')

   await collection.insert(user, defer(err, docs))
   if err then return cb('Unable to save new user')

   cb(null, docs[0])


listUsers = (req, res, next) ->
   """
   Returns the full list of all users
   """
   # Pull out the query args
   limit  = sanitize(req.query.limit).toInt()
   offset = sanitize(req.query.offset).toInt()

   check(limit).min(0)
   check(offset).min(0)

   # Retrieve user's from the database sorted by their added date
   query = Collection("user").find().sort([['added_on', 1]])
   # Since this is Mongo be sure to limit the data returned to the pieces needed
   query.fields =
     _id:   1
     name:  1
     email: 1

   # Add the query args as needed to allow pagination
   if offset
     query.skip(parseInt(offset))
   if limit
     query.limit(parseInt(limit, 10))

   query.toArray (err, items) ->
     res.json({"items": items})


createUser = (req, res, next) ->
   """
   Creates a user and return the uri that can be used get/update the user in the future

   @see User parser for input JSON format
   """
   # XXX fail if user already exists
   try
      # Grab the basic user data
      user = parseUser(req.body)

      # When creating a new user we need to get the auth process started.
      password = req.body.password
      check(password).len(6)
   catch err
      return error(res, err.message, 400)

   # Tack on the date so that we know when the user was first seen.
   user.added_on = new Date().toISOString()

   # Give the user and id
   user._id = new ObjectID()

   # Generate the per user salt and use it to generate the hash for this user.
   await bcrypt.genSalt(defer(err, user_salt))
   if err then return error(res, err, 500)

   await bcrypt.hash(password, user_salt, defer(err, hash_pass))
   user.auth =
      salt: user_salt
      hash: hash_pass

   # Store the user into the database
   await _storeUser(user, defer(err, stored_user))
   if err then return error(res, err, 500)

   # Notify the caller that the user was added.
   res.header 'location', "/user/#{stored_user._id}"
   ret_user = _.pick(stored_user, '_id', 'name', 'email')
   res.json(ret_user, 201)


getUser = (req, res, next) ->
   await Collection("user").findOne {_id: req.docId}, defer(err, user)
   if err then return error(res, err, 500)

   if user is null
      return error(res, 'User not found', 404)

   res.json(user)


updateUser = (req, res, next) ->
   try
      new_user = parseUser(req.body)
   catch err
      return error(res, 'JSON input invalid', 400)

   await Collection("user").findOne {_id: req.docId}, defer(err, user)
   if err          then return error(res, err, 500)
   if user is null then return error(res, 'User does not exist', 400)

   # Merge the updates into the databases version
   _.defaults(new_user, _.pick(user, 'name', 'email'))

   # Save the changes out to the database
   await Collection("user").update({_id: req.docId}, {$set: new_user}, defer(err))
   if err then return error(res, err, 500)

   # Let the user know things went well
   res.send(200)


removeUser = (req, res, next) ->
   await Collection("user").remove({_id: req.docId}, defer(err))
   if err then return error(res, err, 500)

   res.send(200)


module.exports =
   routes:
      '/user': [
         {type: 'GET',  handler: listUsers},
         {type: 'POST', handler: requireJson(createUser)}
         ]
      '/user/:id': [
         {type: 'GET',    handler: parseDocId(getUser)},
         {type: 'PUT',    handler: requireJson(parseDocId(updateUser))},
         {type: 'DELETE', handler: parseDocId(removeUser)}
         ]
