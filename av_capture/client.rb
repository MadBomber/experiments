#!/usr/bin/env ruby -wKU

require 'drb'

SERVER_URI = "druby://localhost:8787"

photoserver = DRbObject.new_with_uri SERVER_URI
print photoserver.take_photo
