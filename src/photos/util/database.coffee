{Server, Db} = require 'mongodb'

_server = _db = null

exports.setup = (host, port, dbName, cb) ->
   _server = new Server('localhost', 27017, {auto_reconnect: true})
   _db     = new Db(dbName, _server)

   _db.open (err, db) ->
      cb(err)

exports.cleanup = (cb) ->
   await _db.collections defer(err, info)

   await
      err = {}
      for {collectionName: collection} in info
         if collection != 'system.indexes'
            _db.dropCollection collection, defer(err[collection])

   collections_with_error = (c for c, e of err when e)
   if 0 < collections_with_error.length
      cb(new Error("Collections were not cleaned up: #{collections_with_error}"))
   else
      cb()


exports.Collection = (name, cb) ->
   _db.collection name, cb
