#!/bin/env ruby
#############################################################################################
# author: apels <Alice Duchess>
#############################################################################################

load 'plugin_manager.rb'

class Cat_print < Pluginf

	# any functions you may need can be included here

	# your definition for function called if the regex for the plugin matches the message.message
	# inputs:
	# 	- data hash
	# 	- admins array
	# 	- backlog array of data hashes
	# output: string to send to data['channel']
	def script(data, admins, backlog)

		# plugins must return the raw mesaage they wish to have sent to the socket
		# return "PRIVMSG #{message.chan} :hello"
		# or you can use functions to simplify this
		# some are provided below
		return "<@#{data['user']}> ~( ^^)"
	end

end

# allows you to support multiple regexes
# prefix = [
#		//,
#		//
#	   ]
#
# reg_p = Regexp.union(prefix)

reg = /^`cat/ # regex to call the plugin
filename = "cat.rb" # file name
pluginname = "cat" # name for plugin
description = "`cat will print a cat" # description and or help

# plugin = Class_name.new(regex, name, file_name, help)
$temp_plugin = Cat_print.new(reg, pluginname, filename, description)
