# ai_misc/ollama_client.rb

require 'omniai/openai'
require 'net/http'
require 'uri'
require 'json'
require 'awesome_print'

# Wrapper class extending OmniAI::OpenAI::Client for Ollama-specific endpoints
class OllamaClient < OmniAI::OpenAI::Client
  # Initialize the client with Ollama-specific defaults
  def initialize(host: 'http://localhost:11434', **options)
    super(host: host, api_key: nil, **options) # No API key needed for Ollama
    @ollama_uri = URI.parse(host)              # Base URI for custom Ollama requests
  end

  # Fetch list of available models from /api/tags
  # Returns an array of model details (name, modified_at, size, digest)
  def list_models
    response = ollama_get('/api/tags')
    response['models'] || []
  rescue => e
    raise "Failed to fetch models: #{e.message}"
  end

  # Fetch list of running models and their resource usage from /api/ps
  # Returns an array of running model details (name, size, loaded, memory_used)
  def list_running_models
    response = ollama_get('/api/ps')
    response['models'] || []
  rescue => e
    raise "Failed to fetch running models: #{e.message}"
  end

  # Fetch the Ollama server version from /api/version
  # Returns a string with the version number (e.g., "0.1.32")
  def get_version
    response = ollama_get('/api/version')
    response['version'] || 'Unknown'
  rescue => e
    raise "Failed to fetch server version: #{e.message}"
  end

  private

  # Helper method to perform GET requests to Ollama endpoints and parse JSON
  def ollama_get(path)
    uri = @ollama_uri.dup
    uri.path = path
    response = Net::HTTP.get_response(uri)
    unless response.is_a?(Net::HTTPSuccess)
      raise "HTTP request failed: #{response.code} #{response.message}"
    end
    JSON.parse(response.body)
  end
end

# Example usage
if __FILE__ == $0
  begin
    client = OllamaClient.new

    response = client.chat "what is the place on earth?", model: 'llama3.3'

    ap response.data

    puts "="*64

    # Get and display the server version
    version = client.get_version
    puts "Ollama Server Version: #{version}"

    # List all available models
    puts "\nAvailable Models:"
    models = client.list_models
    if models.empty?
      puts "No models available."
    else
      models.each do |model|
        puts "- #{model['name']} (Size: #{model['size']}, Modified: #{model['modified_at']})"
      end
    end

    # List running models
    puts "\nRunning Models:"
    running = client.list_running_models
    if running.empty?
      puts "No models currently running."
    else
      running.each do |model|
        puts "- #{model['name']} (Memory Used: #{model['memory_used']})"
      end
    end

    # Example of using inherited OmniAI::OpenAI::Client method (e.g., chat)
    # Note: This assumes Ollama's /v1/chat/completions endpoint is compatible
    puts "\nTesting inherited chat method:"
    chat_response = client.chat(messages: [{ role: 'user', content: 'Hi, how are you?' }], model: 'llama3:latest')
    puts "Chat Response: #{chat_response['choices'][0]['message']['content']}"

  rescue StandardError => e
    puts "Error: #{e.message}"
  end
end
