# frozen_string_literal: true

require "anyway_config"
require "logger"

module FactDb
  class Config < Anyway::Config
    config_name :fact_db

    # Database configuration
    attr_config :database_url
    attr_config database_pool_size: 5,
                database_timeout: 30_000

    # Embedding configuration
    attr_config :embedding_generator
    attr_config embedding_dimensions: 1536

    # LLM configuration
    attr_config :llm_client, :llm_provider, :llm_model, :llm_api_key

    # Extraction configuration
    attr_config default_extractor: :manual

    # Entity resolution thresholds
    attr_config fuzzy_match_threshold: 0.85,
                auto_merge_threshold: 0.95

    # Logging
    attr_config :logger
    attr_config log_level: :info

    # Build LLM client from configuration if not explicitly set
    def llm_client
      return super if super

      return nil unless llm_provider

      @llm_client ||= LLM::Adapter.new(
        provider: llm_provider.to_sym,
        model: llm_model,
        api_key: llm_api_key
      )
    end

    def logger
      super || Logger.new($stdout, level: log_level)
    end

    def validate!
      raise ConfigurationError, "Database URL required" unless database_url

      self
    end
  end

  class << self
    def config
      @config ||= Config.new
    end

    def configure
      yield(config) if block_given?
      config
    end

    def reset_configuration!
      @config = nil
    end
  end
end
