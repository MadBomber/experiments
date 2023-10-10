require "openai"
require "tempfile"

module MethodGenerator
  def self.included(base)
    base.instance_variable_set(:@source_file, caller_locations.first.path)
    base.extend ClassMethods
  end

  module ClassMethods
    def source_file_contents
      File.read(@source_file) if @source_file
    end
  end

  def method_missing(method_name, *args, &block)
    puts "You tried to call #{method_name} which isn't implemented. Calling Openai to request implementation..."

    code, defmethod = generate_implementation(
                        method_name,
                        args,
                        self.class.source_file_contents
                      )

    debug_me{[
      :code,
      :defmethod
    ]}

    puts
    puts "Proposed implementation of #{method_name}:\n\r#{code}\n\r"
    puts "Do you want to add this implementation to the class? (y/n)"
    puts

    input = gets.chomp

    if input == "y"
      tempfile = Tempfile.new("generated_method.rb")
      tempfile.write(code)
      tempfile.close

      system("subl -w #{tempfile.path}")

      tempfile.open
      defmethod = tempfile.read
      tempfile.close
      tempfile.unlink


      debug_me("before eval"){[
        :defmethod
      ]}


      eval("self.class.#{defmethod}")
      self.send(method_name, *args, &block)
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    true
  end
  
  #############################################################
  private

  def generate_implementation(method_name, args, file_contents)
    client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
    response = client.chat(
      parameters: {
        model: "gpt-3.5-turbo",
        messages: [
          {
            "role": "user",
            "content": <<~EOS
              You are an expert ruby programmer.
              Given the method named: #{method_name}, arguments #{args}
              and the contents of the file: #{file_contents} as context.
              What would be your best guess as to the method's implementation?
            EOS
          }
        ],
        function_call: {name: "implementation"},
        functions: [
          {
            name: "implementation",
            description: "The implementation of the requested method",
            parameters: {
              type: "object",
              properties: {
                code: {
                  type: :string,
                  description: "The implementation of the requested method using defmethod from ruby"
                },
                defmethod: {
                  type: :string,
                  description: "a oneliner using defmethod that returns the implementation of the requested method"
                }
              },
              required: ["code"]
            }
          }
        ]
      }
    )
    message = response.dig("choices", 0, "message")

    debug_me{[
      :response,
      :message
    ]}


    if message["role"] == "assistant" && message["function_call"]
      function_name = message.dig("function_call", "implementation")
      args = JSON.parse(
        message.dig("function_call", "arguments"), { symbolize_names: true }
      )

      debug_me('== RETURNING =='){[
        "args[:code]",
        "args[:defmethod]"
      ]}

      return [args[:code], args[:defmethod]]
    end
  end
end
