#! /bin/env ruby
# usage: ruby slackbot.rb <API_KEY>

require "slack-ruby-client"
require_relative "plugin_manager.rb"

plugin_s = ["cat.rb"]
plugins = Plugin_manager.new("./plugins")
plugin_s.each { |a| plugins.plugin_load(a) }
backlog = []
admins = []

Slack.configure do |config|
  config.token = ARGV[0].to_s
end

client = Slack::RealTime::Client.new

client.on :hello do
  puts 'Successfully connected.'
end

client.on :message do |data|

      backlog.push(data)

      case data['text']
      when 'husk hi' then
            client.message channel: data['channel'], text: "Hi <@#{data['user']}>!"
      #when /^husk/ then
      #      client.message channel: data['channel'], text: "Sorry <@#{data['user']}>, what?"
      end

      plugins.plugins.each do |plugin|
            if data['text'].match(plugin.regex)
                  client.message channel: data['channel'], text: plugin.script(data, backlog, admins).to_s
            end
      end

      responses = plugins.check_all(data, admins, backlog)

      responses.each do |a|
            client.message channel: data['channel'], text: a.to_s
      end

end

client.start!
