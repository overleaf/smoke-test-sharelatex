Mocha = require "mocha"
Base = require("mocha/lib/reporters/base")

module.exports =
	run: (smokeTestPath, timeout = 10000) ->
		return (req, res, next) ->
			mocha = new Mocha(reporter: Reporter(res), timeout: timeout)
			mocha.addFile(smokeTestPath)
			mocha.run () ->
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

