{ObjectId} = require 'mongodb'

{routes} = require 'photos/controllers/user'
assert   = require 'assert'

{startServer, shutdownServer, clearDatabase, restClient} = require 'test/util'

{Collection} = require 'photos/util/database'

json_headers = {'content-type': 'application/json'}

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
      assert.equal 201, res.statusCode

      location_parts = /\/user\/(.{24})/.exec res.headers['location']
      assert location_parts isnt null
      user_id = location_parts[1]

      await Collection 'user', defer(err, User)

      await User.findOne {_id: user_id}, defer(err, user_doc)
      assert.ifError err, 'Error getting new user doc'

      assert 'woot', user_doc.name

      # Make sure the user was really added
      done()
