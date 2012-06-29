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
            _db.collection(collection).remove defer(err[collection])

   collections_with_error = (c for c, e of err when e)
   if 0 < collections_with_error.length
      cb(new Error("Collections were not cleaned up: #{collections_with_error}"))
   else
      cb()


exports.Collection = Collection = (name) ->
   return _db.collection(name)


exports.dropAllData = (cb) ->
   await _db.collections(defer(err, collections))
   await
      err = {}
      for collection in collections
         if collection.collectionName != 'system.indexes'
            collection.drop defer(err[collection.collectionName])

   collections_with_error = (c for c, e of err when e)
   if 0 < collections_with_error.length
      cb(new Error("Collections were not removed: #{collections_with_error}"))
   else
      cb()


exports.migrate = (cb) ->
   # Add collections
   User    = Collection('user')
   Session = Collection('session')

   # Add indexes
   index_error = (collection, err) ->
      if err
         return cb(new Error("Unable to add index to #{collection}: #{err.message}"))
   await
      User.ensureIndex({'email': 1}, {unique: true}, defer(err_user))
      if err_user then return index_error('user', err_user)

      Session.ensureIndex({'email': 1}, {expireAfterSeconds: 3600}, defer(err_session))
      if err_user then return index_error('session', err_user)

   console.log "############ Database Ready ################"

   cb()
