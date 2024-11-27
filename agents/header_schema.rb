# experiments/agents/header_schema.rb

require 'simple_json_schema_builder'

class HeaderSchema < SimpleJsonSchemaBuilder::Base
  object do
    string  :from_uuid,  required: true, examples: [SecureRandom.uuid]
    integer :event_id,   required: true, examples: [123]
  end
end
