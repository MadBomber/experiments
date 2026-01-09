# frozen_string_literal: true

module FactDb
  module LLM
    # Adapter for ruby_llm gem
    # Provides a unified interface for the LLM extractor
    #
    # @example Configure with OpenAI
    #   FactDb.configure do |config|
    #     config.llm_client = FactDb::LLM::Adapter.new(
    #       provider: :openai,
    #       api_key: ENV["OPENAI_API_KEY"],
    #       model: "gpt-4o-mini"
    #     )
    #   end
    #
    # @example Configure with Anthropic
    #   FactDb.configure do |config|
    #     config.llm_client = FactDb::LLM::Adapter.new(
    #       provider: :anthropic,
    #       api_key: ENV["ANTHROPIC_API_KEY"],
    #       model: "claude-sonnet-4-20250514"
    #     )
    #   end
    #
    # @example Configure via YAML (config/fact_db.yml)
    #   # llm_provider: anthropic
    #   # llm_model: claude-sonnet-4-20250514
    #   # llm_api_key: <%= ENV["ANTHROPIC_API_KEY"] %>
    #
    # @example Configure via environment variables
    #   # EVENT_CLOCK_LLM_PROVIDER=anthropic
    #   # EVENT_CLOCK_LLM_MODEL=claude-sonnet-4-20250514
    #   # EVENT_CLOCK_LLM_API_KEY=sk-...
    #
    class Adapter
      attr_reader :model, :provider

      PROVIDER_DEFAULTS = {
        openai: "gpt-4o-mini",
        anthropic: "claude-sonnet-4-20250514",
        gemini: "gemini-2.0-flash",
        ollama: "llama3.2",
        bedrock: "claude-sonnet-4",
        openrouter: "anthropic/claude-sonnet-4"
      }.freeze

      # Create an adapter for a specific LLM provider
      #
      # @param provider [Symbol] :openai, :anthropic, :gemini, :ollama, :bedrock, :openrouter
      # @param model [String] Model name (optional, uses provider default)
      # @param api_key [String] API key (optional if set via ENV)
      # @param options [Hash] Additional options passed to RubyLLM
      #
      def initialize(provider:, model: nil, api_key: nil, **options)
        @provider = provider.to_sym
        @model = model || PROVIDER_DEFAULTS[@provider]
        @options = options

        configure_ruby_llm(api_key)
      end

      # Send a prompt to the LLM and return the response text
      #
      # @param prompt [String] The prompt to send
      # @return [String] The response text
      def chat(prompt)
        chat_instance = RubyLLM.chat(model: model)
        response = chat_instance.ask(prompt)
        response.content
      end

      # Alias for compatibility with different client interfaces
      alias call chat
      alias complete chat

      private

      def configure_ruby_llm(api_key)
        require "ruby_llm"

        RubyLLM.configure do |config|
          case provider
          when :openai
            config.openai_api_key = api_key || ENV.fetch("OPENAI_API_KEY", nil)
          when :anthropic
            config.anthropic_api_key = api_key || ENV.fetch("ANTHROPIC_API_KEY", nil)
          when :gemini
            config.gemini_api_key = api_key || ENV.fetch("GEMINI_API_KEY", nil)
          when :ollama
            config.ollama_api_base = @options[:api_base] || "http://localhost:11434"
          when :bedrock
            config.bedrock_region = @options[:region] || ENV.fetch("AWS_REGION", "us-east-1")
            config.bedrock_api_key = api_key || ENV.fetch("AWS_ACCESS_KEY_ID", nil)
            config.bedrock_secret_key = @options[:secret_key] || ENV.fetch("AWS_SECRET_ACCESS_KEY", nil)
          when :openrouter
            config.openrouter_api_key = api_key || ENV.fetch("OPENROUTER_API_KEY", nil)
          else
            raise ConfigurationError, "Unknown LLM provider: #{provider}. " \
                                       "Supported: openai, anthropic, gemini, ollama, bedrock, openrouter"
          end
        end
      rescue LoadError
        raise ConfigurationError, "LLM adapter requires the 'ruby_llm' gem. Add it to your Gemfile:\n" \
                                  "  gem 'ruby_llm'"
      end
    end
  end
end
