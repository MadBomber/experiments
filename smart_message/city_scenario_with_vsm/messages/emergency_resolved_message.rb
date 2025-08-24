#!/usr/bin/env ruby
# examples/messages/emergency_resolved_message.rb
#
# Emergency resolution message broadcast when incidents are successfully resolved
# Provides closure notification to all city services about completed emergency responses
#
require_relative '../smart_message/lib/smart_message'


module Messages
  class EmergencyResolvedMessage < SmartMessage::Base
    version 1

    description 'Emergency incident closure notification message broadcast by emergency services when incidents are successfully resolved, providing completion status, response duration, outcome details, and unit deployment information to all city services for operational awareness and incident tracking'

    transport  SmartMessage::Transport::RedisTransport.new
    serializer SmartMessage::Serializer::Json.new

    property :incident_id, required: true,
                           description: 'Unique identifier of the emergency incident that was resolved'

    property :incident_type, required: true,
                             description: "Classification of the incident that was resolved (e.g., 'robbery', 'kitchen fire')"

    property :location, required: true,
                        description: 'Street address or location where the incident occurred and was resolved'

    property :resolved_by, required: true,
                           description: "Name of the city service that resolved the incident (e.g., 'police-department', 'fire-department')"

    property :resolution_time, required: true,
                               description: 'Exact time when the incident was fully resolved (YYYY-MM-DD HH:MM:SS format)'

    property :duration_minutes, required: true,
                                description: 'Total duration of the incident from start to resolution in minutes (decimal format)'

    property :outcome,
             description: 'Brief description of the final result or outcome of the emergency response'

    property :units_involved,
             description: 'Array of emergency response units that participated in resolving the incident'
  end
end
