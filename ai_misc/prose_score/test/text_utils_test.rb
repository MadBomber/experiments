#!/usr/bin/env ruby
# frozen_string_literal: true

##########################################################
###
##  File: prose_score/test/text_utils_test.rb
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

require_relative 'test_helper'

class TextUtilsTest < Minitest::Test
  def test_splits_simple_sentences
    text = 'The dog ran. The cat slept.'
    assert_equal ['The dog ran.', 'The cat slept.'], ProseScore::TextUtils.sentences(text)
  end

  def test_does_not_split_on_abbreviations
    text = 'Dr. Smith walked home. Mrs. Jones followed.'
    assert_equal ['Dr. Smith walked home.', 'Mrs. Jones followed.'], ProseScore::TextUtils.sentences(text)
  end

  def test_splits_before_quoted_dialogue
    text = 'He paused. "Is that so?" she asked.'
    assert_equal ['He paused.', '"Is that so?" she asked.'], ProseScore::TextUtils.sentences(text)
  end

  def test_returns_empty_array_for_blank_text
    assert_empty ProseScore::TextUtils.sentences('')
    assert_empty ProseScore::TextUtils.sentences(nil)
  end

  def test_splits_paragraphs_on_blank_lines
    text = "First paragraph.\n\nSecond paragraph.\n\n\nThird paragraph."
    assert_equal ['First paragraph.', 'Second paragraph.', 'Third paragraph.'], ProseScore::TextUtils.paragraphs(text)
  end

  def test_words_lowercases_and_strips_punctuation
    assert_equal %w[the dog ran], ProseScore::TextUtils.words('The dog ran!')
  end

  def test_words_keeps_internal_apostrophes
    assert_includes ProseScore::TextUtils.words("Don't stop."), "don't"
  end

  def test_word_count
    assert_equal 3, ProseScore::TextUtils.word_count('The dog ran.')
  end

  def test_syllable_count_single_syllable
    assert_equal 1, ProseScore::TextUtils.syllable_count('time')
  end

  def test_syllable_count_multi_syllable
    assert_equal 3, ProseScore::TextUtils.syllable_count('beautiful')
  end

  def test_syllable_count_empty_word
    assert_equal 0, ProseScore::TextUtils.syllable_count('')
  end

  def test_first_word
    assert_equal 'the', ProseScore::TextUtils.first_word('The dog ran.')
  end
end
