# my_client_test.rb

require 'ostruct'

require 'minitest/autorun'
require 'mocha/minitest'
require_relative 'my_client'

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
    MyClient.use(TestMiddleware)
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
    MyClient.configure do |config|
      config.logger = @logger
      config.timeout = 30
      config.return_raw = true
    end

    assert_equal @logger, MyClient.configuration.logger
    assert_equal 30, MyClient.configuration.timeout
    assert_equal true, MyClient.configuration.return_raw
  end

  def test_provider_configuration
    MyClient.configure do |config|
      config.provider(:openai) do
        {
          organization: 'org-123'
        }
      end
    end

    client = MyClient.new('gpt-3.5-turbo')
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
end

class TestMiddleware
  def self.call(client, next_middleware, *args)
    result = next_middleware.call
    result.data['choices'][0]['message']['content'] += " - Processed by TestMiddleware"
    result
  end
end
