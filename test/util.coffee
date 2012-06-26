database = require 'photos/util/database'
app      = require '../app'

_        = require 'underscore'
http     = require 'http'
assert   = require 'assert'

server =
   host: 'localhost'
   port: 8000

db =
   host: 'localhost'
   port: 27017
   name: 'photos_test'


_server = null
exports.startServer = (cb) ->
   _server = app.buildApp()

   await app.configDatabase db.host, db.port, db.name, defer(err)
   assert.ifError err

   await _server.listen server.port, server.host, defer(err)
   assert.ifError err
   cb(err)

exports.shutdownServer = (cb) ->
   await
      database.cleanup defer()
      _server.close()
      _server = null
   cb()

exports.clearDatabase = (cb) ->
   database.cleanup cb

isJson = (res) ->
   return null != /application\/json/.exec res.headers['content-type']


class RestClient
   constructor: (@host, @port) ->

   get: (url, headers, cb) =>
      @_sendRequest('GET', url, null, headers, cb)

   post: (url, body, headers, cb) =>
      @_sendRequest('POST', url, body, headers, cb)

   delete: (url, body, headers, cb) =>
      @_sendRequest('DELETE', url, body, headers, cb)

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
