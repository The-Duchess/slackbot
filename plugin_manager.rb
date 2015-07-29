#! /bin/env ruby
# plugin_manager.rb

class Pluginf

	def initialize(regex, name, file_name, help)
		@regexp = Regexp.new(regex.to_s)
		@name = name.to_s
		@file_name = file_name.to_s
		@help = help
		@chan_list = []
		@chan_list.push("any")
	end

	# default function
	def script(data, nick, chan)

	end

	def regex
		return @regexp
	end

	def chans
		return @chan_list
	end

	def name
		return @name
	end

	def file_name
		return @file_name
	end

	def help
		return @help
	end

	def cleanup
		return ""
	end
end

class Plugin_manager
	def initialize(plugin_folder)
		@plugins = []
		@plugin_folder = plugin_folder
	end

	# returns all the plugins
	def plugins

		if @plugins.length == 0
			return []
		end

		return @plugins
	end

	# search functions
	def get_names

		if @plugins.length == 0
			return []
		end

		names = []

		@plugins.each { |a| names.push(a.name) }

		return names
	end

	def get_helps

		if @plugins.length == 0
			return []
		end

		names = []

		@plugins.each { |a| names.push(a.help) }

		return names
	end

	def get_files

		if @plugins.length == 0
			return []
		end

		names = []

		@plugins.each { |a| names.push(a.file_name) }

		return names
	end

	def get_chans

		if @plugins.length == 0
			return []
		end

		names = []

		@plugins.each { |a| names.push(a.chans) }

		return names
	end

	def get_regexps

		if @plugins.length == 0
			return []
		end

		names = []

		@plugins.each { |a| names.push(a.regex) }

		return names
	end

	def get_plugin(name) # gets a plugin by name or nil if it is not loaded

		if @plugins.length == 0
			return nil
		end

		@plugins.each { |a| if a.name == name then return a end }

		return nil
	end

	def plugin_help(name) # gets the help for a plugin

		if @plugins.length == 0
			return nil
		end

		@plugins.each { |a| if a.name == name then return a.help end }

		return nil
	end

	def plugin_file_name(name) # gets the file name for a plugin

		if @plugins.length == 0
			return nil
		end

		@plugins.each { |a| if a.name == name then return a.file_name end }

		return nil
	end

	def plugin_chans(name) # gets the array of channels for a plugin

		if @plugins.length == 0
			return nil
		end

		@plugins.each { |a| if a.name == name then return a.chans end }

		return nil
	end

	def plugin_regex(name) # gets the regex for a plugin

		if @plugins.length == 0
			return nil
		end

		@plugins.each { |a| if a.name == name then return a.regex end }

		return nil
	end

	# check if a plugin is loaded
	def plugin_loaded(name)

		if @plugins.length == 0
			return false
		end

		@plugins.each do |a|
			if a.name == name
				return true
			end
		end

		return false
	end

	# regex check function
	# this function uses the IRC_message object for message input
	# inputs:
	# 	- name
	# 	- IRC_message object
	# 	- array of admins [can be an empty array]
	# 	- backlog array [can be an empty array]
	# output: string
 	def check_plugin(name, message, admins, backlog) #checks an individual plugin's (by name) regex against message

 		if @plugins.length == 0
			return ""
		end

		if !plugin_loaded(name)
			return ""
		else
			if message['text'].match(get_plugin(name).regex) and (get_plugin(name).chans.include? "any" or get_plugin(name).chans.include? message['channel'])
				begin
					return get_plugin(name).script(message, admins, backlog) # plugins use the IRC_message object
				rescue => e
					return "an error occured for plugin: #{name}"
				end
			end
		end

		return ""
	end

	# regex check function that returns responses for all plugins in an array
	# inputs:
	# 	- IRC_message object
	# 	- array of admins [can be an empty array]
	# 	- backlog array [can be an empty array]
	# output: array of strings
	def check_all(message, admins, backlog)

		if @plugins.length == 0
			return []
		end

		response = []

		# this is incredibly inneficient but it makes check_plugin flexible
		@plugins.each { |a| response.push(check_plugin(a.name, message, admins, backlog)) }

		return response
	end

	# load
	def plugin_load(name)

		$LOAD_PATH << "#{@plugin_folder}"
		response = ""
		$temp_plugin = nil # allows a global to be set, thus allowing the plugin to create a temporary we can add
		if name.match(/.rb$/)
			begin
				load "#{name}"
				if plugin_loaded($temp_plugin.name)
					$temp_plugin = nil
					return "Plugin #{name} is already loaded"
				end
				@plugins.push($temp_plugin)
				$temp_plugin = nil
				response = "#{name[0..-4]} loaded"
			rescue => e
				response = "cannot load plugin"
			end
		else
			begin
				load "#{name}.rb"
				if plugin_loaded($temp_plugin.name)
					$temp_plugin = nil
					return "Plugin #{name} is already loaded"
				end
				@plugins.push($temp_plugin)
				$temp_plugin = nil
				response = "#{name} loaded"
			rescue => e
				response = "cannot load plugin"
			end
		end
		$LOAD_PATH << './'
		return response
	end

	# unload
	def unload(name)

		if !plugin_loaded(name)
			return "plugin is not loaded"
		end

		get_plugin(name).cleanup
		@plugins.delete_if { |a| a.name == name }

		return "plugin #{name} unloaded"
	end

	# reload
	def reload(name)

		if !plugin_loaded(name)
			return "plugin is not loaded"
		end

		temp_file_name = get_plugin(name).file_name

		unload(name)
		plugin_load(temp_file_name)

		return "plugin #{name} reloaded"
	end
end
