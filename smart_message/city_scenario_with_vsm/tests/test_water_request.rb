#!/usr/bin/env ruby
# test_water_request.rb - Test script to send a water department request to city council

require_relative 'smart_message/lib/smart_message'
require_relative 'messages/service_request_message'
require 'securerandom'

# Create and send a service request for water department
message = Messages::ServiceRequestMessage.new(
  from: "test-dispatcher",
  to: "city_council",
  request_id: SecureRandom.uuid,
  requesting_service: "emergency-dispatch-center",
  emergency_type: "infrastructure",
  description: "Water main break flooding downtown streets - need water management department",
  urgency: "critical",
  original_call_id: "911-#{SecureRandom.hex(4)}",
  details: {
    location: "Main Street & 5th Avenue", 
    caller: "Downtown Business Owner",
    emergency_details: "Major water main break, streets flooding, businesses affected"
  }
)

puts "🧪 Sending test water department request..."
puts "📋 Request details:"
puts "   - Emergency: #{message.description}"
puts "   - Urgency: #{message.urgency}"
puts "   - Location: #{message.details[:location]}"

# Send the message via SmartMessage
message.publish

puts "✅ Water department request sent to city council!"
puts "🏛️ Check city_council.rb output for department creation..."