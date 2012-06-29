database = require 'photos/util/database'
app      = require '../app'

_        = require 'underscore'
http     = require 'http'
assert   = require 'assert'

#{ Test framework helpers
server =
   host: 'localhost'
   port: 8000

   ready: false

db =
   host:  'localhost'
   port:  27017
   name:  'photos_test'


exports.ServerTestMixin = () ->
   _server = null

   before (done) ->
      if server.ready
         return done()

      # Build the app
      _server = app.buildApp()

      # Get the database up and running
      await app.configDatabase db.host, db.port, db.name, defer(err)
      if err then return done(err)

      # Ensure the database is setup correctly
      await database.dropAllData defer(err)
      if err then return done(err)

      await database.migrate(defer(err))
      if err then return done(err)

      # Start the server running
      await _server.listen server.port, server.host, defer(err)
      if err then return done(err)

      # Signal that the server is running so other tests do not need
      # to go through the setup
      server.ready = true

      # Start running the tests
      done()

   beforeEach (done) ->
      # Make sure to clear the database before running so that we do not
      # collide with other tests data.
      database.cleanup(done)
#}


isJson = (res) ->
   return null != /application\/json/.exec res.headers['content-type']


class RestClient
   constructor: (@host, @port) ->

   get: (url, headers, cb) =>
      @_sendRequest('GET', url, null, headers, cb)

   post: (url, body, headers, cb) =>
      @_sendRequest('POST', url, body, headers, cb)

   delete: (url, headers, cb) =>
      @_sendRequest('DELETE', url, null, headers, cb)

   put: (url, body, headers, cb) =>
      @_sendRequest('PUT', url, body, headers, cb)

   _sendRequest: (method, url, body, headers, cb) =>
      options =
         host:    @host
         port:    @port
         path:    url
         method:  method
         headers: headers

      req = http.request options, (res) ->
         buffers = []
         data_len = 0

         res.on 'data', (data) ->
            buffers.push(data)
            data_len = data_len + data.length

         res.on 'end', () ->
            buffer = new Buffer(data_len)
            pos = 0
            for buf in buffers
               buf.copy(buffer, pos)
               pos += buf.length

            data = buffer.toString()
            if isJson(res)
               data = JSON.parse(data)

            cb(null, data, res)

      if body
         req.write(JSON.stringify(body))

      req.end()

      req.on 'error', (err) ->
         console.log err
         assert.ifError err

exports.restClient = new RestClient(server.host, server.port)
