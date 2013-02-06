#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'logger'
require 'tweetstream'

log = Logger.new(STDOUT)
STDOUT.sync = true

# for REST API
client = Twitter::Client.new(
  :consumer_key       => ENV['TWITTER_CONSUMER_KEY'],
  :consumer_secret    => ENV['TWITTER_CONSUMER_SECRET'],
  :oauth_token        => ENV['TWITTER_ACCESS_TOKEN'],
  :oauth_token_secret => ENV['TWITTER_ACCESS_TOKEN_SECRET'],
)
profile = client.verify_credentials

# for Streaming API
TweetStream.configure do |config|
  config.consumer_key       = ENV['TWITTER_CONSUMER_KEY']
  config.consumer_secret    = ENV['TWITTER_CONSUMER_SECRET']
  config.oauth_token        = ENV['TWITTER_ACCESS_TOKEN']
  config.oauth_token_secret = ENV['TWITTER_ACCESS_TOKEN_SECRET']
  config.auth_method        = :oauth
end
stream = TweetStream::Client.new

stream.on_error do |err|
  log.error(err)
end
stream.on_inited do
  log.info('init')
end
# auto follow
stream.on_event(:follow) do |event|
  if event[:target][:id] == profile.id
    log.info('followed from @%s' % event[:source][:screen_name])
    if client.follow(event[:source][:id])
      log.info('followed')
    end
  end
end
stream.userstream do |status|
  next if rand(3) == 0
  next if status.retweet?
  next if status.reply?

  log.info('status from @%s: %s' % [status.from_user, status.text])
  shinpai = '@%s ' % status.from_user
  case status.text
  when /病/
    shinpai += '病んでるの？'
  when /疲/
    shinpai += '疲れてるの？'
  when /凹/
    shinpai += '凹んでるの？'
  when /心折/
    shinpai += '心折れてるの？'
  when /\.\.\./ || /。。。/ || /orz/
  else
    next
  end

  tweet = client.update(shinpai + 'げんきだして！', {
      :in_reply_to_status_id => status.id,
  })
  if tweet
    log.info('tweeted: %s' % tweet.text)
  end
end
