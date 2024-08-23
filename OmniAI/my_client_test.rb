# my_client_test.rb

require 'minitest/autorun'
require 'mocha/minitest'
require_relative 'my_client'


# Mock Faraday if it's not available
unless defined?(Faraday)
  module Faraday
    class ConnectionFailed < StandardError; end
  end
end


class TestMiddleware
  def self.call(client, next_middleware, *args)
    result = next_middleware.call
    result + " - Processed by TestMiddleware"
  end
end


class MyClientTest < Minitest::Test
  def setup
    @model = 'gpt-3.5-turbo'
    @logger = Logger.new(STDOUT)
    @client = MyClient.new(@model, logger: @logger)
    MyClient.clear_middlewares
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

    client = MyClient.new('gpt-3.5-turbo')
    result = client.process('Hello, world!')

    assert_equal 'Generated text', result
  end

  def test_process_speech_to_text
    mock_client = mock()
    mock_client.expects(:audio).returns(mock(transcribe: 'Transcribed text'))
    OmniAI::Client.expects(:new).returns(mock_client)

    client = MyClient.new('whisper-1')
    result = client.process('audio_file.mp3')

    assert_equal 'Transcribed text', result
  end

  def test_process_text_to_speech
    mock_client = mock()
    mock_client.expects(:audio).returns(mock(speech: 'Generated speech'))
    OmniAI::Client.expects(:new).returns(mock_client)

    client = MyClient.new('tts-1')
    result = client.process('Hello, world!')

    assert_equal 'Generated speech', result
  end

  def test_process_text_to_image
    mock_client = mock()
    mock_client.expects(:images).returns(mock(generate: 'Generated image'))
    OmniAI::Client.expects(:new).returns(mock_client)

    client = MyClient.new('dall-e-3')
    result = client.process('A beautiful sunset')

    assert_equal 'Generated image', result
  end

  def test_handle_error
    mock_logger = mock('logger')
    mock_logger.stubs(:error)
    mock_logger.stubs(:debug?).returns(false)

    @client.instance_variable_set(:@logger, mock_logger)
    @client.instance_variable_set(:@provider, :openai)

    original_mapping = MyClient::PROVIDER_ERROR_MAPPING.dup
    MyClient::PROVIDER_ERROR_MAPPING[:openai] = {
      'invalid_api_key' => MyClient::AuthenticationError,
      'rate_limit_exceeded' => MyClient::RateLimitError
    }

    begin
      error = StandardError.new("Quota exceeded")
      assert_raises(MyClient::QuotaExceededError) { @client.send(:handle_error, error) }

      error = StandardError.new("Some other unexpected error")
      assert_raises(MyClient::BaseError) { @client.send(:handle_error, error) }

      error = OmniAI::Error.new("invalid_api_key: Authentication failed")
      assert_raises(MyClient::AuthenticationError) { @client.send(:handle_error, error) }

      error = OmniAI::Error.new("rate_limit_exceeded: Too many requests")
      assert_raises(MyClient::RateLimitError) { @client.send(:handle_error, error) }

      error = Timeout::Error.new
      assert_raises(MyClient::TimeoutError) { @client.send(:handle_error, error) }

      error = SocketError.new
      assert_raises(MyClient::NetworkError) { @client.send(:handle_error, error) }

    ensure
      MyClient.send(:remove_const, :PROVIDER_ERROR_MAPPING)
      MyClient.const_set(:PROVIDER_ERROR_MAPPING, original_mapping)
    end
  end



  def test_with_retries
    @client.expects(:sleep).with(2).once
    @client.expects(:sleep).with(4).once
    @client.expects(:sleep).with(8).once
    @client.expects(:sleep).with(16).once

    calls = 0
    assert_raises(MyClient::RateLimitError) do
      @client.send(:with_retries, max_retries: 4) do  # Allow for 4 retries
        calls += 1
        raise MyClient::RateLimitError
      end
    end
    assert_equal 5, calls  # Magic: 1 (original) + 4 retries
  end


  def test_middleware
    MyClient.use(TestMiddleware)

    mock_client = mock()
    mock_client.expects(:chat).returns({'choices' => [{'message' => {'content' => 'Generated text'}}]})
    OmniAI::Client.expects(:new).returns(mock_client)

    client = MyClient.new('gpt-3.5-turbo')
    result = client.process('Hello, world!')

    assert_equal 'Generated text - Processed by TestMiddleware', result
  end




  def test_configuration
    MyClient.configure do |config|
      config.max_retries = 5
      config.base_delay = 2
      config.max_delay = 30
    end

    assert_equal 5, MyClient.configuration.max_retries
    assert_equal 2, MyClient.configuration.base_delay
    assert_equal 30, MyClient.configuration.max_delay
  end

  def test_configure_provider
    MyClient.configure_provider(:openai) do
      {
        organization: 'org-123',
        api_version: 'v1'
      }
    end

    client = MyClient.new('gpt-3.5-turbo')
    assert_equal({ organization: 'org-123', api_version: 'v1' }, client.instance_variable_get(:@provider_config))
  end



  def test_middleware
      MyClient.use(TestMiddleware)

      mock_client = mock()
      mock_client.expects(:chat).returns({'choices' => [{'message' => {'content' => 'Generated text'}}]})
      OmniAI::Client.expects(:new).returns(mock_client)

      client = MyClient.new('gpt-3.5-turbo')
      result = client.process('Hello, world!')

      assert_equal 'Generated text - Processed by TestMiddleware', result
    end


end
