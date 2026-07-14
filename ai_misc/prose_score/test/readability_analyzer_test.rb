#!/usr/bin/env ruby
# frozen_string_literal: true

##########################################################
###
##  File: prose_score/test/readability_analyzer_test.rb
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

require_relative 'test_helper'

class ReadabilityAnalyzerTest < Minitest::Test
  def analyzer(text = 'placeholder') = ProseScore::Analyzers::ReadabilityAnalyzer.new(text)

  def test_flesch_reading_ease_is_lower_for_denser_text
    plain = 'The dog ran home. It was tired.'
    dense = 'The instantiation of multifaceted epistemological frameworks necessitates comprehensive reconceptualization.'
    assert_operator analyzer(dense).flesch_reading_ease, :<, analyzer(plain).flesch_reading_ease
  end

  def test_flesch_kincaid_grade_level_is_higher_for_denser_text
    plain = 'The dog ran home. It was tired.'
    dense = 'The instantiation of multifaceted epistemological frameworks necessitates comprehensive reconceptualization.'
    assert_operator analyzer(dense).flesch_kincaid_grade_level, :>, analyzer(plain).flesch_kincaid_grade_level
  end

  def test_sentence_length_stdev_is_zero_for_uniform_sentences
    text = 'The dog ran. The cat sat. The bird flew.'
    assert_equal 0.0, analyzer(text).sentence_length_stdev
  end

  def test_sentence_length_stdev_is_positive_for_varied_sentences
    text = 'It rained. The old dog, tired from the long afternoon walk through the muddy fields, curled up by the fire.'
    assert_operator analyzer(text).sentence_length_stdev, :>, 0.0
  end

  def test_vocabulary_richness_is_low_for_repetitive_text
    text = 'The dog ran. The dog ran. The dog ran.'
    assert_operator analyzer(text).vocabulary_richness, :<, 0.5
  end

  def test_vocabulary_richness_is_high_for_varied_text
    text = 'The dog ran quickly across the sunlit meadow, chasing a fleeing rabbit toward the distant hedgerow.'
    assert_operator analyzer(text).vocabulary_richness, :>, 0.8
  end

  # ---- call / composite scoring ----

  def test_repetitive_text_scores_lower_than_varied_text
    varied = 'The sun set slowly behind the hills. A cool breeze drifted through the open window while the old clock ticked steadily into the night.'
    repetitive = 'The dog ran. The dog ran. The dog ran. The dog ran.'
    assert_operator analyzer(repetitive).call.score, :<, analyzer(varied).call.score
  end

  def test_empty_text_scores_100_with_no_issues
    result = analyzer('').call
    assert_equal 100.0, result.score
    assert_empty result.issues
  end
end
