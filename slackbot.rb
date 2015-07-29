#! /bin/env ruby

require "slack"
require "slack-ruby-client"

Slack.configure do |config|
  config.token = ARGV[0].to_s
end

client = Slack::Web::Client.new

puts client.auth_test

client.on :hello do
  puts 'Successfully connected.'
end

client.start!
