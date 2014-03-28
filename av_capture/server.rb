#!/usr/bin/env ruby -wKU

require 'av_capture'
require 'drb'

class PhotoServer
  attr_reader :photo_request, :photo_response

  def initialize
    @photo_request  = Queue.new
    @photo_response = Queue.new
    @mutex          = Mutex.new
  end

  def take_photo
    @mutex.synchronize do
      photo_request << "x"
      photo_response.pop
    end
  end
end

server = PhotoServer.new

Thread.new do
  session = AVCapture::Session.new
  dev = AVCapture.devices.find(&:video?)

  session.run_with(dev) do |connection|
    while server.photo_request.pop
      server.photo_response.push connection.capture
    end
  end
end

URI = "druby://localhost:8787"
DRb.start_service URI, server
DRb.thread.join

