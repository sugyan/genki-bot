#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'logger'
require 'tweetstream'

log = Logger.new(STDOUT)
STDOUT.sync = true

# REST API
rest = Twitter::Client.new(
  :consumer_key       => ENV['TWITTER_CONSUMER_KEY'],
  :consumer_secret    => ENV['TWITTER_CONSUMER_SECRET'],
  :oauth_token        => ENV['TWITTER_ACCESS_TOKEN'],
  :oauth_token_secret => ENV['TWITTER_ACCESS_TOKEN_SECRET'],
)
# Streaming API
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

EM.run do
  # auto follow and unfollow (every 5 minutes)
  EM.add_periodic_timer(300) do
    friends   = rest.friend_ids.all
    followers = rest.follower_ids.all
    to_follow   = followers - friends
    to_unfollow = friends - followers
    # follow
    to_follow.each do |id|
      log.info('follow %s' % id)
      if rest.follow(id)
        log.info('done.')
      end
    end
    # unfollow
    to_unfollow.each do |id|
      log.info('unfollow %s' % id)
      if rest.unfollow(id)
        log.info('done.')
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
    when /(?:寂|淋)し/
      shinpai += 'さびしいの？'
    when /つらい/
      shinpai += 'つらくても、'
    when /死にたい/
      shinpai += '死なないで、'
    when /(…|。。。|orz)/
    else
      next
    end

    # 適当に間隔あける
    EM.add_timer(rand(5) + 5) do
      tweet = rest.update(shinpai + 'げんきだして！', {
          :in_reply_to_status_id => status.id,
        })
      if tweet
        log.info('tweeted: %s' % tweet.text)
      end
    end
  end
end
