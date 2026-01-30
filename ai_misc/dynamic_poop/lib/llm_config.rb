# frozen_string_literal: true

require "ruby_llm"

# Configures RubyLLM for Ollama and chaos_to_the_rescue for runtime
# method generation. Degrades silently if Ollama is unreachable.

module LlmConfig
  OLLAMA_BASE = "http://localhost:11434/v1"
  MODEL       = "qwen3-coder:30b"

  @available = false

  class << self
    attr_reader :available
    alias_method :available?, :available

    def setup!
      configure_ruby_llm!
      verify_ollama!
      configure_chaos! if available?
    rescue => e
      @available = false
      LOGGER.warn("LlmConfig: setup failed (#{e.class}: #{e.message}), LLM features disabled")
    end

    # Send a prompt to Ollama via RubyLLM and return the response content string, or nil.
    def ask(prompt, system: nil)
      return nil unless available?

      chat = RubyLLM.chat(model: MODEL, provider: :ollama)
      chat.with_instructions(system) if system
      response = chat.ask(prompt)
      response.content
    rescue => e
      LOGGER.debug("LlmConfig.ask failed: #{e.class}: #{e.message}")
      nil
    end

    private

    def configure_ruby_llm!
      RubyLLM.configure do |config|
        config.ollama_api_base = OLLAMA_BASE
        config.request_timeout = 30
        config.max_retries = 1
        config.retry_interval = 0.5
      end
      LOGGER.info("LlmConfig: RubyLLM configured for Ollama at #{OLLAMA_BASE}")
    end

    def verify_ollama!
      chat = RubyLLM.chat(model: MODEL, provider: :ollama)
      response = chat.ask("Respond with only the word: ok")
      content = response.content.to_s.downcase

      if content.include?("ok")
        @available = true
        LOGGER.info("LlmConfig: Ollama verified with #{MODEL}")
      else
        @available = false
        LOGGER.warn("LlmConfig: Ollama responded unexpectedly, LLM features disabled")
      end
    rescue => e
      @available = false
      LOGGER.warn("LlmConfig: Ollama verification failed (#{e.class}: #{e.message}), LLM features disabled")
    end

    def configure_chaos!
      require "chaos_to_the_rescue"

      ChaosToTheRescue.configure do |config|
        config.enabled = true
        config.auto_define_methods = true
        config.model = MODEL
        config.allow_everything!
        config.log_level = :warn
      end

      LOGGER.info("LlmConfig: chaos_to_the_rescue enabled")
    rescue LoadError => e
      LOGGER.warn("LlmConfig: chaos_to_the_rescue not available (#{e.message})")
    rescue => e
      LOGGER.warn("LlmConfig: chaos_to_the_rescue setup failed (#{e.class}: #{e.message})")
    end
  end
end
