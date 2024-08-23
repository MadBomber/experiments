# experiments/OmniAI/my_client.rb
# Usage example:
# MyClient.configure do |config|
#   config.max_retries = 5
#   config.base_delay = 2
#   config.max_delay = 30
# end
#
# MyClient.configure_provider(:openai) do
#   {
#     organization: 'org-123',
#     api_version: 'v1'
#   }
# end
#
# MiddleWarz idea to implement comments, directives and RAG
#
# Usage:
# class LoggingMiddleware
#   def self.call(client, next_middleware, *args)
#     start_time = Time.now
#     result = next_middleware.call
#     end_time = Time.now
#     client.logger.info("API call took #{end_time - start_time} seconds")
#     result
#   end
# end
#
# MyClient.use(LoggingMiddleware)

require 'faraday'
require 'omniai'
require 'logger'

class MyClient
  class BaseError < StandardError; end
  class APIError < BaseError; end
  class RateLimitError < APIError; end
  class AuthenticationError < APIError; end
  class InvalidRequestError < BaseError; end
  class UnsupportedModelError < BaseError; end
  class UnsupportedProviderError < BaseError; end
  class NetworkError < BaseError; end
  class TimeoutError < BaseError; end
  class QuotaExceededError < BaseError; end
  class InvalidModelError < BaseError; end

  class Configuration
    attr_accessor :max_retries, :base_delay, :max_delay

    def initialize
      @max_retries = 3
      @base_delay = 2
      @max_delay = 16
    end
  end


  PROVIDER_ERROR_MAPPING = {
    anthropic: {
      'invalid_api_key' => AuthenticationError,
      'rate_limit_exceeded' => RateLimitError,
      # TODO: Add more Anthropic-specific errors
    },
    openai: {
      'invalid_request_error' => InvalidRequestError,
      'authentication_error' => AuthenticationError,
      'rate_limit_exceeded' => RateLimitError,
      # TODO: Add more OpenAI-specific errors
    },
    # TODO: Add mappings for other providers
  }

  PROVIDER_PATTERNS = {
    anthropic: /^claude/i,
    openai: /^(gpt|davinci|curie|babbage|ada|whisper|tts|dall-e)/i,
    google: /^(gemini|palm)/i,
    cohere: /^(command|generate)/i,
    ai21: /^j2-/i,
    localai: /^local-/i,
    ollama: /^ollama-/i
  }

  MODEL_TYPES = {
    text_to_text: /^(gpt|davinci|curie|babbage|ada|claude|gemini|palm|command|generate|j2-)/i,
    speech_to_text: /^whisper/i,
    text_to_speech: /^tts/i,
    text_to_image: /^dall-e/i
  }

  attr_reader :provider, :model_type

  def initialize(model, base_url: nil, logger: Logger.new(STDOUT), timeout: nil, **options)
    @model = model

    @provider = determine_provider(model)
    @provider_config = self.class.provider_config[@provider]&.call || {}

    @model_type = determine_model_type(model)
    @base_url = base_url
    @logger = logger
    @timeout = timeout
    @options = options
    @client = create_client
  end

  def chat(messages, tools: nil, **params)
    @client.chat(messages, model: @model, tools: tools, **params)
  end

  # Update existing methods to use middlewares:
  # def chat(messages, **params)
  #   call_with_middlewares(:chat_without_middlewares, messages, **params)
  # end
  #
  # def chat_without_middlewares(messages, **params)
  #   @client.chat(messages, model: @model, **params)
  # end




  def transcribe(audio, format: nil, **params)
    @client.transcribe(audio, model: @model, format: format, **params)
  end

  def speak(text, format: nil, **params)
    @client.speak(text, model: @model, format: format, **params)
  end

  def embed(input, **params)
    @client.embed(input, model: @model, **params)
  end

  def batch_embed(inputs, batch_size: 100, **params)
    inputs.each_slice(batch_size).flat_map do |batch|
      embed(batch, **params)
    end
  end


  def process(input, request_id: SecureRandom.uuid, **params)
    debug_me{[
      :input,
      :request_id,
      :params
    ]}

    @logger.info("Processing request #{request_id}")

    result = if self.class.middlewares.any?
      debug_me('using middleware')
      call_with_middlewares(:process_without_middlewares, input, **params)
    else
      debug_me('NOT using MW')
      process_without_middlewares(input, **params)
    end

    debug_me

    @logger.info("Finished processing request #{request_id}")
    result
  rescue StandardError => e
    @logger.error("Error processing input: #{e.message}")
    raise
  end



  def process_without_middlewares(input, **params)
    debug_me{[
      :input,
      :params,
      '@model_type'
    ]}


    case @model_type
    when :text_to_text
      debug_me
      generate_text(input, **params)
    when :speech_to_text
      debug_me
      transcribe_audio(input, **params)
    when :text_to_speech
      debug_me
      generate_speech(input, **params)
    when :text_to_image
      debug_me
      generate_image(input, **params)
    else
      debug_me
      raise NotImplementedError, "Unsupported model type: #{@model_type}"
    end
  end



  def call_with_middlewares(method, *args, &block)
    stack = self.class.middlewares.reverse.reduce(-> { send(method, *args, &block) }) do |next_middleware, middleware|
      -> { middleware.call(self, next_middleware, *args) }
    end
    stack.call
  end

  ##############################################

  def self.configure
    yield(configuration)
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.provider_config
    @provider_config ||= {}
  end

  def self.configure_provider(provider, &block)
    provider_config[provider] = block
  end

  def self.middlewares
    @middlewares ||= []
  end

  def self.use(middleware)
    middlewares << middleware
  end

  def self.clear_middlewares
    @middlewares = []
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

    OmniAI::Client.find(provider: @provider.to_s, **client_options)
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


  def generate_text(prompt, max_tokens: 100, stream: false, **params)
    debug_me{[
      :prompt,
      :max_tokens,
      :stream,
      :params
    ]}

    messages = [{ role: 'user', content: prompt }]

    debug_me{[
      :messages
    ]}

    with_retries do
      if stream
        debug_me
        stream_response(messages, max_tokens, params)
      else
        debug_me
        single_response(messages, max_tokens, params)
      end
    end
  rescue StandardError => e
    debug_me('== ERROR =='){[ :e ]}
    handle_error(e)
  end


  def single_response(messages, max_tokens, params)
    debug_me{[
      :messages,
      :max_tokens,
      :params
    ]}
    response = @client.chat(
      model: @model,
      messages: messages,
      max_tokens: max_tokens,
      **params
    )
    debug_me{[
      :response
    ]}
    extract_content(response)
  end

  def stream_response(messages, max_tokens, params)
    Enumerator.new do |yielder|
      @client.chat(
        model: @model,
        messages: messages,
        max_tokens: max_tokens,
        stream: true,
        **params
      ) do |chunk|
        yielder << extract_content(chunk)
      end
    end
  end

  def extract_content(response)
    debug_me{[
      :response,
      '@provider'
    ]}
    case @provider
    when :anthropic, :openai, :google, :localai, :ollama
      response.dig('choices', 0, 'message', 'content') || response.dig('choices', 0, 'delta', 'content')
    when :cohere
      response.dig('generations', 0, 'text')
    when :ai21
      response.dig('completions', 0, 'data', 'text')
    else
      raise NotImplementedError, "Content extraction not implemented for provider: #{@provider}"
    end
  end

  def transcribe_audio(audio_file, **params)
    with_retries do
      @client.audio.transcribe(model: @model, file: audio_file, **params)
    end
  rescue StandardError => e
    handle_error(e)
  end

  def generate_speech(text, **params)
    with_retries do
      @client.audio.speech(model: @model, input: text, **params)
    end
  rescue StandardError => e
    handle_error(e)
  end

  def generate_image(prompt, **params)
    with_retries do
      @client.images.generate(model: @model, prompt: prompt, **params)
    end
  rescue StandardError => e
    handle_error(e)
  end


  def handle_error(error)
    case error
    when OmniAI::Error
      error_type = error.message.split(':').first.strip.downcase
      mapped_error = PROVIDER_ERROR_MAPPING[@provider]&.[](error_type)
      if mapped_error
        raise mapped_error.new("#{@provider} API error: #{error.message}")
      else
        raise APIError.new("#{@provider} API error: #{error.message}")
      end
    when Timeout::Error
      raise TimeoutError, "Request to #{@provider} timed out"
    when SocketError, defined?(Faraday::ConnectionFailed) ? Faraday::ConnectionFailed : StandardError
      raise NetworkError, "Network error when connecting to #{@provider}"
    else
      if error.message.downcase.include?('quota exceeded')
        raise QuotaExceededError, "Quota exceeded for #{@provider}"
      else
        raise BaseError, "Unexpected error: #{error.message}"
      end
    end
  ensure
    @logger.error("Error in #{@provider} API call: #{error.class} - #{error.message}")
    @logger.debug(error.backtrace.join("\n")) if @logger.debug? && error.backtrace
  end




  def with_retries(
    max_retries: self.class.configuration.max_retries,
    base_delay: self.class.configuration.base_delay,
    max_delay: self.class.configuration.max_delay
  )
    retries = 0
    begin
      yield
    rescue RateLimitError, NetworkError => e
      if retries < max_retries
        retries += 1
        delay = [base_delay * (2 ** (retries - 1)), max_delay].min
        @logger.warn("Retrying in #{delay} seconds due to error: #{e.message}")
        sleep(delay)
        retry
      else
        raise
      end
    end
  end

