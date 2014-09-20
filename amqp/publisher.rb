#!/usr/bin/env ruby
#################################################################
###
##  File: publisher.rb
##  Desc: Publishes meditations
##
#
require 'awesome_print'
require 'betterlorem'

#####################################################
## initializer junk

require "bunny"
require 'json'
require 'hashie'
require 'date'

OPTIONS = {
  :host      => "localhost",          # defualt: 127.0.0.1
  :port      => 5672,                 # default
  :ssl       => false,                # defualt
  :vhost     => "sandbox",            # defualt: /
  :user      => "xyzzy",              # defualt: guest
  :pass      => "xyzzy",              # defualt: guest
  :heartbeat => :server,              # defualt: will use RabbitMQ setting
  :threaded  => true,                 # default
  :network_recovery_interval => 5.0,  # default is in seconds
  :automatically_recover  => true,    # default
  :frame_max => 131072                # default
}

QUEUE_NAME = "submissions"

$connection = Bunny.new(OPTIONS).tap(&:start)
$exchange   = $connection.create_channel.topic("sandbox", :auto_delete => true)

at_exit do
  $connection.close
end

#####################################################
## local stuff

class Author < Hashie::Mash
  def save
    # TODO: most likely going to save to a database
    #       or maybe to a file in Elvis
  end
end

class Meditation < Hashie::Mash
  def save
    # TODO: save as an InCopy file
    # TODO: Upload file to Elvis
  end
end


def send_author(author)
  $exchange.publish(  author.to_json,
                      routing_key: 'Author.new',
                      app_id: "Fake Submitter"
                    )
  puts "Author:  ID #{author.author_id}  Nane: #{author.name}"
end # def send_author(author)


def send_meditation(meditation)
  $exchange.publish(  meditation.to_json,
                      routing_key: 'Meditation.new',
                      app_id: "Fake Submitter"
                    )
  puts "\tMeditation:  ID #{meditation.submission_id}  Title: #{meditation.title}"
end # def send_meditation(meditation)


def create_meditation(author_id)
  meditation = Meditation.new

  meditation.author_id        = author_id

  meditation.submission_id    = DateTime.now.strftime('%Q').to_s
  meditation.title            = BetterLorem.w(3+rand(5),true,true)
  meditation.theme            = BetterLorem.w(3+rand(5),true,true)
  meditation.long_reading     = BetterLorem.w(1,true,true) + " #{rand(45)}:#{rand(16)}-#{rand(45)+16}"
  meditation.quoted_scripture = BetterLorem.w(13+rand(13),true,true)
  meditation.citation         = BetterLorem.w(1,true,true) + " #{rand(45)}:#{rand(16)}-#{rand(45)+16}"

  body_text = BetterLorem.p(1+rand(4)).split(' ')
  s = rand(body_text.size-7)
  e = s + rand(3)+1
  body_text[s] = "<i>" + body_text[s]
  body_text[e] = body_text[e] + "</i>"

  meditation.body_text            = body_text.join(' ')
  meditation.prayer               = BetterLorem.p(1,true,false)
  meditation.thought_for_the_day  = BetterLorem.w(3+rand(10),true,true)
  meditation.prayer_focus         = BetterLorem.w(3+rand(6),true,true)

  return meditation
end # def create_meditation


def create_author
  author = Author.new

  author.author_id  = DateTime.now.strftime('%Q').to_s
  author.gender     = rand(2) > 0 ? 'M' : 'F'
  author.name       = BetterLorem.w(1+rand(4),true,true)
  author.location   = BetterLorem.w(1+rand(3),true,true)
  author.email      = BetterLorem.w(1,true,true) + "@" + BetterLorem.w(1,true,true) + '.net'

  return author
end # def create_author


100.times do

  author          = create_author
  send_author(author)

  100.times do
    meditation = create_meditation(author.author_id)
    #submission = author.merge meditation
    send_meditation(meditation)
    #sleep(rand(3))
  end

end

