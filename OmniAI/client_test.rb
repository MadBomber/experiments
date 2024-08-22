# client_test.rb

require 'minitest/autorun'
require 'mocha/minitest'
require_relative 'client'


# Mock Faraday if it's not available
unless defined?(Faraday)
  module Faraday
    class ConnectionFailed < StandardError; end
  end
end


class ClientTest < Minitest::Test
  def setup
    @api_key = 'test_api_key'
    @model = 'gpt-3.5-turbo'
    @logger = Logger.new(STDOUT)
    @client = Client.new(@api_key, @model, logger: @logger)
  end

  def test_initialize
    assert_equal :openai, @client.provider
    assert_equal :text_to_text, @client.model_type
  end

  def test_determine_provider
    assert_equal :anthropic, @client.send(:determine_provider, 'claude-2')
    assert_equal :openai, @client.send(:determine_provider, 'gpt-4')
    assert_equal :google, @client.send(:determine_provider, 'gemini-pro')
    assert_equal :cohere, @client.send(:determine_provider, 'command')
    assert_equal :ai21, @client.send(:determine_provider, 'j2-jumbo')
    assert_equal :localai, @client.send(:determine_provider, 'local-model')
    assert_equal :ollama, @client.send(:determine_provider, 'ollama-llama2')

    assert_raises(ArgumentError) { @client.send(:determine_provider, 'unknown-model') }
  end

  def test_determine_model_type
    assert_equal :text_to_text, @client.send(:determine_model_type, 'gpt-3.5-turbo')
    assert_equal :speech_to_text, @client.send(:determine_model_type, 'whisper-1')
    assert_equal :text_to_speech, @client.send(:determine_model_type, 'tts-1')
    assert_equal :text_to_image, @client.send(:determine_model_type, 'dall-e-3')

    assert_raises(ArgumentError) { @client.send(:determine_model_type, 'unknown-model') }
  end

  def test_process_text_to_text
    mock_client = mock()
    mock_client.expects(:chat).returns({'choices' => [{'message' => {'content' => 'Generated text'}}]})
    OmniAI::Client.expects(:new).returns(mock_client)

    client = Client.new(@api_key, 'gpt-3.5-turbo')
    result = client.process('Hello, world!')

    assert_equal 'Generated text', result
  end

  def test_process_speech_to_text
    mock_client = mock()
    mock_client.expects(:audio).returns(mock(transcribe: 'Transcribed text'))
    OmniAI::Client.expects(:new).returns(mock_client)

    client = Client.new(@api_key, 'whisper-1')
    result = client.process('audio_file.mp3')

    assert_equal 'Transcribed text', result
  end

  def test_process_text_to_speech
    mock_client = mock()
    mock_client.expects(:audio).returns(mock(speech: 'Generated speech'))
    OmniAI::Client.expects(:new).returns(mock_client)

    client = Client.new(@api_key, 'tts-1')
    result = client.process('Hello, world!')

    assert_equal 'Generated speech', result
  end

  def test_process_text_to_image
    mock_client = mock()
    mock_client.expects(:images).returns(mock(generate: 'Generated image'))
    OmniAI::Client.expects(:new).returns(mock_client)

    client = Client.new(@api_key, 'dall-e-3')
    result = client.process('A beautiful sunset')

    assert_equal 'Generated image', result
  end


  def test_handle_error
    mock_logger = Minitest::Mock.new
    7.times do  # Increased from 6 to 7
      mock_logger.expect :error, nil, [String]
      mock_logger.expect :debug?, false
    end

    @client.instance_variable_set(:@logger, mock_logger)
    @client.instance_variable_set(:@provider, :openai)

    original_mapping = Client::PROVIDER_ERROR_MAPPING.dup
    Client::PROVIDER_ERROR_MAPPING[:openai] = {
      'invalid_api_key' => Client::AuthenticationError,
      'rate_limit_exceeded' => Client::RateLimitError
    }

    begin
      error = OmniAI::Error.new("invalid_api_key: Authentication failed")
      assert_raises(Client::AuthenticationError) { @client.send(:handle_error, error) }

      error = OmniAI::Error.new("rate_limit_exceeded: Too many requests")
      assert_raises(Client::RateLimitError) { @client.send(:handle_error, error) }

      error = OmniAI::Error.new("unknown_error: Some unknown error")
      assert_raises(Client::APIError) { @client.send(:handle_error, error) }

      error = Timeout::Error.new
      assert_raises(Client::TimeoutError) { @client.send(:handle_error, error) }

      error = SocketError.new
      assert_raises(Client::NetworkError) { @client.send(:handle_error, error) }

      error = Faraday::ConnectionFailed.new("Connection failed")
      assert_raises(Client::NetworkError) { @client.send(:handle_error, error) }

      error = StandardError.new
      assert_raises(Client::BaseError) { @client.send(:handle_error, error) }

      mock_logger.verify
    ensure
      Client.send(:remove_const, :PROVIDER_ERROR_MAPPING)
      Client.const_set(:PROVIDER_ERROR_MAPPING, original_mapping)
    end
  end

  def test_with_retries
    @client.expects(:sleep).times(3)

    calls = 0
    assert_raises(Client::RateLimitError) do
      @client.send(:with_retries) do
        calls += 1
        raise Client::RateLimitError
      end
    end
    assert_equal 4, calls
  end
end
