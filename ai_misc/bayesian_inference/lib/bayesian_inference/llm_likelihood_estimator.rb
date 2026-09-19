# frozen_string_literal: true

require_relative 'llm_support'

module BayesianInference
  # Uses an LLM as a likelihood function over soft, semantic evidence.
  #
  # Kernel density estimation (the Likelihood class) needs numeric
  # feature vectors and historical data. But much real-world evidence is
  # text: a log line, a witness statement, a news headline. An LLM can
  # judge P(evidence | hypothesis) for that kind of evidence — and then
  # this library does what LLMs are demonstrably bad at: combining those
  # judgments coherently via Bayes' theorem, one update per piece of
  # evidence, with no double-counting and no anchoring drift.
  #
  # @example Root-cause diagnosis from log evidence
  #   estimator = LlmLikelihoodEstimator.new(
  #     hypotheses: {
  #       bad_deploy: 'The 14:02 deploy introduced a bug',
  #       database:   'The primary database is degraded',
  #       network:    'There is a network partition between AZs'
  #     }
  #   )
  #   lh = estimator.likelihoods('Error rate spiked 2 minutes after deploy')
  #   # => { bad_deploy: 0.9, database: 0.2, network: 0.15 }
  class LlmLikelihoodEstimator
    include LlmSupport

    attr_reader :hypotheses, :model, :provider

    # @param hypotheses [Hash] {id => description}; ids become the
    #   outcome keys used with Prior/Posterior
    # @param chat [#ask, nil] injectable chat object (tests pass a fake)
    # @param model [String, nil] model id; nil resolves per provider
    # @param provider [Symbol, nil] :lms, :apfel, :cloud; nil auto-detects
    def initialize(hypotheses:, chat: nil, model: nil, provider: nil)
      @hypotheses = hypotheses
      @model = model
      @provider = provider
      @chat = chat
    end

    # Estimate P(evidence | hypothesis) for every hypothesis.
    #
    # Likelihoods are NOT probabilities of the hypotheses and need not
    # sum to 1 — each answers "if this hypothesis were true, how
    # surprising would this evidence be?" independently.
    #
    # @param evidence [String] one piece of evidence in natural language
    # @return [Hash] {hypothesis_id => Float in (0, 1)}
    def likelihoods(evidence)
      response = chat.ask(build_prompt(evidence))
      likelihoods_from_response(response.content)
    end

    # Convert raw LLM response content into a clamped likelihood hash.
    # Public and pure so it can be tested without any network call.
    #
    # @param content [Hash, String] LLM response content
    # @return [Hash] {hypothesis_id => Float}
    def likelihoods_from_response(content)
      raw = extract_json(content)
      rekey_to_outcomes(raw, @hypotheses.keys)
        .transform_values { |v| clamp_likelihood(v) }
    end

    # Build the likelihood-estimation prompt.
    # Public and pure so prompt wording can be tested and iterated on.
    #
    # @param evidence [String]
    # @return [String]
    def build_prompt(evidence)
      <<~PROMPT
        You are a careful probabilistic reasoner. For EACH hypothesis below,
        estimate the conditional probability of observing the given evidence
        ASSUMING THAT HYPOTHESIS IS TRUE: P(evidence | hypothesis).

        These are independent judgments — they do NOT need to sum to 1.
        Use values between 0.01 and 0.99. Avoid 0 and 1; evidence is rarely
        impossible or certain.

        Evidence:
        #{evidence}

        Hypotheses:
        #{hypothesis_lines}

        Respond with ONLY a JSON object mapping each hypothesis id to its
        conditional probability, for example: {#{example_json_keys}}.
        No commentary.
      PROMPT
    end

    private

    def chat
      @chat ||= LlmSupport.build_chat(@model, provider: @provider)
    end

    def hypothesis_lines
      @hypotheses.map { |id, desc| "- #{id}: #{desc}" }.join("\n")
    end

    def example_json_keys
      @hypotheses.keys.map { |id| "\"#{id}\": 0.5" }.join(', ')
    end
  end
end
