{GraphDatabase} = require 'neo4j'
assert          = require 'assert'

_connection = null

exports.setup = (host, port) ->
   assert _connection is null, 'Connection already created'
   _connection = new GraphDatabase "http://#{host}:#{port}"

exports.cleanup = () ->
   _connection = null

exports.getDB = () ->
   assert _connection isnt null, 'Connection not created'
   return _connection
