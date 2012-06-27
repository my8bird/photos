controllers = [
   'user', 'auth'
]

module.exports = (app) ->
   controllers.map (controllerName) ->
      mod = require '../controllers/' + controllerName
      for route of mod.routes
         for config in mod.routes[route]
            console.log "Adding #{config.type} #{route}"
            app[config.type.toLowerCase()](route, config.handler)
