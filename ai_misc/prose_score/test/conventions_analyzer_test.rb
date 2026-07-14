#!/usr/bin/env ruby
# frozen_string_literal: true

##########################################################
###
##  File: prose_score/test/conventions_analyzer_test.rb
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

require_relative 'test_helper'

class ConventionsAnalyzerTest < Minitest::Test
  # spell_checker double so these tests never depend on `aspell` being
  # installed on the machine running the suite
  class StubSpellChecker
    def self.misspelled(_text) = []
  end

  def analyzer(text = 'placeholder')
    ProseScore::Analyzers::ConventionsAnalyzer.new(text,
                                                   spell_checker: StubSpellChecker)
  end

  # ---- fragment? ----

  def test_flags_dependent_clause_fragment
    assert analyzer.fragment?('Because we lost power.')
  end

  def test_flags_gerund_opening_fragment
    assert analyzer.fragment?('Taking deep breaths.')
  end

  def test_flags_infinitive_opening_fragment
    assert analyzer.fragment?('To reach the one thousand mark.')
  end

  def test_does_not_flag_dependent_clause_attached_with_comma
    refute analyzer.fragment?('Because we lost power, the entire family overslept.')
  end

  def test_does_not_flag_gerund_opener_attached_to_main_clause
    refute analyzer.fragment?('Taking deep breaths, Saul prepared for his presentation.')
  end

  def test_does_not_flag_ordinary_sentence
    refute analyzer.fragment?('The dog barked at the mailman.')
  end

  # ---- comma_splice? ----

  def test_flags_comma_splice
    assert analyzer.comma_splice?('We looked outside, the kids were hopping on the trampoline.')
  end

  def test_does_not_flag_comma_before_coordinating_conjunction
    refute analyzer.comma_splice?('We looked outside, and the kids were hopping on the trampoline.')
  end

  def test_does_not_flag_list_commas
    refute analyzer.comma_splice?('She bought apples, bananas, and pears.')
  end

  def test_does_not_flag_subordinate_clause_after_comma
    refute analyzer.comma_splice?('We stayed inside, because the storm was getting worse.')
  end

  def test_does_not_flag_appositive
    refute analyzer.comma_splice?('My brother, a doctor, came to visit.')
  end

  # ---- excessively_long? ----

  def test_flags_sentence_over_word_threshold
    long_sentence = "#{(['word'] * 46).join(' ')}."
    assert analyzer.excessively_long?(long_sentence)
  end

  def test_does_not_flag_normal_length_sentence
    refute analyzer.excessively_long?('This is a normal sentence.')
  end

  # ---- capitalization_error? ----

  def test_flags_lowercase_sentence_start
    assert analyzer.capitalization_error?('the dog ran home.')
  end

  def test_does_not_flag_uppercase_sentence_start
    refute analyzer.capitalization_error?('The dog ran home.')
  end

  def test_does_not_flag_quote_wrapped_sentence
    refute analyzer.capitalization_error?('"Is that so?" she asked.')
  end

  # ---- repeated_word? ----

  def test_flags_repeated_word
    assert analyzer.repeated_word?('I saw the the cat.')
  end

  def test_does_not_flag_distinct_words
    refute analyzer.repeated_word?('I saw the cat.')
  end

  # ---- spacing_error? ----

  def test_flags_double_space
    assert analyzer.spacing_error?('This has  a double space.')
  end

  def test_flags_space_before_punctuation
    assert analyzer.spacing_error?('This is odd , right?')
  end

  def test_does_not_flag_clean_spacing
    refute analyzer.spacing_error?('This sentence is spaced correctly, right?')
  end

  # ---- call / composite scoring ----

  def test_perfect_text_scores_100
    text = 'The dog ran home. She smiled and waved. "Welcome back," he said.'
    result = analyzer(text).call
    assert_equal 100.0, result.score
    assert_empty result.issues
  end

  def test_flawed_text_scores_below_100
    text = 'Because we lost power. the entire family overslept.'
    result = analyzer(text).call
    assert_operator result.score, :<, 100.0
    assert(result.issues.any? { it.category == 'fragment' })
  end

  def test_empty_text_scores_100_with_no_issues
    result = analyzer('').call
    assert_equal 100.0, result.score
    assert_empty result.issues
  end
end
