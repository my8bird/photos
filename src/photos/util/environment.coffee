module.exports = (app, express) ->

    app.configure () ->
       app.use express.logger()

    app.configure 'development', () ->
       app.use express.errorHandler {
          dumpExceptions: true
          showStack     : true
       }

    app.configure 'production', () ->
      app.use(express.errorHandler())
