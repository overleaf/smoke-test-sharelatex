(function() {
  var Base, HealthCheckController, Mocha, Reporter;

  Mocha = require("mocha");

  Base = require("mocha/lib/reporters/base");

  module.exports = {
    run: function(smokeTestPath, timeout) {
      if (timeout == null) {
        timeout = 10000;
      }
      return function(req, res, next) {
        var mocha;
        mocha = new Mocha({
          reporter: Reporter(res),
          timeout: timeout
        });
        mocha.addFile(smokeTestPath);
        return mocha.run(function() {
          var idx, parent, smokeTestModule;
          smokeTestModule = require.cache[smokeTestPath];
          if (smokeTestModule == null) {
            return;
          }
          parent = smokeTestModule.parent;
          while ((idx = parent.children.indexOf(smokeTestModule)) !== -1) {
            parent.children.splice(idx, 1);
          }
          return delete require.cache[smokeTestPath];
        });
      };
    }
  };

  HealthCheckController = {
    check: function(req, res, next) {
      if (next == null) {
        next = function(error) {};
      }
    }
  };

  Reporter = function(res) {
    return function(runner) {
      var failures, passes, tests,
        _this = this;
      Base.call(this, runner);
      tests = [];
      passes = [];
      failures = [];
      runner.on('test end', function(test) {
        return tests.push(test);
      });
      runner.on('pass', function(test) {
        return passes.push(test);
      });
      runner.on('fail', function(test) {
        return failures.push(test);
      });
      return runner.on('end', function() {
        var clean, results;
        clean = function(test) {
          return {
            title: test.fullTitle(),
            duration: test.duration,
            err: test.err,
            timedOut: test.timedOut
          };
        };
        results = {
          stats: _this.stats,
          failures: failures.map(clean),
          passes: passes.map(clean)
        };
        res.contentType("application/json");
        if (failures.length > 0) {
          return res.send(500, JSON.stringify(results, null, 2));
        } else {
          return res.send(200, JSON.stringify(results, null, 2));
        }
      });
    };
  };

}).call(this);
