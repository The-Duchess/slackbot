#! /bin/env ruby
# usage: ruby slackbot.rb <API_KEY>

require "slack-ruby-client"

# plugin_s = []
# plugins = Plugin_manager.new("./plugins")
# plugin_s.each { |a| plugins.plugin_load(a) }
# backlog = []
# admins = []

Slack.configure do |config|
  config.token = ARGV[0].to_s
end

client = Slack::RealTime::Client.new

client.on :hello do
  puts 'Successfully connected.'
end

client.on :message do |data|

      # backlog.push(data)

      case data['text']
      when 'husk hi' then
            client.message channel: data['channel'], text: "Hi <@#{data['user']}>!"
      when /^husk/ then
            client.message channel: data['channel'], text: "Sorry <@#{data['user']}>, what?"
      end

=begin
      @plugins.each do |plugin|
            if data['text'].match(plugin.regex)
                  client.message channel: data['channel'], text: plugin.sub(data, backlog, admins).to_s
            end
      end
=end
end

client.start!
