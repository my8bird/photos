database = require 'photos/util/database'
app      = require '../app'

http     = require 'http'

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
   if err then return cb(err)

   _server.listen server.port, server.host
   cb(null)

exports.shutdownServer = (cb) ->
   await
      database.cleanup defer()
      _server.close()
      _server = null
   cb()

exports.clearDatabase = (cb) ->
   database.cleanup cb


class RestClient
   constructor: (@host, @port) ->

   get: (url, body, headers, cb) =>
      @_sendRequest('GET', url, body, headers, cb)

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
         buffer   = ''
         res.on 'data', (data) ->
            buffer += data

         res.on 'end', () ->
            cb(null, buffer, res)

      req.write(JSON.stringify(body))

      req.end()
      req.on 'error', (err) ->
         cb(err)

exports.restClient = new RestClient(server.host, server.port)
