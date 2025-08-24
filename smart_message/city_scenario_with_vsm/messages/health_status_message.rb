#!/usr/bin/env ruby
# messages/health_status_message.rb
#
# Health status response message sent by city services back to the Health Department
# Contains operational status with color-coded display (green=healthy, yellow=warning, orange=critical, red=failed)

require_relative '../smart_message/lib/smart_message'

module Messages

  class HealthStatusMessage < SmartMessage::Base
    version 1

    description "Operational status response message sent by city services to the Health Department in response to health check requests, providing real-time service condition reporting with color-coded status levels for monitoring dashboard display"

    VALID_STATUS = %w[healthy warning critical failed]

    transport  SmartMessage::Transport::RedisTransport.new
    serializer SmartMessage::Serializer::Json.new

    property :service_name, required: true,
      description: "Name of the city service reporting its status (e.g., 'police-department', 'fire-department')"

    property :check_id, required: true,
      description: "ID of the health check request this message responds to"

    property :status, required: true,
      validate: ->(v) { VALID_STATUS.include?(v) },
      validation_message: "Status must be: #{VALID_STATUS.join(', ')}",
      description: "Current operational status of the service. Valid values: #{VALID_STATUS.join(', ')}"

    property :details,
      description: "Additional status information describing current service conditions"
  end
end
