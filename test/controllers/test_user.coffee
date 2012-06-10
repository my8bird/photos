{routes} = require 'controllers/user'
should   = require 'should'

{startServer, shutdownServer, restClient} = require 'test/util'


describe 'User REST Handlers', () ->
   beforeEach () ->
      startServer()

   afterEach () ->
      shutdownServer()

   it 'should fail to add data if body is not JSON', (done) ->
      await restClient.post '/user', defer(err, buf, res)
      should.not.exist(err)
      res.statusCode.should.equal(400)
      done()
