{ObjectID}   = require 'mongodb'
{Collection} = require 'photos/util/database'
assert       = require 'assert'
_            = require 'underscore'
bcrypt       = require 'bcrypt'

{error, parseDocId, requireJson} = require './helpers'
{check, sanitize}                = require('validator')


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

   await bcrypt.compare(password, user.auth.hash, defer(err, matched))

   if matched
      res.send(200)
   else
      res.send(401) # Unauthorized


logout = (req, res, next) ->


module.exports =
   routes:
      '/login': [
         {type: 'POST', handler: requireJson(login)}
         ]
      '/logout': [
         {type: 'GET', handler: logout}
         ]
