#!/usr/bin/env ruby

require_relative 'smart_message/lib/smart_message'

# Load all message types
Dir[File.join(__dir__, 'messages', '*.rb')].each { |file| require file }

puts "🧪 Testing department creation fix..."

# Create a service request message to test the system
request_msg = Messages::ServiceRequestMessage.new(
  emergency_type: "Sanitation Emergency", 
  location: "Citywide",
  description: "Need sanitation department to handle: Overflowing sewers everywhere!",
  requested_service: "sanitation_department"
)
request_msg._sm_header.from = "test_client"
request_msg._sm_header.to = "city_council"

puts "📤 Sending service request to city_council..."
request_msg.publish

puts "✅ Service request sent. Check city_council logs and files for new department creation."
puts "🔍 Expected: sanitation_department.rb (NOT sanitation_department_department.rb)"