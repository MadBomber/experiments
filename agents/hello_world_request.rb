# experiments/agents/hello_world_request.rb


require_relative 'header_schema'

class HelloWorldRequest < SimpleJsonSchemaBuilder::Base
  object do
    object :header, schema: HeaderSchema

    string :greeting, required: false,  examples: ["Hello"]
    string :name,     required: true,   examples: ["World"]
  end
end
