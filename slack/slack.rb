#!/usr/bin/env ruby
######################################################
###
##  File: slack.rb
##  Desc: Playing with slack API
#


require 'dotenv'
require 'awesome_print'

require 'pathname'

require 'slack-notify'
require 'slacken'


class ImGateway
  def initialize

    webhook_url = ENV['SLACK_WEBHOOK_URL']
    channel     = ENV['SLACK_CHANNEL']       || '#feedback'
    username    = ENV['SLACK_USERNAME']      || 'feedbacker'

    unless webhook_url && channel && username
      puts <<~EOS

        The following system environment variables are required for slack notification:

          SLACK_WEBHOOK_URL ... current value: #{ENV['SLACK_WEBHOOK_URL']}
          SLACK_CHANNEL ....... current value: #{ENV['SLACK_CHANNEL']}
          SLACK_USERNAME ...... current value: #{ENV['SLACK_USERNAME']}

      EOS
      exit
    end

    @slack_client = SlackNotify::Client.new(
                      webhook_url:  webhook_url,
                      channel:      channel,
                      username:     username
                    )
  end # def initialize


  def notify_slack(options={})
    message = options['message'].gsub("\n", "<br /><br />")
    @slack_client.notify(Slacken.translate(message)) # xlate HTML to markdown for slack
  end
end # class ImGateway


