# experiments/OmniAI/my_client.rb

unless defined?(DebugMe)
  require 'debug_me'
  include DebugMe
end

require 'omniai'
require 'omniai/anthropic'
require 'omniai/google'
require 'omniai/mistral'
require 'omniai/openai'
require 'logger'

# Usage example:
# Configure general settings
#   MyClient.configure do |config|
#     config.logger = Logger.new('my_client.log')
#     config.return_raw = true
#   end
#
# Configure provider-specific settings
#   MyClient.configure do |config|
#     config.configure_provider(:openai) do
#       {
#         organization: 'org-123',
#         api_version: 'v1'
#       }
#     end
#   end
#
#
# Add middlewares
#   MyClient.use(RetryMiddleware.new(max_retries: 5, base_delay: 2, max_delay: 30))
#   MyClient.use(LoggingMiddleware.new(MyClient.configuration.logger))
#
# # Create a client instance
#   client = MyClient.new('gpt-3.5-turbo')

class MyClient
  class Configuration
    attr_accessor :logger, :timeout, :return_raw

    def initialize
      @logger = Logger.new(STDOUT)
      @timeout = nil
      @providers = {}
      @return_raw = false
    end

    def provider(name, &block)
      if block_given?
        @providers[name] = block
      else
        @providers[name]&.call || {}
      end
    end
  end

  PROVIDER_PATTERNS = {
    anthropic: /^claude/i,
    openai: /^(gpt|davinci|curie|babbage|ada|whisper|tts|dall-e)/i,
    google: /^(gemini|palm)/i,
    mistral: /^mistral/i,
    localai: /^local-/i,
    ollama: /llama-/i
  }

  MODEL_TYPES = {
    text_to_text: /^(gpt|davinci|curie|babbage|ada|claude|gemini|palm|command|generate|j2-)/i,
    speech_to_text: /^whisper/i,
    text_to_speech: /^tts/i,
    text_to_image: /^dall-e/i
  }

  attr_reader :provider, :model_type, :logger

  def initialize(model, **options)

    debug_me{[
      :model,
      :options
    ]}

    @model = model
    @provider = determine_provider(model)
    @model_type = determine_model_type(model)

    config = self.class.configuration
    provider_config = config.provider(@provider)

    @logger = options[:logger] || config.logger
    @timeout = options[:timeout] || config.timeout
    @base_url = options[:base_url] || provider_config[:base_url]

    @options = options.merge(provider_config)
    @client = create_client

    @last_response = nil
    @return_raw = config.return_raw
  end

  def response
    @last_response
  end

  def text
    get_content @last_response
  end

  ######################################
  def chat(messages, **params)
      result = call_with_middlewares(:chat_without_middlewares, messages, **params)
      @last_response = result
      @return_raw ? result : get_content(result)
    end


  def chat_without_middlewares(messages, **params)
    @client.chat(messages, model: @model, **params)
  end

  ######################################
  def transcribe(messages, **params)
    call_with_middlewares(:transcribe_without_middlewares, messages, **params)
  end

  def transcribe_without_middlewares(audio, format: nil, **params)
    @client.transcribe(audio, model: @model, format: format, **params)
  end

  ######################################
  def speak(messages, **params)
    call_with_middlewares(:speak_without_middlewares, messages, **params)
  end

  def speak_without_middlewares(text, format: nil, **params)
    @client.speak(text, model: @model, format: format, **params)
  end

  ######################################
  def embed(input, **params)
    @client.embed(input, model: @model, **params)
  end

  def batch_embed(inputs, batch_size: 100, **params)
    inputs.each_slice(batch_size).flat_map do |batch|
      embed(batch, **params)
    end
  end

  def call_with_middlewares(method, *args, &block)
    stack = self.class.middlewares.reverse.reduce(-> { send(method, *args, &block) }) do |next_middleware, middleware|
      -> { middleware.call(self, next_middleware, *args) }
    end
    stack.call
  end

  ##############################################
  class << self
    def configure
      yield(configuration)
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def middlewares
      @middlewares ||= []
    end

    def use(middleware)
      middlewares << middleware
    end

    def clear_middlewares
      @middlewares = []
    end
  end

  ##############################################
  private

  def create_client
    api_key = fetch_api_key
    client_options = {
      api_key: api_key,
      logger: @logger,
      timeout: @timeout
    }
    client_options[:base_url] = @base_url if @base_url
    client_options.merge!(@options)

    case @provider
    when :openai, :localai, :ollama
      OmniAI::OpenAI::Client.new(**client_options)
    when :anthropic
      OmniAI::Anthropic::Client.new(**client_options)
    when :google
      OmniAI::Google::Client.new(**client_options)
    when :mistral
      OmniAI::Mistral::Client.new(**client_options)
    else
      raise ArgumentError, "Unsupported provider: #{@provider}"
    end
  end

  def fetch_api_key
    env_var_name = "#{@provider.upcase}_API_KEY"
    api_key = ENV[env_var_name]

    if api_key.nil? || api_key.empty?
      raise ArgumentError, "API key not found in environment variable #{env_var_name}"
    end

    api_key
  end

  def determine_provider(model)
    PROVIDER_PATTERNS.find { |provider, pattern| model.match?(pattern) }&.first ||
      raise(ArgumentError, "Unsupported model: #{model}")
  end

  def determine_model_type(model)
    MODEL_TYPES.find { |type, pattern| model.match?(pattern) }&.first ||
      raise(ArgumentError, "Unable to determine model type for: #{model}")
  end

  def get_content(response)
    case @provider
    when :openai, :localai, :ollama
      response.data.dig('choices', 0, 'message', 'content')
    when :anthropic
      response['completion']
    when :google
      response.dig('candidates', 0, 'content', 'parts', 0, 'text')
    when :mistral
      response.dig('choices', 0, 'message', 'content')
    else
      raise NotImplementedError, "Content extraction not implemented for provider: #{@provider}"
    end
  end
end

#####################################
## Middleware Class Examples ##
###############################

# MyClient.use(
#   RetryMiddleware.new(
#     max_retries: 5,
#     base_delay: 2,
#     max_delay: 30
#   )
# )

class RetryMiddleware
  def initialize(max_retries: 3, base_delay: 2, max_delay: 16)
    @max_retries = max_retries
    @base_delay = base_delay
    @max_delay = max_delay
  end

  def call(client, next_middleware, *args)
    retries = 0
    begin
      next_middleware.call
    rescue OmniAI::RateLimitError, OmniAI::NetworkError => e
      if retries < @max_retries
        retries += 1
        delay = [@base_delay * (2 ** (retries - 1)), @max_delay].min
        client.logger.warn("Retrying in #{delay} seconds due to error: #{e.message}")
        sleep(delay)
        retry
      else
        raise
      end
    end
  end
end

# logger = Logger.new(STDOUT)
# MyClient.use(
#   LoggingMiddleware.new(logger)
# )
#
# Or, if you want to use the same logger as the MyClient:
# MyClient.use(
#   LoggingMiddleware.new(
#     MyClient.configuration.logger
#   )
# )

class LoggingMiddleware
  def initialize(logger)
    @logger = logger
  end

  def call(client, next_middleware, *args)
    method_name = args.first.is_a?(Symbol) ? args.first : 'unknown method'
    @logger.info("Starting #{method_name} call")
    start_time = Time.now

    result = next_middleware.call(*args)

    end_time = Time.now
    duration = end_time - start_time
    @logger.info("Finished #{method_name} call (took #{duration.round(3)} seconds)")

    result
  end
end