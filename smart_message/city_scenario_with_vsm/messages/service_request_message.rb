# messages/service_request_message.rb
# Message for requesting new city services from the City Council

require_relative '../smart_message/lib/smart_message'

module Messages
  class ServiceRequestMessage < SmartMessage::Base
    version 1
    description "Request for City Council to create or provide a new city service/department"
    
    transport SmartMessage::Transport::RedisTransport.new
    serializer SmartMessage::Serializer::Json.new
    
    property :request_id, default: -> { SecureRandom.uuid }
    property :requesting_service, default: 'unknown'
    property :emergency_type
    property :description
    property :urgency, default: 'normal'  # low, normal, high, critical
    property :original_call_id
    property :timestamp, default: -> { Time.now.iso8601 }
    property :details, default: {}
  end
end