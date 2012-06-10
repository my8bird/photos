{spawn} = require('child_process')

#
# Options which can be passed in
#
option '-w', '--watch', 'Watch files and run tests'


# Ensure the project is loaded correctly
process.env['NODE_PATH'] = __dirname + ':' + __dirname+'/src'

# Ensure we can find npm packages easily
# XXX not windows friendly
process.env['PATH'] = __dirname+'/node_modules/.bin:' + process.env['PATH']


# Helper for running commands
run = (cmd, args, cb) ->
   proc = spawn(cmd, args)

   proc.stdout.on 'data', (buf) ->
      process.stdout.write(buf)

   proc.stderr.on 'data', (buf) ->
      process.stderr.write(buf)

   proc.on 'exit', (code) ->
      cb(code)

task 'test', 'run all tests', (options) ->
  # Build up command
  runner = "mocha"
  args   = ["--compilers", "coffee:iced-coffee-script",
           "--require", "should",
           "--reporter", "spec",
           "--colors",
           "--recursive",
           "--regex", ".*test_.*\.coffee",
           "--ignore-leaks",
           "test/"]

  if options.watch
    args.push('--watch')

  # Run tests
  await run(runner, args, defer(status))

  # Exit with non-zero if test suite failed
  if status > 0
     process.exit(status)
