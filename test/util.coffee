database = require 'util/database'
app      = require 'app'

http     = require 'http'

server =
   host: 'localhost'
   port: 8000

neo =
   host: 'localhost'
   port: 7474


_server = null
exports.startServer = () ->
   _server = app.buildApp()
   app.configDatabase neo.host, neo.port
   _server.listen server.port, server.host

exports.shutdownServer = () ->
   database.cleanup()
   _server.close()
   _server = null


class RestClient
   constructor: (@host, @port) ->

   get: (url, cb) =>
      @_sendRequest('GET', url, cb)
   post: (url, cb) =>
      @_sendRequest('POST', url, cb)
   delete: (url, cb) =>
      @_sendRequest('DELETE', url, cb)
   put: (url, cb) =>
      @_sendRequest('PUT', url, cb)

   _sendRequest: (method, url, cb) =>
      options =
         host:   @host
         port:   @port
         path:   url
         method: method

      req = http.request options, (res) ->
         buffer   = ''
         res.on 'data', (data) ->
            buffer += data

         res.on 'end', () ->
            cb(null, buffer, res)

      req.end()
      req.on 'error', (err) ->
         cb(err)

exports.restClient = new RestClient(server.host, server.port)
