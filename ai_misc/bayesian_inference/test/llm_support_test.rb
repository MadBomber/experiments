# frozen_string_literal: true

require_relative 'test_helper'

class LlmSupportTest < Minitest::Test
  include BayesianInference

  def test_extract_json_passes_hash_through
    hash = { 'a' => 1 }
    assert_equal hash, LlmSupport.extract_json(hash)
  end

  def test_extract_json_parses_raw_json_string
    assert_equal({ '0' => 40, '1' => 60 }, LlmSupport.extract_json('{"0": 40, "1": 60}'))
  end

  def test_extract_json_finds_object_inside_prose_and_fences
    content = "Here you go:\n```json\n{\"x\": 0.5}\n```\nHope that helps!"
    assert_equal({ 'x' => 0.5 }, LlmSupport.extract_json(content))
  end

  def test_extract_json_raises_on_missing_object
    assert_raises(BayesianInference::Error) { LlmSupport.extract_json('no json here') }
  end

  def test_extract_json_raises_on_malformed_json
    assert_raises(BayesianInference::Error) { LlmSupport.extract_json('{"a": }') }
  end

  def test_rekey_to_outcomes_matches_on_string_form
    raw = { '-1' => 10, '0' => 20, '1' => 70 }
    result = LlmSupport.rekey_to_outcomes(raw, [-1, 0, 1])
    assert_equal({ -1 => 10.0, 0 => 20.0, 1 => 70.0 }, result)
  end

  def test_rekey_to_outcomes_defaults_missing_keys_to_zero
    result = LlmSupport.rekey_to_outcomes({ 'a' => 5 }, %i[a b])
    assert_equal({ a: 5.0, b: 0.0 }, result)
  end

  def test_normalize_distribution_sums_to_one
    result = LlmSupport.normalize_distribution({ a: 30, b: 60, c: 10 })
    assert_in_delta 1.0, result.values.sum, 1e-9
    assert_in_delta 0.6, result[:b], 1e-3
  end

  def test_normalize_distribution_never_yields_exact_zero
    result = LlmSupport.normalize_distribution({ a: 100, b: 0 })
    assert result[:b].positive?, 'zero weight must be floored (Cromwell\'s rule)'
  end

  def test_normalize_distribution_floors_negative_weights
    result = LlmSupport.normalize_distribution({ a: -5, b: 5 })
    assert result[:a].positive?
    assert result[:a] < result[:b]
  end

  def test_choose_local_model_prefers_qwen_then_gpt_oss
    ids = ['bible-expert-24b', 'openai/gpt-oss-20b', 'qwen/qwen3.6-35b-a3b']
    assert_equal 'qwen/qwen3.6-35b-a3b', LlmSupport.choose_local_model(ids)
    assert_equal 'openai/gpt-oss-20b',
                 LlmSupport.choose_local_model(['bible-expert-24b', 'openai/gpt-oss-20b'])
  end

  def test_choose_local_model_never_picks_embedding_or_ocr_models
    ids = ['text-embedding-nomic-embed-text-v1.5', 'unlimited-ocr', 'kimi-k2.7-code']
    assert_equal 'kimi-k2.7-code', LlmSupport.choose_local_model(ids)
    assert_nil LlmSupport.choose_local_model(['text-embedding-nomic-embed-text-v1.5'])
  end

  def test_env_model_returns_nil_for_blank
    original = ENV['BI_LLM_MODEL']
    ENV['BI_LLM_MODEL'] = '  '
    assert_nil LlmSupport.env_model
    ENV['BI_LLM_MODEL'] = 'qwen/qwen3.6-35b-a3b'
    assert_equal 'qwen/qwen3.6-35b-a3b', LlmSupport.env_model
  ensure
    original.nil? ? ENV.delete('BI_LLM_MODEL') : ENV['BI_LLM_MODEL'] = original
  end

  def test_clamp_likelihood_bounds_extremes
    assert_equal 0.001, LlmSupport.clamp_likelihood(0.0)
    assert_equal 0.999, LlmSupport.clamp_likelihood(1.0)
    assert_in_delta 0.42, LlmSupport.clamp_likelihood(0.42), 1e-9
  end
end
