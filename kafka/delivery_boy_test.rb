#!/usr/bin/env ruby
# delivery_boy_test.rb

require 'awesome_print'
require 'debug_me'
include DebugMe

require 'delivery_boy'

DeliveryBoy.configure do |config|
  config.client_id = "db-gem"
  # ...
end

DeliveryBoy.deliver('Does this work?', topic: "comments")
