# frozen_string_literal: true

require_relative 'test_helper'

class LlmPriorElicitorTest < Minitest::Test
  include BayesianInference

  OUTCOMES = [-2, -1, 0, 1, 2].freeze

  def elicitor_with(content, descriptions: {})
    LlmPriorElicitor.new(
      outcomes: OUTCOMES,
      outcome_descriptions: descriptions,
      chat: FakeChat.new(content)
    )
  end

  def test_elicit_returns_valid_prior_from_json_string
    elicitor = elicitor_with('{"-2": 5, "-1": 10, "0": 20, "1": 40, "2": 25}')
    prior = elicitor.elicit('bullish news')

    assert_instance_of Prior, prior
    assert_in_delta 1.0, prior.probabilities.values.sum, 1e-6
    assert_equal 1, prior.probabilities.max_by { |_, p| p }.first
  end

  def test_elicit_handles_fenced_json_with_commentary
    content = "Sure!\n```json\n{\"-2\": 0, \"-1\": 0, \"0\": 50, \"1\": 30, \"2\": 20}\n```"
    prior = elicitor_with(content).elicit('mixed news')

    assert_in_delta 1.0, prior.probabilities.values.sum, 1e-6
    assert prior.probability(-2).positive?, 'floored, never exactly zero'
  end

  def test_elicit_handles_hash_content_from_structured_output
    prior = elicitor_with({ '-2' => 10, '-1' => 20, '0' => 40, '1' => 20, '2' => 10 }).elicit('quiet market')
    assert_equal 0, prior.probabilities.max_by { |_, p| p }.first
  end

  def test_prompt_includes_context_and_outcome_descriptions
    elicitor = elicitor_with('{"-2":1,"-1":1,"0":1,"1":1,"2":1}',
                             descriptions: { 2 => 'strong uptrend' })
    elicitor.elicit('Fed cut rates')

    prompt = elicitor.instance_variable_get(:@chat).last_prompt
    assert_includes prompt, 'Fed cut rates'
    assert_includes prompt, '2: strong uptrend'
  end

  def test_prior_from_response_is_pure_and_testable_without_chat
    elicitor = LlmPriorElicitor.new(outcomes: OUTCOMES, chat: :unused)
    prior = elicitor.prior_from_response('{"-2": 25, "-1": 25, "0": 25, "1": 25, "2": 0}')
    assert_in_delta 0.25, prior.probability(0), 1e-3
  end
end
