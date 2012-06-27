#! ./node_modules/.bin/iced

express  = require 'express'
optimist = require 'optimist'

# The Express Application
app = null


parseOptions = () ->
   # Setup CLI options
   opts = optimist.
       describe('help', 'Show Help Message').

       describe('p', 'Port Number').
       alias(   'p', 'port').
       default( 'p', 3000).

       describe('h', 'Hostname').
       alias(   'h', 'host').
       default( 'h', 'localhost').

       describe('db_port', 'Database Port Number').
       default( 'db_port', 27017).

       describe('db_host', 'Database Hostname').
       default( 'db_host', 'localhost')

       describe('db_name', 'Database Name').
       default( 'db_name', 'photos')

   # Show help if required and exit
   if opts.argv.help
      console.log opts.help()
      process.exit(0)

   opts.argv

exports.buildApp = buildApp = () ->
   app = express.createServer()
   app.set 'view engine', 'jade'
   app.set 'view options', { layout: false }

   app.error (err, req, res, next) ->
      if req.is('html')
         res.render '500', {error: err}
      else
         res.send(err.message, 500)

      throw err

   app.use express.static(__dirname + '../static')
   app.use express.bodyParser()

   require('photos/util/environment')(app, express)
   require('photos/util/routes')(app)

   return app


exports.configDatabase = configDatabase = (host, port, dbName, cb) ->
   require('photos/util/database').setup(host, port, dbName, cb)


startApp = (host, port) ->
   # Now that everything is ready start the app
   app.listen port, host
   console.log "Listening at http://#{host}:#{port}"


if require.main == module
   argv = parseOptions()

   buildApp()

   await configDatabase(argv.db_host, argv.db_port, argv.db_name, defer(err))
   if err then return console.error err

   startApp(argv.host, argv.port)
