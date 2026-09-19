# frozen_string_literal: true

require_relative 'llm_support'

module BayesianInference
  # Elicits a Prior distribution from an LLM given a natural-language
  # description of the current situation.
  #
  # Classical Bayesian analysis stalls on the question "where does the
  # prior come from?" — an LLM is a compressed archive of domain
  # knowledge that can be queried for exactly that. The LLM never does
  # probability arithmetic; it only supplies relative weights, which are
  # floored, normalized, and validated by the existing Prior class.
  #
  # @example Elicit a market-trend prior from a news summary
  #   elicitor = LlmPriorElicitor.new(
  #     outcomes: [-2, -1, 0, 1, 2],
  #     outcome_descriptions: {
  #       -2 => 'strong downtrend', -1 => 'mild downtrend', 0 => 'sideways',
  #        1 => 'mild uptrend',      2 => 'strong uptrend'
  #     }
  #   )
  #   prior = elicitor.elicit('The Fed unexpectedly cut rates by 50bp...')
  #   predictor = TimeSeriesPredictor.new(
  #     outcomes: [-2, -1, 0, 1, 2],
  #     prior_probabilities: prior.probabilities,
  #     update_prior: false
  #   )
  class LlmPriorElicitor
    include LlmSupport

    attr_reader :outcomes, :outcome_descriptions, :model, :provider

    # @param outcomes [Array] discrete outcomes the prior ranges over
    # @param outcome_descriptions [Hash] optional {outcome => human label}
    #   used in the prompt so the LLM knows what each outcome means
    # @param chat [#ask, nil] injectable chat object (tests pass a fake);
    #   defaults to a RubyLLM chat built on first use
    # @param model [String, nil] model id; nil resolves per provider
    # @param provider [Symbol, nil] :lms, :apfel, :cloud; nil auto-detects
    def initialize(outcomes:, outcome_descriptions: {}, chat: nil, model: nil, provider: nil)
      @outcomes = outcomes.sort
      @outcome_descriptions = outcome_descriptions
      @model = model
      @provider = provider
      @chat = chat
    end

    # Ask the LLM for a prior over the outcomes given the context.
    #
    # @param context [String] natural-language description of the situation
    # @return [Prior] validated prior distribution
    def elicit(context)
      response = chat.ask(build_prompt(context))
      prior_from_response(response.content)
    end

    # Convert raw LLM response content into a Prior.
    # Public and pure so it can be tested without any network call.
    #
    # @param content [Hash, String] LLM response content
    # @return [Prior]
    def prior_from_response(content)
      raw = extract_json(content)
      weights = rekey_to_outcomes(raw, @outcomes)
      Prior.new(@outcomes, normalize_distribution(weights))
    end

    # Build the elicitation prompt.
    # Public and pure so prompt wording can be tested and iterated on.
    #
    # @param context [String]
    # @return [String]
    def build_prompt(context)
      <<~PROMPT
        You are a careful probabilistic forecaster. Based on the situation
        described below, assign a relative weight between 0 and 100 to each
        possible outcome, reflecting how probable each outcome is a priori.

        Situation:
        #{context}

        Possible outcomes:
        #{outcome_lines}

        Respond with ONLY a JSON object mapping each outcome to its weight,
        for example: {#{example_json_keys}}. No commentary.
      PROMPT
    end

    private

    def chat
      @chat ||= LlmSupport.build_chat(@model, provider: @provider)
    end

    def outcome_lines
      @outcomes.map do |outcome|
        label = @outcome_descriptions[outcome]
        label ? "- #{outcome}: #{label}" : "- #{outcome}"
      end.join("\n")
    end

    def example_json_keys
      @outcomes.map { |o| "\"#{o}\": 20" }.join(', ')
    end
  end
end
