#!/usr/bin/env ruby
# frozen_string_literal: true

##########################################################
###
##  File: prose_score/test/prose_score_test.rb
##  Desc: The single-number, loop-friendly entry point
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

require_relative 'test_helper'

class ProseScoreModuleTest < Minitest::Test
  GOOD_TEXT = 'The dog barked at the mailman. She smiled and waved.'

  def test_score_returns_a_plain_float
    result = ProseScore.score(GOOD_TEXT)

    assert_instance_of Float, result
    assert_equal ProseScore::Scorer.score(GOOD_TEXT)[:score], result
  end

  def test_acceptable_is_true_when_score_meets_threshold
    assert ProseScore.acceptable?(GOOD_TEXT, threshold: 0.0)
  end

  def test_acceptable_is_false_when_score_is_below_threshold
    refute ProseScore.acceptable?(GOOD_TEXT, threshold: 101.0)
  end

  def test_acceptable_defaults_to_a_70_threshold
    score = ProseScore.score(GOOD_TEXT)
    assert_equal score >= 70.0, ProseScore.acceptable?(GOOD_TEXT)
  end
end
