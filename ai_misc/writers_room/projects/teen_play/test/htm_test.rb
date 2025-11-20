# frozen_string_literal: true

require "test_helper"

class HTMTest < Minitest::Test
  def test_version_exists
    refute_nil ::HTM::VERSION
  end

  def test_version_format
    assert_match /\d+\.\d+\.\d+/, ::HTM::VERSION
  end

  def test_htm_class_exists
    assert defined?(HTM)
  end

  def test_embedding_service_class_exists
    assert defined?(HTM::EmbeddingService)
  end

  def test_working_memory_class_exists
    assert defined?(HTM::WorkingMemory)
  end

  def test_long_term_memory_class_exists
    assert defined?(HTM::LongTermMemory)
  end

  def test_database_class_exists
    assert defined?(HTM::Database)
  end

  def test_default_embedding_service_is_ollama
    # Create a mock HTM instance (without database)
    # We'll just test that ollama is the default provider
    service = HTM::EmbeddingService.new
    assert_equal :ollama, service.provider
  end

  def test_can_specify_gpt_oss_model
    service = HTM::EmbeddingService.new(:ollama, model: 'gpt-oss')
    assert_equal :ollama, service.provider
    refute_nil service.llm_client
  end

  def test_embedding_service_supports_multiple_providers
    # Test that different providers can be initialized
    [:ollama, :openai, :cohere, :local].each do |provider|
      service = HTM::EmbeddingService.new(provider)
      assert_equal provider, service.provider
    end
  end
end
