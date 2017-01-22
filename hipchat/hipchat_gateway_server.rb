#!/usr/bin/env ruby
######################################################
###
##  File: hipchat_gateway_server.rb
##  Desc: Server for distributed Ruby (dRuby) gateway to hipchat
##        Required for hipchat integration with Rails v4.2.3
##        due to an openSSL error within Rails.
#

require 'drb/drb'
require 'hipchat'

class HipchatGateway

  attr_accessor :client
  attr_accessor :room
  attr_accessor :server
  attr_accessor :token
  attr_accessor :user
  attr_accessor :message
  attr_accessor :notify
  attr_accessor :color

  def initialize()
    @room     = ENV['HIPCHAT_ROOM']
    @server   = ENV['HIPCHAT_SERVER']
    @token    = ENV['HIPCHAT_TOKEN']
    @user     = ENV['HIPCHAT_USER']     || 'Hipchat Gateway'
    @message  = ENV['HIPCHAT_MESSAGE']  || 'This is a canned message'
    @notify   = ENV['HIPCHAT_NOTIFY']   || false
    @color    = ENV['HIPCHAT_COLOR']    || 'yellow'

    unless @room && @token
      puts <<~EOS

        The following system environment variables are required:

          HIPCHAT_ROOM .... current value: #{ENV['HIPCHAT_ROOM']}
          HIPCHAT_TOKEN ... current value: #{ENV['HIPCHAT_TOKEN']}

        The following system environment variables are optional:

          HIPCHAT_SERVER .. current value: #{ENV['HIPCHAT_SERVER']}
          HIPCHAT_USER .... current value: #{ENV['HIPCHAT_USER']}

      EOS
      exit
    end

    if @user.size > 20
      @user = @user[0,20]
      puts <<~EOS

        WARNING: The HIPCHAT_USER value exceeded 20 characters limit - it was truncated.
                 Value was: '#{ENV['HIPCHAT_USER']}'
                 Value is:  '#{@user}'

      EOS
    end

    if @server.nil? || @server.empty?
      @client = HipChat::Client.new(@token, :api_version => 'v2') # use the default server
    else
      @client = HipChat::Client.new(@token, :api_version => 'v2', :server_url => "https://#{@server}")
    end

  end # def initialize

  def notify(options={})
    fromuser  = options.delete(:fromuser) || @user
    message   = options.delete(:message)  || @message

    @client[@room].send(fromuser, message, options)
  end
end

gateway = HipchatGateway.new

DRb.start_service('druby://localhost:9999', gateway)
DRb.thread.join

