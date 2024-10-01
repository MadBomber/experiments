# ai_client_test.rb

require 'ostruct'

require 'minitest/autorun'
require 'mocha/minitest'
require_relative 'ai_client'

class AiClientTest < Minitest::Test
  # runs before each test case
  def setup
    @model  = 'gpt-3.5-turbo'
    @logger = Logger.new(STDOUT)

    AiClient.clear_middlewares
    @client = AiClient.new(@model, logger: @logger)
    
    @client.instance_variable_set(:@last_response, nil)
    @client.instance_variable_set(:@return_raw, false)
  end


  def test_initialize
    assert_equal :openai, @client.provider
    assert_equal :text_to_text, @client.model_type
    assert_equal @logger, @client.logger
  end


  def test_determine_provider
    assert_equal :anthropic, @client.send(:determine_provider, 'claude-2')
    assert_equal :openai, @client.send(:determine_provider, 'gpt-4')
    assert_equal :google, @client.send(:determine_provider, 'gemini-pro')
    assert_equal :mistral, @client.send(:determine_provider, 'mistral-medium')
    assert_equal :localai, @client.send(:determine_provider, 'local-model')
    assert_equal :ollama, @client.send(:determine_provider, 'llama-7b')

    assert_raises(ArgumentError) { @client.send(:determine_provider, 'unknown-model') }
  end


  def test_determine_model_type
    assert_equal :text_to_text, @client.send(:determine_model_type, 'gpt-3.5-turbo')
    assert_equal :speech_to_text, @client.send(:determine_model_type, 'whisper-1')
    assert_equal :text_to_speech, @client.send(:determine_model_type, 'tts-1')
    assert_equal :text_to_image, @client.send(:determine_model_type, 'dall-e-3')

    assert_raises(ArgumentError) { @client.send(:determine_model_type, 'unknown-model') }
  end


  def test_chat
    mock_client = mock()
    mock_client.expects(:chat).returns(OpenStruct.new(data: {'choices' => [{'message' => {'content' => 'Generated text'}}]}))
    @client.instance_variable_set(:@client, mock_client)

    result = @client.chat([{role: 'user', content: 'Hello'}])
    
    assert_equal "Generated text", result
  end


  def test_middleware
    AiClient.use(TestMiddleware)
    mock_client = mock()
    mock_client.expects(:chat).returns(OpenStruct.new(data: {'choices' => [{'message' => {'content' => 'Generated text'}}]}))
    @client.instance_variable_set(:@client, mock_client)

    result = @client.chat([{role: 'user', content: 'Hello'}])
    assert_equal "Generated text - Processed by TestMiddleware", result
  end


  def test_transcribe
    mock_client = mock()
    mock_client.expects(:transcribe).returns('Transcribed text')
    @client.instance_variable_set(:@client, mock_client)

    result = @client.transcribe('audio.mp3')
    assert_equal 'Transcribed text', result
  end


  def test_speak
    mock_client = mock()
    mock_client.expects(:speak).returns('Generated audio')
    @client.instance_variable_set(:@client, mock_client)

    result = @client.speak('Hello, world!')
    assert_equal 'Generated audio', result
  end


  def test_embed
    mock_client = mock()
    mock_client.expects(:embed).returns([0.1, 0.2, 0.3])
    @client.instance_variable_set(:@client, mock_client)

    result = @client.embed('Text to embed')
    assert_equal [0.1, 0.2, 0.3], result
  end


  def test_batch_embed
    mock_client = mock()
    mock_client.expects(:embed).twice.returns([0.1, 0.2, 0.3])
    @client.instance_variable_set(:@client, mock_client)

    result = @client.batch_embed(['Text 1', 'Text 2'], batch_size: 1)
    assert_equal [0.1, 0.2, 0.3, 0.1, 0.2, 0.3], result
  end


  def test_configuration
    AiClient.configure do |config|
      config.logger = @logger
      config.timeout = 30
      config.return_raw = true
    end

    assert_equal @logger, AiClient.configuration.logger
    assert_equal 30, AiClient.configuration.timeout
    assert_equal true, AiClient.configuration.return_raw
  end


  def test_provider_configuration
    AiClient.configure do |config|
      config.provider(:openai) do
        {
          organization: 'org-123'
        }
      end
    end

    client = AiClient.new('gpt-3.5-turbo')
    assert_equal 'org-123', client.instance_variable_get(:@options)[:organization]
  end


  def test_content_extraction
    @client.instance_variable_set(:@provider, :openai)
    @client.instance_variable_set(:@last_response, OpenStruct.new(data: {'choices' => [{'message' => {'content' => 'OpenAI content'}}]}))
    assert_equal 'OpenAI content', @client.content

    @client.instance_variable_set(:@provider, :anthropic)
    @client.instance_variable_set(:@last_response, OpenStruct.new(data: {'content' => [{'text' => 'Anthropic content'}]}))
    assert_equal 'Anthropic content', @client.content

    @client.instance_variable_set(:@provider, :google)
    @client.instance_variable_set(:@last_response, OpenStruct.new(data: {'candidates' => [{'content' => {'parts' => [{'text' => 'Google content'}]}}]}))
    assert_equal 'Google content', @client.content

    @client.instance_variable_set(:@provider, :mistral)
    @client.instance_variable_set(:@last_response, OpenStruct.new(data: {'choices' => [{'message' => {'content' => 'Mistral content'}}]}))
    assert_equal 'Mistral content', @client.content

    @client.instance_variable_set(:@provider, :unknown)
    assert_raises(NotImplementedError) { @client.content }
  end


  def test_invalid_model
    assert_raises(ArgumentError) { AiClient.new('invalid_model') }
  end


  def test_invalid_provider
    assert_raises(ArgumentError, "Unsupported provider: invalid_provider") do
      AiClient.new('gpt-3.5-turbo', provider: :invalid_provider)
    end
  end


  def test_raw_content_flag_when_true
    mock_client = mock()
    response_data = {'choices' => [{'message' => {'content' => 'Raw content'}}]}
    mock_client.expects(:chat).returns(OpenStruct.new(data: response_data))

    @client.instance_variable_set(:@client, mock_client)
    @client.instance_variable_set(:@last_response, OpenStruct.new(data: response_data))

    @client.instance_variable_set(:@return_raw, true)
    result = @client.chat([{ role: 'user', content: 'Hello' }])
    assert_equal response_data, result.data
  end


  def test_raw_content_flag_when_false
    mock_client = mock()
    response_data = {'choices' => [{'message' => {'content' => 'Raw content'}}]}
    mock_client.expects(:chat).returns(OpenStruct.new(data: response_data))

    @client.instance_variable_set(:@client, mock_client)
    @client.instance_variable_set(:@last_response, OpenStruct.new(data: response_data))

    @client.instance_variable_set(:@return_raw, false)
    result = @client.chat([{ role: 'user', content: 'Hello' }])
    assert_equal 'Raw content', result
  end



  def test_batch_embed_with_large_inputs
    mock_client = mock()
    mock_client.expects(:embed).returns([0.1, 0.2, 0.3]).twice
    @client.instance_variable_set(:@client, mock_client)

    large_input = Array.new(200) { |i| "Text #{i + 1}" }
    result = @client.batch_embed(large_input, batch_size: 100)
    assert_equal [0.1, 0.2, 0.3, 0.1, 0.2, 0.3], result
  end


  def test_timeouts_in_configuration
    AiClient.configure do |config|
      config.timeout = 10
    end

    assert_equal 10, AiClient.configuration.timeout
    new_client = AiClient.new(@model)
    assert_equal 10, new_client.instance_variable_get(:@timeout)
  end


  def test_middleware_chain_order
    AiClient.clear_middlewares
    AiClient.use(Middleware1)
    AiClient.use(Middleware2)

    # NOTE: that the middleware must ve setup BEFORE
    #       an instance of the AiClient is created.
    @client = AiClient.new(@model, logger: @logger)

    mock_client = mock()
    mock_client.expects(:chat).returns(OpenStruct.new(data: {'choices' => [{'message' => {'content' => 'Generated text'}}]}))
    @client.instance_variable_set(:@client, mock_client)

    result = @client.chat([{role: 'user', content: 'Hello'}])

    assert_equal 'Generated text two one', result
  end


  def test_invalid_api_key
    ENV['OPENAI_API_KEY'] = ''
    assert_raises(ArgumentError) { AiClient.new('gpt-3.5-turbo') }
    ENV['OPENAI_API_KEY'] = 'valid_api_key' # reset to avoid affecting other tests
  end


  def test_response_storage
    mock_client = mock()
    mock_client.expects(:chat).returns(OpenStruct.new(data: {'choices' => [{'message' => {'content' => 'Stored response'}}]}))
    @client.instance_variable_set(:@client, mock_client)

    response = @client.chat([{role: 'user', content: 'Store this'}])
    assert_equal 'Stored response', @client.last_response.data.dig('choices', 0, 'message', 'content')
  end
end


class TestMiddleware
  def self.call(client, next_middleware, *args)
    result = next_middleware.call
    result.data['choices'][0]['message']['content'] += " - Processed by TestMiddleware"
    result
  end
end


class Middleware1
  def self.call(client, next_middleware, *args)
    client.instance_variable_set(:@middleware1_called, true)
    result = next_middleware.call
    result.data['choices'][0]['message']['content'] += " one"
    result
  end
end


class Middleware2
  def self.call(client, next_middleware, *args)
    client.instance_variable_set(:@middleware2_called, true)
    result = next_middleware.call
    result.data['choices'][0]['message']['content'] += " two"
    result
  end
end
