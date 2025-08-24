#!/usr/bin/env ruby
# messages/police_dispatch_message.rb
# Police dispatch message sent by the Police Department in response to emergency calls
# Contains unit assignments and response details for security incidents and crimes

require_relative '../smart_message/lib/smart_message'

module Messages
  class PoliceDispatchMessage < SmartMessage::Base
    version 1

    description <<~DESC
      Law enforcement dispatch coordination message sent by the Police Department in response to emergency calls
      and security incidents,   containing unit assignments, response priorities, and tactical deployment information
      for crimes, alarms, and public safety threats
    DESC

    transport  SmartMessage::Transport::RedisTransport.new
    serializer SmartMessage::Serializer::Json.new

    VALID_PRIORITY = %w[low medium high emergency]

    property :dispatch_id, required: true,
      description: "Unique hexadecimal identifier for this police dispatch operation"

    property :units_assigned, required: true,
      description: "Array of police unit call signs assigned to respond (e.g., ['Unit-101', 'Unit-102'])"

    property :location, required: true,
      description: "Street address or location where police units should respond"

    property :incident_type, required: true,
      description: "Classification of the incident requiring police response (e.g., 'robbery', 'suspicious_activity')"

    property :priority, required: true,
      validate: ->(v) { VALID_PRIORITY.include?(v) },
      validation_message: "Priority must be: #{VALID_PRIORITY.join(', ')}",
      description: "Response urgency level determining dispatch speed. Valid values: #{VALID_PRIORITY.join(', ')}"

    property :estimated_arrival,
      description: "Projected time for first unit arrival at the scene (e.g., '5 minutes')"

    property :timestamp, required: true,
      description: "Exact time when the dispatch was initiated (YYYY-MM-DD HH:MM:SS format)"
  end
end
