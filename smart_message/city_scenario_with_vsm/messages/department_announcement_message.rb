# messages/department_announcement_message.rb
# Message for announcing new city departments created by City Council

require_relative '../smart_message/lib/smart_message'

module Messages
  class DepartmentAnnouncementMessage < SmartMessage::Base
    property :announcement_id, default: -> { SecureRandom.uuid }
    property :department_name
    property :department_file
    property :status # 'created', 'launched', 'active', 'failed'
    property :description
    property :capabilities, default: []
    property :message_types, default: []
    property :launch_time, default: -> { Time.now.iso8601 }
    property :process_id # PID of launched department process
    property :created_by, default: 'city_council'
    property :reason # Why the department was created
    property :timestamp, default: -> { Time.now.iso8601 }
    
    def self.description
      "Announcement of new city department creation and launch status"
    end
  end
end