end

__END__

The provided `Client` class is quite comprehensive and covers a wide range of possibilities for different AI providers and model types. However, there are a few considerations and potential improvements:

1. Extensibility: While it covers major providers like OpenAI, Anthropic, Google, Cohere, AI21, LocalAI, and Ollama, new providers or models might emerge. Consider implementing a way to easily add new providers or model types without modifying the core code.

2. Error Handling: The error handling is basic. You might want to add more specific error types and handling for different scenarios (API errors, rate limiting, etc.).

3. Async Support: The current implementation is synchronous. For better performance, especially with streaming, consider adding asynchronous support.

4. Configuration: Consider allowing more flexible configuration, perhaps through a configuration file or environment variables.

5. Tokenization: Some operations might require tokenization, which isn't addressed in this client.

6. Fine-tuning and Model Management: If applicable, add support for model fine-tuning and management operations.

7. Caching: For improved performance, you might want to implement caching for certain responses.

8. Metrics and Logging: While there's basic logging, you might want to add more detailed metrics and logging for monitoring and debugging.

9. Rate Limiting: Consider implementing rate limiting to comply with API usage limits.

10. Input Validation: Add more robust input validation for the different model types and their specific requirements.

11. Output Processing: Depending on the use case, you might want to add more sophisticated output processing or formatting options.

12. Multi-modal Models: As AI evolves, you might need to support multi-modal models that can handle multiple types of input/output in a single call.

While this implementation is solid for many use cases, depending on your specific needs, you might want to expand it to cover these additional scenarios. The flexibility to easily add new providers and model types would be particularly valuable for future-proofing the client.
