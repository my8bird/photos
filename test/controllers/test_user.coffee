{ObjectID} = require 'mongodb'

{routes} = require 'photos/controllers/user'
assert   = require 'assert'
_        = require 'underscore'

{startServer, shutdownServer, clearDatabase, restClient} = require 'test/util'

{Collection} = require 'photos/util/database'

json_headers = {'content-type': 'application/json'}


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
      await restClient.post '/user', {name: 'woot'}, json_headers, defer(err, buf, res)
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
      await restClient.post '/user', {name: 'woot'}, json_headers, defer(err, buf, res)
      assert.ifError err
      assert.equal 201, res.statusCode

      # GET the user
      uri = res.headers['location']
      await restClient.get uri, {}, defer(err, user, res)
      assert.equal 200, res.statusCode
      assert.equal 'woot', user.name

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
