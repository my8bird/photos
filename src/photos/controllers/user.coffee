{ObjectID}   = require 'mongodb'
{Collection} = require 'photos/util/database'

assert = require "assert"


error = (res, text, statusCode = 500) ->
   res.send(text, statusCode)


User = (data) ->
   assert data.name, 'Invalid name'
   return {
      _id:  ''+new ObjectID()
      name: data.name
      }


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

   await Collection('user', defer(err, collection))
   if err then return error(res, 'DB error', 500)

   await collection.insert(user, defer(err, docs))
   if err then return error(res, 'Unable to save new user', 500)

   res.header 'content-type', 'application/json'
   res.header 'location',     "/user/#{docs[0]._id}"

   res.send('Created', 201)


getUser = (req, res, next) ->
   user_id = req.params.id

   database.getCollection("user").findOne {_id: new ObjectID(user_id)}, (err, user) ->
      if err
         throw err
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
