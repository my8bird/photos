{ObjectID}        = require 'mongodb'
{Collection}      = require 'photos/util/database'
assert            = require 'assert'
_                 = require 'underscore'
crypto            = require 'crypto'
{check, sanitize} = require('validator')

{error, parseDocId, requireJson, hashPassword} = require './helpers'


parseAuth = (data) ->
   """
   User validation and base object type
   """
   # Validate the input data
   check(data.email).isEmail()
   check(data.password).min(5)

   # Create the User
   return {
      email:     data.email
      password: data.password
      }


login = (req, res, next) ->
   try
      {email, password} = parseAuth(req.body)
   catch err
      return error(res, err.message, 400)

   await Collection('user').findOne {email: email}, {}, defer(err, user)
   if err          then return error(res, err.message, 500)
   if user is null then return error(res, 'User with email not found', 400)

   await hashPassword(password, user.auth.salt, defer(err, hashed))
   if err then return error(res, err, 500)

   if user.auth.hash != hashed
      res.send(401) # Unauthorized

   await crypto.randomBytes(48, defer(ex, buf))
   token = buf.toString('base64')

   res.send(token, 200)



logout = (req, res, next) ->


module.exports =
   routes:
      '/login': [
         {type: 'POST', handler: requireJson(login)}
         ]
      '/logout': [
         {type: 'GET', handler: logout}
         ]
