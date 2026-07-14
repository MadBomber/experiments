#!/usr/bin/env ruby
# frozen_string_literal: true

##########################################################
###
##  File: prose_score/test/clarity_analyzer_test.rb
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

require_relative 'test_helper'

class ClarityAnalyzerTest < Minitest::Test
  def analyzer(text = 'placeholder') = ProseScore::Analyzers::ClarityAnalyzer.new(text)

  # ---- passive_voice? ----

  def test_flags_passive_with_regular_participle
    assert analyzer.passive_voice?('A decision was reached to postpone the vote.')
  end

  def test_flags_passive_with_irregular_participle
    assert analyzer.passive_voice?('The book was written by a famous author.')
  end

  def test_does_not_flag_active_voice
    refute analyzer.passive_voice?('The committee decided to postpone the vote.')
  end

  # ---- nominalization? ----

  def test_flags_nominalization
    assert analyzer.nominalization?('implementation')
  end

  def test_does_not_flag_short_word_with_matching_suffix
    refute analyzer.nominalization?('lion') # too short to trip the length guard
  end

  def test_does_not_flag_non_nominalized_word
    refute analyzer.nominalization?('dog')
  end

  # ---- noun_string? ----

  def test_flags_noun_string
    assert analyzer.noun_string?('This report explains our investment growth stimulation projects.')
  end

  def test_does_not_flag_normal_sentence
    refute analyzer.noun_string?('This report explains our projects to stimulate growth in investments.')
  end

  # ---- multiple_negatives? ----

  def test_flags_multiple_negatives
    assert analyzer.multiple_negatives?("I don't have no time for this.")
  end

  def test_does_not_flag_single_negative
    refute analyzer.multiple_negatives?('This is not clear.')
  end

  # ---- cliches_in / fillers_in / vague_quantifiers_in / generic_words_in ----

  def test_detects_cliche
    assert_includes analyzer.cliches_in('At the end of the day, we tried our best.'), 'at the end of the day'
  end

  def test_detects_filler_phrase
    assert_includes analyzer.fillers_in('In order to succeed, we must plan.'), 'in order to'
  end

  def test_detects_vague_quantifier
    assert_includes analyzer.vague_quantifiers_in('A lot of people showed up.'), 'a lot of'
  end

  def test_detects_generic_word
    assert_includes analyzer.generic_words_in('We did a lot of things.'), 'did'
  end

  # ---- repeated_openers ----

  def test_counts_repeated_sentence_openers
    text = 'The dog ran. The cat sat. The bird flew.'
    assert_equal 1, analyzer(text).repeated_openers
  end

  def test_does_not_count_varied_openers
    text = 'The dog ran. She smiled. He waved.'
    assert_equal 0, analyzer(text).repeated_openers
  end

  # ---- call / composite scoring ----

  def test_clean_text_scores_100
    text = 'The dog barked at the mailman. She smiled and waved.'
    result = analyzer(text).call
    assert_equal 100.0, result.score
    assert_empty result.issues
  end

  def test_murky_text_scores_below_100
    text = 'A decision was reached to postpone the vote. It is important to note that we need a lot of things.'
    result = analyzer(text).call
    assert_operator result.score, :<, 100.0
    assert(result.issues.any? { it.category == 'passive_voice' })
  end

  def test_empty_text_scores_100_with_no_issues
    result = analyzer('').call
    assert_equal 100.0, result.score
    assert_empty result.issues
  end
end
