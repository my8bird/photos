{ObjectID} = require 'mongodb'

{routes} = require 'photos/controllers/user'
assert   = require 'assert'
_        = require 'underscore'

{ServerTestMixin, restClient} = require 'test/util'

{Collection} = require 'photos/util/database'


json_header = {'content-type': 'application/json'}

addUser = (data, cb) ->
   if _.isFunction(data)
      cb = data
      data = {name: 'bobo', email: 'clown@school.com', password: 'password'}

   await restClient.post '/user', data, json_header, defer(err, user, res)
   assert.ifError err
   assert.equal 201, res.statusCode

   cb(user, res.headers['location'])


describe 'User Authentication Handlers', () ->
   ServerTestMixin()

   it 'should allow users to login in', (done) ->
      # Add a user which will take care of setting the password
      await addUser defer(user)

      data = {email: user.email, password: 'password'}
      await restClient.post '/login', data, json_header, defer(err, buf, res)
      assert.ifError err
      assert.equal 200, res.statusCode

      # A token was returned
      assert.equal 64, buf.length

      # And the token was saved to the user so we can find it later

      done()

   it 'should block users with invalid password', (done) ->
      # Add a user which will take care of setting the password
      await addUser defer(user)

      data = {email: user.email, password: 'invalid'}
      await restClient.post '/login', data, json_header, defer(err, buf, res)
      assert.ifError err
      assert.equal 401, res.statusCode

      done()
