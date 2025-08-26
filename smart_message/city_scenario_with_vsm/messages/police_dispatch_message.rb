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
    VALID_INCIDENT_TYPES = %w[robbery burglary theft assault vandalism suspicious_activity domestic_disturbance traffic_violation accident silent_alarm weapons_violation drug_offense public_disturbance trespassing fraud harassment stalking other]
    VALID_UNIT_PREFIXES = %w[Unit-P Car- Alpha- Bravo- Charlie- Delta- Echo- Foxtrot- Golf- Hotel-]

    property :dispatch_id, required: true,
      validate: ->(v) { v.is_a?(String) && v.match?(/\A[0-9a-f]{4,8}\z/i) },
      validation_message: "Dispatch ID must be a 4-8 character hexadecimal string",
      description: "Unique hexadecimal identifier for this police dispatch operation"

    property :units_assigned, required: true,
      validate: ->(v) { 
        v.is_a?(Array) && 
        v.length > 0 && 
        v.all? { |unit| unit.is_a?(String) && VALID_UNIT_PREFIXES.any? { |prefix| unit.start_with?(prefix) } }
      },
      validation_message: "Units assigned must be a non-empty array of valid police unit call signs with prefixes: #{VALID_UNIT_PREFIXES.join(', ')}",
      description: "Array of police unit call signs assigned to respond (e.g., ['Unit-P101', 'Unit-P102'])"

    property :location, required: true,
      validate: ->(v) { v.is_a?(String) && v.length >= 5 && v.length <= 200 },
      validation_message: "Location must be a string between 5 and 200 characters",
      description: "Street address or location where police units should respond"

    property :incident_type, required: true,
      validate: ->(v) { VALID_INCIDENT_TYPES.include?(v) },
      validation_message: "Incident type must be one of: #{VALID_INCIDENT_TYPES.join(', ')}",
      description: "Classification of the incident requiring police response. Valid types: #{VALID_INCIDENT_TYPES.join(', ')}"

    property :priority, required: true,
      validate: ->(v) { VALID_PRIORITY.include?(v) },
      validation_message: "Priority must be: #{VALID_PRIORITY.join(', ')}",
      description: "Response urgency level determining dispatch speed. Valid values: #{VALID_PRIORITY.join(', ')}"

    property :estimated_arrival,
      validate: ->(v) { v.nil? || (v.is_a?(String) && v.match?(/\A\d+\s+(minute|minutes|min|mins|second|seconds|sec|secs)\z/i)) },
      validation_message: "Estimated arrival must be in format like '5 minutes' or '30 seconds'",
      description: "Projected time for first unit arrival at the scene (e.g., '5 minutes', '2 mins')"

    property :timestamp, required: true,
      validate: ->(v) { v.is_a?(String) && v.match?(/\A\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\z/) },
      validation_message: "Timestamp must be in YYYY-MM-DD HH:MM:SS format",
      description: "Exact time when the dispatch was initiated (YYYY-MM-DD HH:MM:SS format)"
  end
end
