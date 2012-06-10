#! ./node_modules/.bin/iced

express  = require 'express'
optimist = require 'optimist'


parseOptions = () ->
   # Setup CLI options
   opts = optimist.
       describe('help', 'Show Help Message').

       describe('p', 'Port Number').
       alias(   'p', 'port').
       default( 'p', 8000).

       describe('h', 'Hostname').
       alias(   'h', 'host').
       default( 'h', 'localhost')

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
      res.render '500', {error: err}

   app.use express.static(__dirname + '../static')
   app.use express.bodyParser()

   require('util/environment')(app, express)
   require('util/routes')(app)

   return app


exports.configDatabase = configDatabase = (host, port) ->
   require('util/database').setup(host, port)


startApp = (host, port) ->
   # Now that everything is ready start the app
   app.listen port, host
   console.log "Listening at http://#{host}:#{port}"


if require.main == module
   argv = parseOptions()
   buildApp()
   configDatabase(argv.db_host, argv.db_port)
   startApp(argv.host, argv.port)
