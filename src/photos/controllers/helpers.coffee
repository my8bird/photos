{ObjectID}   = require 'mongodb'
crypto       = require 'crypto'


exports.hashPassword = (password, salt, done) ->
   crypto.pbkdf2(password, salt, 1000, 64, done)


exports.error = error = (res, text, statusCode = 500) ->
   res.send(text, statusCode)
   return text


exports.parseDocId = (inner) ->
  return (req, res, next) ->
    try
      doc_id = new ObjectID(req.params.id)
    catch err
      return error(res, 'Id is not valid', 400)

    req.docId = doc_id
    inner(req, res, next)


exports.requireJson = (inner) ->
   return (req, res, next) ->
     if not req.is("json")
       return error(res, 'JSON body is required', 400)

     inner(req, res, next)
