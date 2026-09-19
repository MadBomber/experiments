# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'

module BayesianInference
  # Shared plumbing for classes that get numbers out of an LLM.
  #
  # LLMs return prose; Bayes' theorem needs clean numeric hashes. Every
  # method here is a module_function so it can be tested in isolation
  # without instantiating anything.
  #
  # Provider strategy — local first:
  #   1. BI_LLM_PROVIDER env var (lms | apfel | cloud) if set
  #   2. LM Studio via ruby_llm-providers-lms   (http://localhost:1234/v1)
  #   3. Apfel (Apple Foundation Models) via ruby_llm-providers-apfel
  #      (http://127.0.0.1:11434/v1)
  #   4. cloud fallback through the plain ruby_llm registry
  # BI_LLM_MODEL overrides the model in every case.
  module LlmSupport
    module_function

    LMS_DEFAULT_BASE   = 'http://localhost:1234/v1'
    APFEL_DEFAULT_BASE = 'http://127.0.0.1:11434/v1'
    CLOUD_DEFAULT_MODEL = 'claude-haiku-4-5'

    def lms_api_base
      ENV.fetch('LMS_API_BASE', LMS_DEFAULT_BASE)
    end

    def apfel_api_base
      ENV.fetch('APFEL_API_BASE', APFEL_DEFAULT_BASE)
    end

    # Model override from the environment, nil when unset/blank.
    def env_model
      model = ENV['BI_LLM_MODEL']&.strip
      model.nil? || model.empty? ? nil : model
    end

    # Which provider to talk to: explicit env choice, else the first
    # local server that answers, else the cloud.
    #
    # @return [Symbol] :lms, :apfel, or :cloud
    def resolve_provider
      env = ENV['BI_LLM_PROVIDER']&.strip
      return env.to_sym unless env.nil? || env.empty?
      return :lms if server_alive?(lms_api_base)
      return :apfel if server_alive?(apfel_api_base)

      :cloud
    end

    # Quick liveness probe against an OpenAI-compatible /models endpoint.
    #
    # @param base [String] API base URL (".../v1")
    # @return [Boolean]
    def server_alive?(base, timeout: 1)
      uri = URI("#{base}/models")
      Net::HTTP.start(uri.host, uri.port, open_timeout: timeout, read_timeout: timeout) do |http|
        http.get(uri.path).code.start_with?('2')
      end
    rescue StandardError
      false
    end

    # Model ids served right now by a local OpenAI-compatible server.
    #
    # @param base [String] API base URL (".../v1")
    # @return [Array<String>]
    def list_local_models(base)
      uri = URI("#{base}/models")
      body = Net::HTTP.get(uri)
      JSON.parse(body).fetch('data', []).map { |m| m['id'] }
    rescue StandardError
      []
    end

    # Pick the best judgment model from a local server's offerings.
    # Qwen models honor JSON/structured prompts most reliably in LM
    # Studio (see ruby_llm-providers-lms README), then gpt-oss; embedding
    # and OCR models are never eligible.
    #
    # @param ids [Array<String>] model ids as listed by the server
    # @return [String, nil]
    def choose_local_model(ids)
      chat_ids = ids.reject { |id| id.match?(/embed|ocr/i) }
      chat_ids.find { |id| id.match?(/qwen/i) } ||
        chat_ids.find { |id| id.match?(/gpt-oss/i) } ||
        chat_ids.first
    end

    # Build a lazily-required RubyLLM chat so the core math library
    # never depends on ruby_llm being installed.
    #
    # @param model [String, nil] model id; nil resolves per provider
    # @param provider [Symbol, String, nil] :lms, :apfel, :cloud;
    #   nil auto-detects via resolve_provider
    # @return [RubyLLM::Chat]
    def build_chat(model = nil, provider: nil)
      require 'ruby_llm'
      configure_ruby_llm
      provider = (provider || resolve_provider).to_sym
      model ||= env_model

      case provider
      when :lms
        local_chat(:lms, model, lms_api_base)
      when :apfel
        local_chat(:apfel, model, apfel_api_base)
      else
        RubyLLM.chat(model: model || CLOUD_DEFAULT_MODEL)
      end
    end

    # @param provider [Symbol] :lms or :apfel
    # @param model [String, nil]
    # @param base [String] server API base, used to pick a model when none given
    # @return [RubyLLM::Chat]
    def local_chat(provider, model, base)
      model ||= choose_local_model(list_local_models(base))
      raise Error, "No chat model available from #{provider} server at #{base}" unless model

      RubyLLM.chat(model:, provider:, assume_model_exists: true)
    end

    # Register the local provider gems and point RubyLLM at whichever
    # cloud keys exist in the environment. Runs once; safe to call
    # repeatedly.
    def configure_ruby_llm
      return if @ruby_llm_configured

      require_local_providers

      RubyLLM.configure do |config|
        config.anthropic_api_key = ENV['ANTHROPIC_API_KEY'] if ENV['ANTHROPIC_API_KEY']
        config.openai_api_key    = ENV['OPENAI_API_KEY']    if ENV['OPENAI_API_KEY']
        config.gemini_api_key    = ENV['GEMINI_API_KEY']    if ENV['GEMINI_API_KEY']
        config.lms_api_base      = lms_api_base   if config.respond_to?(:lms_api_base=)
        config.apfel_api_base    = apfel_api_base if config.respond_to?(:apfel_api_base=)
      end
      @ruby_llm_configured = true
    end

    # The provider gems are optional: their absence only disables the
    # corresponding provider, it never breaks the cloud path.
    def require_local_providers
      %w[ruby_llm/providers/lms ruby_llm/providers/apfel].each do |path|
        require path
      rescue LoadError
        nil
      end
    end

    # Pull a Hash out of whatever the LLM returned.
    #
    # Accepts an already-parsed Hash (e.g., from structured output or a
    # test double), a raw JSON string, or prose containing a JSON object
    # (possibly inside a ```json fence).
    #
    # @param content [Hash, String, #to_s] LLM response content
    # @return [Hash] parsed JSON object with string keys
    # @raise [BayesianInference::Error] when no JSON object can be found
    def extract_json(content)
      return content if content.is_a?(Hash)

      text = content.to_s
      json = text[/\{.*\}/m]
      raise Error, "No JSON object found in LLM response: #{text.inspect}" unless json

      JSON.parse(json)
    rescue JSON::ParserError => e
      raise Error, "Malformed JSON from LLM: #{e.message}"
    end

    # Re-key an LLM-produced hash onto the caller's outcome objects.
    #
    # JSON keys are always strings; outcomes may be integers, symbols,
    # or strings. Matches on +to_s+ equality. Missing outcomes get 0.0.
    #
    # @param raw [Hash] {string_key => Numeric}
    # @param outcomes [Array] the caller's outcome objects
    # @return [Hash] {outcome => Float}
    def rekey_to_outcomes(raw, outcomes)
      by_string = raw.transform_keys(&:to_s)
      outcomes.each_with_object({}) do |outcome, hash|
        hash[outcome] = by_string.fetch(outcome.to_s, 0.0).to_f
      end
    end

    # Normalize weights into a proper probability distribution.
    #
    # Adds a small epsilon before normalizing so no outcome is ever
    # assigned exactly zero probability — a zero prior can never recover
    # no matter how much evidence arrives (Cromwell's rule).
    #
    # @param weights [Hash] {outcome => non-negative Numeric}
    # @param epsilon [Float] floor added to every weight
    # @return [Hash] {outcome => Float} summing to 1.0
    def normalize_distribution(weights, epsilon: 1e-6)
      floored = weights.transform_values { |w| [w.to_f, 0.0].max + epsilon }
      total = floored.values.sum
      floored.transform_values { |w| w / total }
    end

    # Clamp a likelihood into an open unit interval.
    #
    # Keeps LLM overconfidence (0.0 / 1.0 answers) from zeroing out or
    # saturating the posterior in a single update.
    #
    # @param value [Numeric]
    # @return [Float] value clamped to [floor, ceiling]
    def clamp_likelihood(value, floor: 0.001, ceiling: 0.999)
      value.to_f.clamp(floor, ceiling)
    end
  end
end
