{ObjectID}   = require 'mongodb'
{Collection} = require 'photos/util/database'

assert = require 'assert'
_      = require 'underscore'

{error, parseDocId, requireJson} = require './helpers'


{check, sanitize} = require('validator')
User = (data) ->
   check(data.name)
   check(data.email).isEmail()

   return {
      _id:   new ObjectID()
      name:  sanitize(data.name).xss().trim()
      email: sanitize(data.email).xss().trim()
      }

_storeUser = (user, cb) ->
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
   limit  = req.query.limit
   offset = req.query.offset

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
   try
      user = User(req.body)
   catch err
      return error(res, 'JSON input invalid', 400)

   # Tack on the date so that we know when the user was first seen.
   user.added_on = new Date().toISOString()

   # Store the user into the database
   await _storeUser(user, defer(err, stored_user))
   if err then return error(res, err, 500)

   # Notify the caller that the user was added.
   res.header 'location', "/user/#{stored_user._id}"
   res.send(201)


getUser = (req, res, next) ->
   await Collection("user").findOne {_id: req.docId}, defer(err, user)
   if err then return error(res, err, 500)

   if user is null
      return error(res, 'User not found', 404)

   res.json(user)


updateUser = (req, res, next) ->
   try
      new_user = User(req.body)
   catch err
      return error(res, 'JSON input invalid', 400)

   await Collection("user").findOne {_id: req.docId}, defer(err, user)
   if err          then return error(res, err, 500)
   if user is null then return error(res, 'User does not exist', 400)

   _.defaults(new_user, user)
   delete new_user['_id']

   await Collection("user").update({_id: req.docId}, {$set: new_user}, defer(err))
   if err then return error(res, err, 500)

   res.json(new_user)


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
