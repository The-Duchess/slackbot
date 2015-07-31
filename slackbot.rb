#! /bin/env ruby
# usage: ruby slackbot.rb <BOT_USER_NAME> <API_KEY>

require "slack-ruby-client"
require_relative "plugin_manager.rb"

plugin_s = ["cat.rb", "weather.rb"]
plugins = Plugin_manager.new("./plugins")
plugin_s.each { |a| plugins.plugin_load(a) }
backlog = []
admins = []
username = ARGV[0].to_s

Slack.configure do |config|
  config.token = ARGV[1].to_s
end

client = Slack::RealTime::Client.new

client.on :hello do
  puts 'Successfully connected.'
end

client.on :message do |data|

      backlog.push(data)

      case data['text']
      when /^#{username} hi$/ then
            client.message channel: data['channel'], text: "Hi <@#{data['user']}>!"
      when /^`src$/ then
            client.message channel: data['channel'], text: "<@#{data['user']}>, https://github.com/The-Duchess/slackbot"
      when /^`plsgo$/ then
            plugins.plugins.each do |plugin|
                  plugin.cleanup
            end
            abort
      end

      plugins.plugins.each do |plugin|
            if data.class == nil then next end
            if data['text'].class == nil then next end
            puts data['text']
            if data['text'].to_s.match(plugin.regex)
                  puts data['text']
                  client.message channel: data['channel'], text: plugin.script(data, backlog, admins).to_s
            end
      end

end

client.start!
