Mocha = require "mocha"
Base = require("mocha/lib/reporters/base")

module.exports =
	run: (smokeTestPath, timeout = 10000) ->
		return (req, res, next) ->
			mocha = new Mocha(reporter: Reporter(res), timeout: timeout)
			mocha.addFile(smokeTestPath) # this requires the module as a child of mocha
			mocha.run () ->
				# we need to clean up all references to the smokeTest module
				# so it can be garbage collected.  The only reference should
				# be in its parent, when it is loaded by mocha.addFile.
				smokeTestModule = require.cache[smokeTestPath]
				# handle one smoke test removing module while another is running
				return if not smokeTestModule?
				parent = smokeTestModule.parent
				while (idx = parent.children.indexOf(smokeTestModule)) != -1
					parent.children.splice(idx, 1)
				# remove the smokeTest from the module cache
				delete require.cache[smokeTestPath]

HealthCheckController =
	check: (req, res, next = (error) ->) ->
		
Reporter = (res) ->
	(runner) ->
		Base.call(this, runner)

		tests = []
		passes = []
		failures = []

		runner.on 'test end', (test) -> tests.push(test)
		runner.on 'pass',     (test) -> passes.push(test)
		runner.on 'fail',     (test) -> failures.push(test)

		runner.on 'end', () =>
			clean = (test) ->
				title: test.fullTitle()
				duration: test.duration
				err: test.err
				timedOut: test.timedOut

			results = {
				stats: @stats
				failures: failures.map(clean)
				passes: passes.map(clean)
			}

			res.contentType("application/json")
			if failures.length > 0
				res.send 500, JSON.stringify(results, null, 2)
			else
				res.send 200, JSON.stringify(results, null, 2)

