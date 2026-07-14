#!/usr/bin/env ruby
# frozen_string_literal: true

##########################################################
###
##  File: prose_score/test/scorer_test.rb
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

require_relative 'test_helper'
require 'minitest/mock'

class ScorerTest < Minitest::Test
  SAMPLE_TEXT = <<~TEXT
    The dog ran across the yard. The dog barked at a squirrel that had climbed the old oak tree. The squirrel chattered back before disappearing into the branches.

    Meanwhile, the cat watched from the porch. The cat seemed unimpressed by the dogs excitement. It yawned and returned to napping in the sun.
  TEXT

  def test_deterministic_mode_averages_the_four_analyzers_equally
    report = ProseScore::Scorer.score(SAMPLE_TEXT)
    scores = report[:analyzers].values_at(:conventions, :clarity, :coherence, :readability).map { |a| a[:score] }
    expected = (scores.sum / 4.0).round(1)

    assert_equal 'deterministic', report[:mode]
    assert_equal expected, report[:score]
  end

  def test_deterministic_mode_has_no_llm_judge_entry
    report = ProseScore::Scorer.score(SAMPLE_TEXT)
    refute report[:analyzers].key?(:llm_judge)
  end

  def test_llm_enhanced_mode_blends_judge_scores_with_content_first_weighting
    stub_result = ProseScore::AnalysisResult.new(
      score: 90.0,
      issues: [],
      metrics: { ideas: 90.0, organization: 90.0, voice: 90.0, word_choice: 90.0, rationale: 'stub',
                 available: true }
    )

    report = nil
    ProseScore::Analyzers::LlmJudgeAnalyzer.stub(:analyze, stub_result) do
      report = ProseScore::Scorer.score(SAMPLE_TEXT, use_llm: true)
    end

    assert_equal 'llm_enhanced', report[:mode]
    assert report[:analyzers].key?(:llm_judge)
    # a uniformly-high LLM judge score should pull the overall score up relative
    # to the deterministic-only report for the same text
    deterministic_score = ProseScore::Scorer.score(SAMPLE_TEXT)[:score]
    assert_operator report[:score], :>, deterministic_score if deterministic_score < 90.0
  end

  def test_llm_enhanced_mode_falls_back_to_deterministic_when_judge_unavailable
    stub_result = ProseScore::AnalysisResult.new(
      score: 0.0,
      issues: [ProseScore::Issue.new(category: 'llm_judge_unavailable', message: 'no credentials',
                                     excerpt: '')],
      metrics: { available: false }
    )

    report = nil
    ProseScore::Analyzers::LlmJudgeAnalyzer.stub(:analyze, stub_result) do
      report = ProseScore::Scorer.score(SAMPLE_TEXT, use_llm: true)
    end

    assert_equal 'deterministic_fallback', report[:mode]
    refute report[:analyzers].key?(:llm_judge)
  end
end
