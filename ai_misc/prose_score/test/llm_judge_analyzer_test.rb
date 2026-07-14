#!/usr/bin/env ruby
# frozen_string_literal: true

##########################################################
###
##  File: prose_score/test/llm_judge_analyzer_test.rb
##  Desc: These tests never make a live LLM call -- they only verify the
##        request-building and the graceful-failure path. See
##        prose_score/README for how to smoke-test the real call.
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

require_relative 'test_helper'

class LlmJudgeAnalyzerTest < Minitest::Test
  def test_returns_unavailable_result_when_ruby_llm_raises
    # point at a port nothing listens on so this fails fast and stays
    # independent of whether the machine running the suite has Ollama up
    analyzer = ProseScore::Analyzers::LlmJudgeAnalyzer.new('Some prose.', ollama_url: 'http://localhost:1')
    result = analyzer.call

    refute result.metrics[:available]
    assert_equal 0.0, result.score
    assert_equal 1, result.issues.size
    assert_equal 'llm_judge_unavailable', result.issues.first.category
  end

  def test_prompt_embeds_the_text_to_grade
    analyzer = ProseScore::Analyzers::LlmJudgeAnalyzer.new('The quick brown fox.')
    prompt = analyzer.send(:prompt)

    assert_includes prompt, 'The quick brown fox.'
    assert_includes prompt, 'IDEAS:'
    assert_includes prompt, 'ORGANIZATION:'
    assert_includes prompt, 'VOICE:'
    assert_includes prompt, 'WORD CHOICE:'
  end
end
