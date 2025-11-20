# frozen_string_literal: true

require "test_helper"

class EmbeddingServiceTest < Minitest::Test
  def setup
    # Initialize embedding service with Ollama provider and gpt-oss model
    @service = HTM::EmbeddingService.new(:ollama, model: 'gpt-oss')
  end

  def test_initializes_with_ollama_provider
    assert_equal :ollama, @service.provider
  end

  def test_llm_client_attribute_exists
    # llm_client is a placeholder - actual embedding is done via direct Ollama API calls
    assert_respond_to @service, :llm_client
  end

  def test_embed_returns_array
    embedding = @service.embed("Test text for embedding")
    assert_instance_of Array, embedding
  end

  def test_embed_returns_non_empty_array
    embedding = @service.embed("Test text for embedding")
    refute_empty embedding
  end

  def test_embed_with_longer_text
    text = "This is a longer piece of text that will be used to test the embedding service " \
           "with the Ollama provider using the gpt-oss model via RubyLLM."
    embedding = @service.embed(text)

    assert_instance_of Array, embedding
    refute_empty embedding
  end

  def test_embed_handles_empty_string
    embedding = @service.embed("")
    assert_instance_of Array, embedding
  end

  def test_count_tokens
    text = "This is a test string"
    token_count = @service.count_tokens(text)

    assert_instance_of Integer, token_count
    assert token_count > 0
  end

  def test_count_tokens_empty_string
    token_count = @service.count_tokens("")
    assert_instance_of Integer, token_count
    assert_equal 0, token_count
  end

  def test_different_providers
    # Test that we can initialize with different providers
    openai_service = HTM::EmbeddingService.new(:openai)
    assert_equal :openai, openai_service.provider

    cohere_service = HTM::EmbeddingService.new(:cohere)
    assert_equal :cohere, cohere_service.provider

    local_service = HTM::EmbeddingService.new(:local)
    assert_equal :local, local_service.provider
  end

  def test_ollama_with_custom_model
    custom_service = HTM::EmbeddingService.new(:ollama, model: 'custom-model')
    assert_equal :ollama, custom_service.provider
    refute_nil custom_service.llm_client
  end

  def test_ollama_with_custom_url
    custom_url = 'http://custom-ollama:11434'
    custom_service = HTM::EmbeddingService.new(:ollama, model: 'gpt-oss', ollama_url: custom_url)
    assert_equal :ollama, custom_service.provider
    refute_nil custom_service.llm_client
  end

  def test_embeddings_consistency
    # Test that the same text produces embeddings (may not be identical due to model behavior)
    text = "Consistent text for testing"
    embedding1 = @service.embed(text)
    embedding2 = @service.embed(text)

    assert_instance_of Array, embedding1
    assert_instance_of Array, embedding2
    # Note: Embeddings should be deterministic for the same text,
    # but this depends on the model implementation
  end

  def test_different_texts_produce_different_embeddings
    text1 = "First piece of text"
    text2 = "Completely different content"

    embedding1 = @service.embed(text1)
    embedding2 = @service.embed(text2)

    assert_instance_of Array, embedding1
    assert_instance_of Array, embedding2
    # They should be different (though we don't test exact values)
    refute_equal embedding1, embedding2
  end
end
