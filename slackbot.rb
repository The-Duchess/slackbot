#! /bin/env ruby
# usage: ruby slackbot.rb <API_KEY>

require "slack-ruby-client"

Slack.configure do |config|
  config.token = ARGV[0].to_s
end

client = Slack::RealTime::Client.new

client.on :hello do
  puts 'Successfully connected.'
end

client.on :message do |data|
      case data['text']
      when 'husk hi' then
            client.message channel: data['channel'], text: "Hi <@#{data['user']}>!"
      when /^husk/ then
            client.message channel: data['channel'], text: "Sorry <@#{data['user']}>, what?"
      end
end

client.start!
