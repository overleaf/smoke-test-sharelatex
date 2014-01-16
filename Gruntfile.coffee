module.exports = (grunt) ->

	# Project configuration.
	grunt.initConfig
		coffee:
			index:
				src:  "index.coffee"
				dest: "index.js"

	grunt.loadNpmTasks 'grunt-contrib-coffee'
	
	grunt.registerTask 'default', ['coffee']


