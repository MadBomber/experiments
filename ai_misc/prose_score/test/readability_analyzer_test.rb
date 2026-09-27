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

  # ---- gunning_fog_index ----

  def test_gunning_fog_is_higher_for_denser_text
    plain = 'The dog ran home. It was tired.'
    dense = 'The instantiation of multifaceted epistemological frameworks necessitates comprehensive reconceptualization.'
    assert_operator analyzer(dense).gunning_fog_index, :>, analyzer(plain).gunning_fog_index
  end

  def test_gunning_fog_excludes_words_inflected_from_a_simple_stem
    # "created" is 3 syllables but its stem "creat(e)" is not real complexity,
    # just the standard -ed exception from the Gunning Fog rulebook
    refute analyzer.complex_word?('created')
  end

  def test_gunning_fog_counts_a_genuinely_complex_word
    assert analyzer.complex_word?('epistemological')
  end

  # ---- coleman_liau_index / automated_readability_index ----

  def test_coleman_liau_is_higher_for_denser_text
    plain = 'The dog ran home. It was tired.'
    dense = 'The instantiation of multifaceted epistemological frameworks necessitates comprehensive reconceptualization.'
    assert_operator analyzer(dense).coleman_liau_index, :>, analyzer(plain).coleman_liau_index
  end

  def test_automated_readability_index_is_higher_for_denser_text
    plain = 'The dog ran home. It was tired.'
    dense = 'The instantiation of multifaceted epistemological frameworks necessitates comprehensive reconceptualization.'
    assert_operator analyzer(dense).automated_readability_index, :>, analyzer(plain).automated_readability_index
  end

  # ---- grade_level_estimate ----

  def test_grade_level_estimate_is_the_average_of_the_four_formulas
    text = 'The old house stood at the end of the lane, its windows dark and its paint long faded.'
    a = analyzer(text)
    expected = [a.flesch_kincaid_grade_level, a.gunning_fog_index, a.coleman_liau_index, a.automated_readability_index].sum / 4.0
    assert_in_delta expected, a.grade_level_estimate, 0.01
  end

  # ---- mtld ----

  def test_mtld_is_low_for_repetitive_text
    text = 'The dog ran. The dog ran. The dog ran. The dog ran. The dog ran.'
    assert_operator analyzer(text).mtld, :<, 20.0
  end

  def test_mtld_is_higher_for_lexically_varied_text
    varied = 'The old house stood at the end of the lane, its windows dark and its paint long faded. ' \
             'Rain fell steadily against the roof, tapping a slow uneven rhythm. Somewhere inside, ' \
             'a candle flickered whenever wind found a gap in the frame.'
    repetitive = 'The dog ran. The dog ran. The dog ran. The dog ran. The dog ran. The dog ran. The dog ran.'
    assert_operator analyzer(varied).mtld, :>, analyzer(repetitive).mtld
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
