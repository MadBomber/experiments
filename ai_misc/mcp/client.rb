# This is an AI translation of the provided Python MCP client code into Ruby.

require 'async'
require 'dotenv/load'
require 'mcp' # Assumed to be an equivalent Ruby MCP library
require 'anthropic'

class MCPClient
  def initialize
    # Initialize session and client objects
    @session = nil
    @anthropic = Anthropic.new # Update if any args required for initialization
  end

  async def connect_to_server(server_script_path)
    # Connect to an MCP server
    is_python = server_script_path.end_with?('.py')
    is_js = server_script_path.end_with?('.js')

    unless is_python || is_js
      raise "Server script must be a .py or .js file"
    end

    command = is_python ? 'python' : 'node'
    server_params = StdioServerParameters.new(
      command: command,
      args: [server_script_path],
      env: nil
    )

    stdio_transport = await stdio_client(server_params)
    @stdio, @write = stdio_transport
    @session = await ClientSession.new(@stdio, @write)

    await @session.initialize

    # List available tools
    response = await @session.list_tools
    tools = response.tools
    puts "\nConnected to server with tools: #{tools.map(&:name)}"
  end

  async def process_query(query)
    # Process a query using Claude and available tools
    messages = [{
      role: "user",
      content: query
    }]

    response = await @session.list_tools
    available_tools = response.tools.map do |tool|
      {
        name: tool.name,
        description: tool.description,
        input_schema: tool.input_schema
      }
    end

    # Initial Claude API call
    response = @anthropic.messages.create(
      model: "claude-3-5-sonnet-20241022",
      max_tokens: 1000,
      messages: messages,
      tools: available_tools
    )

    final_text = []

    response.content.each do |content|
      if content.type == 'text'
        final_text << content.text
      elsif content.type == 'tool_use'
        tool_name = content.name
        tool_args = content.input

        # Execute tool call
        result = await @session.call_tool(tool_name, tool_args)
        final_text << "[Calling tool #{tool_name} with args #{tool_args}]"

        # Continue conversation with tool results
        if content.text
          messages << {
            role: "assistant",
            content: content.text
          }
        end

        messages << {
          role: "user",
          content: result.content
        }

        # Get next response from Claude
        response = @anthropic.messages.create(
          model: "claude-3-5-sonnet-20241022",
          max_tokens: 1000,
          messages: messages
        )

        final_text << response.content[0].text
      end
    end

    return final_text.join("\n")
  end

  async def chat_loop
    puts "\nMCP Client Started!"
    puts "Type your queries or 'quit' to exit."

    while true
      print "\nQuery: "
      query = gets.strip

      break if query.downcase == 'quit'

      begin
        response = await process_query(query)
        puts "\n#{response}"
      rescue => e
        puts "\nError: #{e.message}"
      end
    end
  end

  async def cleanup
    # Clean up resources (if necessary, based on your library's cleanup mechanism)
    @session&.cleanup
  end
end

def main
  if ARGV.length < 1
    puts "Usage: ruby client.rb <path_to_server_script>"
    exit(1)
  end

  client = MCPClient.new
  begin
    Async do
      await client.connect_to_server(ARGV[0])
      await client.chat_loop
    end
  ensure
    await client.cleanup
  end
end

if __FILE__ == $0
  main
end

__END__

### Key Changes and Considerations:
1. **Async Handling**: Ruby’s `async` gem provides similar functionality to Python's `asyncio`, but syntax and usage may differ.
2. **Environment Variables**: Ruby's dotenv library handles the loading of environment variables, similar to the Python version.
3. **Class and Object Management**: Adapted the initialization and object management to Ruby's conventions.
4. **Loops and Input/Output**: Used Ruby's standard input and output methods.
5. **Error Handling**: Ruby's error handling is done using `begin...rescue`, and I've translated this directly from the Python `try...except`.
6. **Library Usage**: The code assumes equivalent libraries exist in Ruby, such as `mcp` and `anthropic`. You may need to adapt it further based on the actual libraries available or implemented in Ruby.
