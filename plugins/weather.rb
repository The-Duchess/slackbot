#!/bin/env ruby
#############################################################################################
# author: apels <Alice Duchess>
#############################################################################################

load 'plugin_manager.rb'

require 'net/http'
require 'optparse'
require 'open-uri'
require 'json'
require 'date'

class Weather < Pluginf

	def initialize(regex, name, filename, help)
			@regexp = regex
			@name = name.to_s
			@help = help
			@chan_list = []
			@chan_list.push("any")
			@file_name = filename

			# Weather user hash and array
			@users = Hash.new
			@users_s = Array.new

			if not File.exist?("./.weather") then
				`touch ./.weather` #if the user list file does not exist then create it
			end

			p load_users
		end

		def add_user(nick, ac_t)
			#@dict.store("#{object}", ["#{description}"])
			@users_s.push(nick.to_s)
			@users.store(nick.to_s, ac_t.to_s)

			return "added"
		end

		def update_user(nick, ac_t)
			@users[:nick] = ac_t.to_s
			return "updated"
		end

		def check_user(nick)
			if @users_s.include? nick then return true end

			return false
		end

		def cleanup
			# perform cleanup if module is going to be removed
			save_users
		end

		def save_users
			# Write out users to file
			File.open("./.weather", 'w') do |fw|
				@users_s.each do |a|
					fw.puts("#{a}:#{@users.fetch(a)}\n")
				end
			end

			return "saved"
		end

		def load_users
			# Read users from file
			File.open("./.weather", 'r') do |fr|
				while line = fr.gets
					line.chomp!
					# file format
					# nick:area code
					tokens = line.split(':')
					nick_t = tokens[0]
					area_c = tokens[1] # area code will always have any spaces removed before being saved
					@users_s.push(nick_t.to_s)
					@users.store(nick_t.to_s, area_c.to_s)
				end
			end

			return "loaded"
		end

		def weatherc(c)
			wc = Hash.new

			wc = {200 => "thunderstorm with light rain", 201 => "thunderstorm with rain", 202 => "thunderstorm with heavy rain", 210 => "light thunderstorm", 211 => "thunderstorm", 212 => "heavy thunderstorm", 221 => "ragged thunderstorm", 230 => "thunderstorm with light drizzle", 231 => "thunderstorm with drizzle", 231 => "thunderstorm with heavy drizzle", 300 => "light intensity drizzle", 301 => "drizzle", 302 => "heavy intensity drizzle", 310 => "light intensity drizzle rain", 311 => "drizzle rain", 312 => "heavy intensity drizzle rain", 313 => "shower rain and drizzle", 314 => "heavy shower rain and drizzle", 321 => "shower drizzle", 500 => "light rain", 501 => "moderate rain", 502 => "heavy intensity rain", 503 => "very heavy rain", 504 => "extreme rain", 511 => "freezing rain", 520 => "light intensity shower rain", 521 => "shower rain", 522 => "heavy intensity shower rain", 531 => "ragged shower rain", 600 => "light snow", 601 => "snow", 602 => "heavy snow", 611 => "sleet", 612 => "shower sleet", 615 => "light rain and snow", 616 => "rain and snow", 620 => "light shower snow", 621 => "shower snow", 622 => "heavy shower snow",701 => "mist", 711 => "smoke", 721 => "haze", 731 => "sand, dust. whirls", 741 => "fog", 751 => "sand", 761 => "dust", 762 => "volcanic ash", 771 => "squalls", 781 => "tornado", 800 => "clear sky", 801 => "few clouds", 802 => "scattered clouds", 803 => "broken clouds", 804 => "overcast clouds", 900 => "tornado", 901 => "tropical storm", 902 => "hurricane", 903 => "cold", 904 => "hot", 905 => "windy", 906 => "hail", 951 => "calm", 952 => "light breeze", 953 => "gentle breeze", 954 => "moderate breeze", 955 => "fresh breeze", 956 => "strong breeze", 957 => "high wind, near gale", 958 => "gale", 959 => "severe gale", 960 => "storm", 961 => "violent storm", 962 => "hurricane"}

			return wc.fetch(c.to_i).to_s
		end

		# returns a length 5 array of ["today", tomorrow", "NEXT NEXT DAY NAME" ... ]
		def get_day_names
			# get today
			arr = ["Today", "Tomorrow"]
			week_d = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

			today = Time.now.strftime("%A")
			#today[0].upcase!
			i =
			i = week_d.find_index(today)

			if i == 5
				i = 0
			elsif i == 6
				i = 1
			else
				i = i + 2
			end


			5.times do |j|
				arr.push(week_d[i])

				if i == 6
					i = 0
				else
					i = i + 1
				end
			end


			return arr
		end

		# returns the appropriate index for a temperature
		def get_index(temperature_t)

			temper = temperature_t.to_i

			if temper < 40
				return 0
			elsif 41 <= temper < 60
				return 1
			elsif 61 <= temper < 80
				return 2
			else
				return 3
			end
		end

		def get_forcast(area_code)
			@ac = area_code
			@r_w = ""
			days = [] # weather for various days
			days_names = Array.new
			days_names = get_day_names
			temp_colors = ["02", "03", "08", "04"] # colors to change text color for temperature

			url = "http://api.openweathermap.org/data/2.5/forecast/daily?q=#{@ac}&mode=json&units=imperial&cnt=7"
			url_m = "http://api.openweathermap.org/data/2.5/forecast/daily?q=#{@ac}&mode=json&units=metric&cnt=7"

			# p "BEFORE READ"


			begin
				@contents = open(url).read
			rescue => a
				# p a
				return "#{@ac} is this place actually real?"
			end

			begin
				@contents_m = open(url_m).read
			rescue => a
				# p a
				return "#{@ac} is this place actually real?"
			end

			# p "AFTER READ"

			contents = open(url).read
			contents_m = open(url_m).read
			parsed_json = JSON.parse(contents)
			parsed_json_m = JSON.parse(contents_m)

			# p "BEFORE PARSE INTO DAYS"

			#p contents.to_s
			#p  parsed_json.to_s

			if parsed_json['list'].nil?
				@r_w = "#{@ac} is this place actually real?"
			elsif days_fc = parsed_json['list']
				# parse website info and put into days
				days_fc = parsed_json['list']
				days_fc_m = parsed_json_m['list']

				# p "AT PARSE INTO DAYS"

				0.upto(3) do |i|
					# temperature F
					begin

						# p "PARSING DAY #{i} TEMP"

						temper_f_min = days_fc[i]['temp']['min'].to_s
						#t = get_index(temper_f_min)
						t1_n = 04 #temp_colors[get_index(temper_f_min)].to_i
						temper_f_max = days_fc[i]['temp']['max'].to_s
						#t = get_index(temper_f_max)
						t1_x = 04 #temp_colors[get_index(temper_f_max)].to_i
						p "PARSING DAY #{i} TEMP F DONE"
						# temperature C
						temper_c_min = days_fc_m[i]['temp']['min'].to_s
						#t = get_index(temper_c_min)
						t2_n = 04 #temp_colors[get_index(temper_c_min)].to_i
						temper_c_max = days_fc_m[i]['temp']['max'].to_s
						#t = get_index(temper_c_max)
						t2_x = 04 #temp_colors[get_index(temper_c_max)].to_i

						weather_condition = weatherc(days_fc[i]['weather'][0]['id']).to_s

						wind_speed = days_fc[i]['speed'].to_s

						humidity = days_fc[i]['humidity'].to_s

						days.push("\x0314#{days_names[i]}\x03: Weather for \x0314#{@ac}\x03 is #{weather_condition}, Temperature: min \x0308#{temper_f_min}\x03°F or \x0308#{temper_c_min}\x03°C, max \x0304#{temper_f_max}\x03°F or \x0304#{temper_c_max}\x03°C, Humidity of \x0302#{humidity}\x03 percent, Wind speeds at \x0303#{wind_speed}\x03 mph")

					rescue => e
						return "#{@ac} is this place actually real?"
					end
				end
			end

			# p "DONE PARSING"

			days.each do |a|
				@r_w.concat("#{a}\n")
			end

			@r_w.chomp!

			return @r_w

		end

		def get_weather(area_code)

			@r_w = ""
			@ac = area_code

			url = "http://api.openweathermap.org/data/2.5/weather?q=#{@ac}&mode=json&units=imperial"
			url_m = "http://api.openweathermap.org/data/2.5/weather?q=#{@ac}&mode=json&units=metric"

			begin
				@contents = open(url).read
			rescue => a
				return "#{@ac} is this place actually real?"
			end

			begin
				@contents_m = open(url_m).read
			rescue => a
				return "#{@ac} is this place actually real?"
			end

			contents = open(url).read
			contents_m = open(url_m).read
			parsed_json = JSON.parse(contents)
			parsed_json_m = JSON.parse(contents_m)
			if parsed_json['main'].nil?
				@r_w = "#{@ac} is this place actually real?"
			elsif weather_in_f = (parsed_json['main']['temp']).to_i
				begin
					weather_in_c = (parsed_json_m['main']['temp']).to_i
				rescue NoMethodError => e
					return "#{@ac} is this place actually real?"
				end
				humidity = parsed_json['main']['humidity']
				weathercode = weatherc("#{parsed_json['weather'][0]['id']}")
				@r_w.concat("Weather of \x0304#{@ac.to_s}:\x03 #{weathercode} at \x0302#{weather_in_f}°F\x03 or \x0302#{weather_in_c}°C\x03 and winds at \x0311#{parsed_json['wind']['speed']} mph\x03")
			end

			return @r_w
		end

		def get_ac(nick)
			begin
				return @users.fetch(nick)
			rescue => e
				return "nick not found"
			end
		end

		def parse(message, nick, chan)
			tokens = message.split(' ')
			cmd = tokens[0] # the command the user is calling [ `w <area code |s nick> | `ws <area code> ]
			@r = ""

			if message.match(/^`w$/)

				ac_t = get_ac(nick)

				if not ac_t == "nick not found"
					@r.concat(get_weather(ac_t).to_s)
				else
					@r.concat("nick not found")
				end

				return @r

			elsif message.match(/^`fc$/) # get your own forcast

				ac_t = get_ac(nick)

				if not ac_t == "nick not found"
					@r.concat(get_forcast(ac_t).to_s)
				else
					@r.concat("nick not found")
				end

				return @r

			elsif cmd == "`fc" # get forcast for a user

				if (tokens[1] == nick or check_user(tokens[1])) and tokens.length == 2
					ac_t = get_ac(tokens[1])

					if not ac_t == "nick not found"
						@r.concat(get_forcast(ac_t).to_s)
					else
						@r.concat("nick not found")
					end

					return @r

				elsif tokens[1] != nick and tokens.length >= 2
					ac_t = ""
					if tokens.length > 2
						1.upto(tokens.length - 1) do |i|
							ac_t.concat("#{tokens[i]}")
						end
					else
						ac_t = tokens[1]
					end
					@r.concat(get_forcast(ac_t).to_s)
				else
					return "invalid arguments"
				end

			elsif cmd == "`w" # getting weather for nick or an area code if tokens[1] != nick

				if (tokens[1] == nick or check_user(tokens[1])) and tokens.length == 2
					ac_t = get_ac(tokens[1])

					if not ac_t == "nick not found"
						@r.concat(get_weather(ac_t).to_s)
					else
						@r.concat("nick not found")
					end

					return @r

				elsif tokens[1] != nick and tokens.length >= 2
					ac_t = ""
					if tokens.length > 2
						1.upto(tokens.length - 1) do |i|
							ac_t.concat("#{tokens[i]}")
						end
					else
						ac_t = tokens[1]
					end
					@r.concat(get_weather(ac_t).to_s)
				else
					return "invalid arguments"
				end

			elsif cmd == "`ws" # sets the weather information for nick (e.g. `ws <area code>)

				if not tokens.length >= 2
					return "invalid arguments"
				end

				if not check_user(tokens[1])
					ac_t = ""
					if tokens.length > 2
						1.upto(tokens.length - 1) do |i|
							ac_t.concat("#{i}")
						end
					else
						ac_t = tokens[1]
					end

					return add_user(nick, ac_t)
				else
					ac_t = ""
					if tokens.length > 2
						1.upto(tokens.length - 1) do |i|
							ac_t.concat("#{i}")
						end
					else
						ac_t = tokens[1]
					end

					return update_user(nick, ac_t)
				end
				ac_t = get_ac(nick)

				if not ac_t == "nick not found"
					@r.concat(get_weather(ac_t).to_s)
				else
					@r.concat("nick not found")
				end

				return @r
			else
				# we have a major problem
				return "gottverdammt"
			end

			return @r
		end

		#your definition for script
		def script(data, admins, backlog)
			res_p = parse(data['text'], data['user'], data['channel'])
			return "<@#{data['user']}> #{res_p}"
		end

end

prefix_s = [
		/^`ws /,
		/^`w/,
		/^`fc/
	     ]
reg = Regexp.union(prefix_s)

filename = "weather.rb" # file name
pluginname = "weather" # name for plugin
description = "usage: `w areacode or City, State or nick | `ws <nick> <areacode> | `fc nick or nothing" # description and or help

# plugin = Class_name.new(regex, name, file_name, help)
$temp_plugin = Weather.new(reg, pluginname, filename, description)
