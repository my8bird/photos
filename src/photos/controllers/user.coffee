{ObjectID}   = require 'mongodb'
{Collection} = require 'photos/util/database'

assert = require "assert"


error = (res, text, statusCode = 500) ->
   res.send(text, statusCode)


User = (data) ->
   assert data.name, 'Invalid name'
   return {
      _id:  new ObjectID()
      name: data.name
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
   database.getCollection("user").find {}, (err, cursor) ->
      cursor.toArray (err, items) ->
         res.json({"users": items})


createUser = (req, res, next) ->
   """
   Creates a user and return the uri that can be used get/update the user in the future

   Input:
       {
         "name": "users name"
       }
   """
   if not req.is("json")
      return error(res, 'JSON body is required', 400)

   try
      user = User(req.body)
   catch err
      return error(res, 'JSON input invalid', 400)

   await _storeUser(user, defer(err, stored_user))
   if err then return error(res, err, 500)

   res.header 'location', "/user/#{stored_user._id}"
   res.send(201)



getUser = (req, res, next) ->
   try
     user_id = new ObjectID(req.params.id)
   catch err
     return error(res, 'Id is not valid', 400)

   await Collection("user").findOne {_id: user_id}, defer(err, user)
   if err then return error(res, err, 500)

   if user is null
      return error(res, 'User not found', 404)

   res.json(user)



updateUser = (req, res, next) ->
   assert req.is("json")
   user_id = req.params.id

   updated_user = User(req.body)

   database.getCollection("user").update(
      {_id: new ObjectID(user_id)},
      {$set: {name: updated_user.name}},
      (err) ->
         res.json(updated_user)
   )


module.exports =
   routes:
      '/user': [
         {type: 'GET',  handler: listUsers},
         {type: 'POST', handler: createUser}
         ]
      '/user/:id': [
         {type: 'GET', handler: getUser},
         {type: 'PUT', handler: updateUser}
         ]