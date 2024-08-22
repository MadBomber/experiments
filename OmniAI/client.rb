require 'faraday'
require 'omniai'
require 'logger'

class Client
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

  def initialize(api_key, model, base_url: nil, logger: Logger.new(STDOUT), **options)
    @api_key = api_key
    @model = model
    @provider = determine_provider(model)
    @model_type = determine_model_type(model)
    @base_url = base_url
    @logger = logger
    @options = options
    @client = create_client
  end

  def process(input, **params)
    case @model_type
    when :text_to_text
      generate_text(input, **params)
    when :speech_to_text
      transcribe_audio(input, **params)
    when :text_to_speech
      generate_speech(input, **params)
    when :text_to_image
      generate_image(input, **params)
    else
      raise NotImplementedError, "Unsupported model type: #{@model_type}"
    end
  rescue StandardError => e
    @logger.error("Error processing input: #{e.message}")
    raise
  end

  private

  def determine_provider(model)
    PROVIDER_PATTERNS.find { |provider, pattern| model.match?(pattern) }&.first ||
      raise(ArgumentError, "Unsupported model: #{model}")
  end

  def determine_model_type(model)
    MODEL_TYPES.find { |type, pattern| model.match?(pattern) }&.first ||
      raise(ArgumentError, "Unable to determine model type for: #{model}")
  end

  def create_client
    client_options = { api_key: @api_key }
    client_options[:base_url] = @base_url if @base_url
    client_options.merge!(@options)

    OmniAI::Client.new(**client_options)
  end


  def generate_text(prompt, max_tokens: 100, stream: false, **params)
    messages = [{ role: 'user', content: prompt }]
    with_retries do
      if stream
        stream_response(messages, max_tokens, params)
      else
        single_response(messages, max_tokens, params)
      end
    end
  rescue StandardError => e
    handle_error(e)
  end


  def single_response(messages, max_tokens, params)
    response = @client.chat(
      model: @model,
      messages: messages,
      max_tokens: max_tokens,
      **params
    )
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
      raise BaseError, "Unexpected error: #{error.message}"
    end
  ensure
    @logger.error("Error in #{@provider} API call: #{error.class} - #{error.message}")
    @logger.debug(error.backtrace.join("\n")) if @logger.debug? && error.backtrace
  end


  def with_retries(max_retries: 3, base_delay: 1, max_delay: 16)
    retries = 0
    begin
      yield
    rescue RateLimitError, NetworkError => e
      if retries < max_retries
        retries += 1
        delay = [base_delay * (2 ** retries), max_delay].min
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
