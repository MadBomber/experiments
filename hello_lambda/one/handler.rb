require 'json'

def hello(event:, context:)
  {
    statusCode: 200,
    body: {
      message: "Hello #{ENV['USERNAME']} your function executed successfully!",
      input: event
    }.to_json
  }
end
