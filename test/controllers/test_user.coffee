{ObjectID} = require 'mongodb'

{routes} = require 'photos/controllers/user'
assert   = require 'assert'
_        = require 'underscore'

{startServer, shutdownServer, clearDatabase, restClient} = require 'test/util'

{Collection} = require 'photos/util/database'

json_headers = {'content-type': 'application/json'}


addUser = (data, cb) ->
  if _.isFunction(data)
    cb = data
    data = {name: 'bobo', email: 'clown@school.com'}

  await restClient.post '/user', data, json_headers, defer(err, user, res)
  assert.ifError err
  assert.equal 201, res.statusCode

  cb(res.headers['location'])


assert_object = (object, expected) ->
   """
   Loop over the object and make sure all of the expect keys are there.
   """
   assert.ok object, 'Object must not be null'
   for key, value of expected
      found = _.values(_.pick(object, key))[0]
      assert.equal value, found, "#{key} was #{JSON.stringify(found)} not #{value}"


assert_user_exists = (_id, cb) ->
   """
   Attempt to grab the user from the database assert if an error happens.
   cb gets called with the user instance.
   """
   # Grab the collection
   await Collection 'user', defer(err, User)

   # Look up the document
   await User.findOne {_id: new ObjectID(_id)}, defer(err, user_doc)
   # raise error if something went wrong
   assert.ifError err, 'Error getting new user doc'

   cb(err, user_doc)


describe 'User REST Handlers', () ->
   before (done) ->
      startServer done

   after (done) ->
      shutdownServer done

   afterEach (done) ->
      clearDatabase done

   it 'should fail to add data if body is not JSON', (done) ->
      # there are no headers so the mime type check fails
      await restClient.post '/user', {}, {}, defer(err, buf, res)
      assert.equal 400, res.statusCode

      # The mime type is set wrong
      await restClient.post '/user', {}, {'content-type': 'text/plain'}, defer(err, buf, res)
      assert.equal 400, res.statusCode
      done()

   it 'should fail to add data if body does not have required keys', (done) ->
      await restClient.post '/user', {}, json_headers, defer(err, buf, res)
      assert.equal buf, 'JSON input invalid'
      assert.equal 400, res.statusCode
      done()

   it 'should add new user', (done) ->
      # Add the user
      await restClient.post '/user', {name: 'woot', email: 'woot@ding.com'},
                   json_headers, defer(err, buf, res)
      assert.ifError err
      assert.equal 201, res.statusCode

      location_parts = /\/user\/(.{24})/.exec res.headers['location']
      assert location_parts isnt null
      user_id = location_parts[1]

      # Make sure the user was really added
      await assert_user_exists user_id, defer(err, user)
      assert.equal 'woot', user.name

      done()

   it 'should allow retrieving a saved user', (done) ->
      # Add the user
      await addUser defer(user_uri)

      # GET the user
      await restClient.get user_uri, {}, defer(err, user, res)
      assert.equal 200, res.statusCode
      assert.equal 'bobo', user.name

      done()

   it 'should fail to retrieve missing user', (done) ->
      # GET the user that does not exist
      uri = "/user/#{new ObjectID()}"
      await restClient.get uri, {}, defer(err, data, res)
      assert.equal 404, res.statusCode
      assert.equal 'User not found', data

      done()

   it 'should fail on invalid id', (done) ->
      # GET the user that has invalid id
      uri = "/user/1324"
      await restClient.get uri, {}, defer(err, data, res)
      assert.equal 400, res.statusCode
      assert.equal 'Id is not valid', data

      done()

   it 'should allow updating a saved user', (done) ->
      # Add an user
      await addUser defer(user_uri)

      # Update the user
      await restClient.put user_uri, {name: 'new name', email: 'new@email.com'},
              json_headers, defer(err, user, res)
      assert.equal 200, res.statusCode
      assert.equal 'new name', user.name

      done()

   it 'should allow removing a saved user', (done) ->
      # Add an user
      await addUser defer(user_uri)

      # Update the user
      await restClient.delete user_uri, {}, defer(err, data, res)
      assert.equal 200, res.statusCode

      done()

   it 'should list all users in the system', (done) ->
      # Add some users (add serially so that we know the return order)
      await addUser {name: 'user1', email: 'd1@d.com'}, defer(user1_uri)
      await addUser {name: 'user2', email: 'd2@d.com'}, defer(user2_uri)

      await restClient.get '/user', {}, defer(err, data, res)
      assert.equal 200, res.statusCode

      users = data.items
      assert.equal 2, users.length
      assert_object users[0], {name: 'user1', email: 'd1@d.com'}
      assert_object users[1], {name: 'user2', email: 'd2@d.com'}

      done()

   it 'should list users up to limit', (done) ->
      # Add some users (add serially so that we know the return order)
      await addUser {name: 'user1', email: 'd1@d.com'}, defer(user1_uri)
      await addUser {name: 'user2', email: 'd2@d.com'}, defer(user2_uri)

      # Grab only one user
      await restClient.get '/user?limit=1', {}, defer(err, data, res)
      assert.equal 200, res.statusCode

      users = data.items
      assert.equal 1, users.length
      assert_object users[0], {name: 'user1', email: 'd1@d.com'}

      # Grab the next page of users
      await restClient.get '/user?offset=1&limit=1', {}, defer(err, data, res)

      assert.equal 200, res.statusCode


      users = data.items
      assert.equal 1, users.length
      assert_object users[0], {name: 'user2', email: 'd2@d.com'}

      done()
