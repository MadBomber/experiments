# messages/department_announcement_message.rb
# Message for announcing new city departments created by City Council

require_relative '../smart_message/lib/smart_message'

module Messages
  class DepartmentAnnouncementMessage < SmartMessage::Base
    version 1

    description <<~DESC
      Official announcement message broadcast by the City Council when creating new city departments,
      providing details about department launch status, capabilities, and operational information
      for system-wide awareness and coordination
    DESC

    transport SmartMessage::Transport::RedisTransport.new
    serializer SmartMessage::Serializer::Json.new

    VALID_STATUS           = %w[created launched active failed terminated suspended]
    VALID_CREATORS         = %w[city_council emergency_dispatch_center mayor system_admin]
    VALID_DEPARTMENT_TYPES = %w[emergency public_works utilities environmental transportation health safety administrative]

    property :department_name, required: true,
      validate: ->(v) { v.is_a?(String) && v.length >= 3 && v.length <= 100 && v.match?(/\A[a-z0-9_]+\z/) },
      validation_message: "Department name must be 3-100 characters, lowercase letters, numbers, and underscores only",
      description: "Internal system name for the department (e.g., 'water_department', 'animal_control')"

    property :department_file, required: true,
      validate: ->(v) { v.is_a?(String) && v.match?(/\A[a-z0-9_]+\.(rb|yml)\z/) },
      validation_message: "Department file must be a valid .rb or .yml filename with lowercase letters, numbers, and underscores",
      description: "Filename of the department implementation or configuration file"

    property :status, required: true,
      validate: ->(v) { VALID_STATUS.include?(v) },
      validation_message: "Status must be one of: #{VALID_STATUS.join(', ')}",
      description: "Current operational status of the department. Valid values: #{VALID_STATUS.join(', ')}"

    property :description,
      validate: ->(v) { v.nil? || (v.is_a?(String) && v.length <= 500) },
      validation_message: "Description must be a string with maximum 500 characters",
      description: "Human-readable description of the department's purpose and responsibilities"

    property :capabilities,
      default: [],
      validate: ->(v) { v.is_a?(Array) && v.all? { |cap| cap.is_a?(String) && cap.length > 0 } },
      validation_message: "Capabilities must be an array of non-empty strings",
      description: "List of operational capabilities provided by this department"

    property :message_types,
      default: [],
      validate: ->(v) { v.is_a?(Array) && v.all? { |msg| msg.is_a?(String) && msg.match?(/\A[a-z_]+_message\z/) } },
      validation_message: "Message types must be an array of strings ending with '_message'",
      description: "List of SmartMessage types this department can handle or publish"

    property :launch_time,
      default: -> { Time.now.iso8601 },
      validate: ->(v) { v.is_a?(String) && v.match?(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}([+-]\d{2}:\d{2}|Z)\z/) },
      validation_message: "Launch time must be in ISO8601 format (YYYY-MM-DDTHH:MM:SSZ)",
      description: "ISO8601 timestamp when the department was launched or will be launched"

    property :process_id,
      validate: ->(v) { v.nil? || (v.is_a?(Integer) && v > 0) },
      validation_message: "Process ID must be a positive integer",
      description: "Operating system process ID (PID) of the running department process"

    property :created_by,
      default: 'city_council',
      validate: ->(v) { VALID_CREATORS.include?(v) },
      validation_message: "Created by must be one of: #{VALID_CREATORS.join(', ')}",
      description: "System entity that initiated the department creation. Valid values: #{VALID_CREATORS.join(', ')}"

    property :reason,
      validate: ->(v) { v.nil? || (v.is_a?(String) && v.length >= 10 && v.length <= 300) },
      validation_message: "Reason must be a string between 10 and 300 characters",
      description: "Explanation of why this department was created (e.g., 'Emergency response to citizen requests')"
  end
end
