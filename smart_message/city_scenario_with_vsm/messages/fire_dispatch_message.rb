#!/usr/bin/env ruby
# examples/messages/fire_dispatch_message.rb
#
# Fire dispatch message sent by the Fire Department in response to fire emergencies
# Contains fire engine assignments and specialized equipment details for fire suppression operations

require_relative '../smart_message/lib/smart_message'

module Messages
  class FireDispatchMessage < SmartMessage::Base
    version 1

    description 'Emergency fire suppression dispatch coordination message sent by the Fire Department in response to fire emergencies, containing fire engine assignments, specialized equipment deployment, and tactical response information for various fire types, rescue operations, and hazardous material incidents'

    transport  SmartMessage::Transport::RedisTransport.new
    serializer SmartMessage::Serializer::Json.new

    property :dispatch_id, required: true,
                           description: 'Unique hexadecimal identifier for this fire department dispatch operation'

    property :engines_assigned, required: true,
                                description: "Array of fire engine and apparatus call signs responding (e.g., ['Engine-1', 'Ladder-1', 'Rescue-1'])"

    VALID_FIRE_TYPES = %w[fire kitchen electrical basement garage wildfire vehicle chemical general grease]

    property :location, required: true,
                        description: 'Street address or location where fire engines should respond to the emergency'

    property :fire_type, required: true,
                         validate: ->(v) { VALID_FIRE_TYPES.include?(v) },
                         validation_message: "Fire type must be: #{VALID_FIRE_TYPES.join(', ')}",
                         description: "Classification of the fire type requiring specific suppression methods. Valid values: #{VALID_FIRE_TYPES.join(', ')}"

    property :equipment_needed,
             description: 'Specialized firefighting equipment and tools required for this specific fire type'

    property :estimated_arrival,
             description: "Projected time for first fire engine arrival at the emergency scene (e.g., '6 minutes')"

    property :timestamp, required: true,
                         description: 'Exact time when the fire dispatch was initiated (YYYY-MM-DD HH:MM:SS format)'
  end
end
