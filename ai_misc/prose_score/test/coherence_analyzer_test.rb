#!/usr/bin/env ruby
# frozen_string_literal: true

##########################################################
###
##  File: prose_score/test/coherence_analyzer_test.rb
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

require_relative 'test_helper'

class CoherenceAnalyzerTest < Minitest::Test
  def analyzer(text = 'placeholder') = ProseScore::Analyzers::CoherenceAnalyzer.new(text)

  # ---- underdeveloped_paragraph? / long_paragraph? ----

  def test_flags_two_sentence_paragraph_as_underdeveloped
    assert analyzer.underdeveloped_paragraph?('Cats are animals. Dogs are animals too.')
  end

  def test_does_not_flag_well_developed_paragraph
    text = 'Cats are animals. Dogs are animals. Birds are animals too. All of them need food and water.'
    refute analyzer.underdeveloped_paragraph?(text)
  end

  def test_flags_long_paragraph
    paragraph = (['This is a sentence.'] * 13).join(' ')
    assert analyzer.long_paragraph?(paragraph)
  end

  # ---- transition_opener? ----

  def test_flags_paragraph_with_no_transition
    refute analyzer.transition_opener?('Cats are great pets. They are independent.')
  end

  def test_detects_transition_opener
    assert analyzer.transition_opener?('However, dogs need more attention. They love company.')
  end

  # ---- bridged? ----

  def test_detects_lexical_bridge
    assert analyzer.bridged?('The dog ran across the yard.', 'The dog barked at a squirrel.')
  end

  def test_detects_no_bridge
    refute analyzer.bridged?('The dog ran across the yard.', 'Quantum physics is complicated.')
  end

  # ---- sentence_type ----

  def test_classifies_simple_sentence
    assert_equal :simple, analyzer.sentence_type('The dog ran home.')
  end

  def test_classifies_compound_sentence
    assert_equal :compound, analyzer.sentence_type('The dog ran home, and the cat followed.')
  end

  def test_classifies_complex_sentence
    assert_equal :complex, analyzer.sentence_type('Because it was raining, the dog ran home.')
  end

  def test_classifies_compound_complex_sentence
    assert_equal :compound_complex,
                 analyzer.sentence_type('Because it was raining, the dog ran home, and the cat followed.')
  end

  # ---- monotonous_sentence_types? ----

  def test_flags_monotonous_sentence_types
    text = (['The dog ran home.'] * 6).join(' ')
    assert analyzer(text).monotonous_sentence_types?
  end

  def test_does_not_flag_varied_sentence_types
    text = 'The dog ran home. Because it rained, the cat stayed in, and it slept all day. Since the sun set, the owls woke, but the dog kept sleeping.'
    refute analyzer(text).monotonous_sentence_types?
  end

  # ---- call / composite scoring ----

  def test_well_organized_text_scores_high
    text = <<~TEXT
      The dog ran across the yard. The dog barked at a squirrel that had climbed the old oak tree. The squirrel chattered back before disappearing into the branches.

      Meanwhile, the cat watched from the porch. The cat seemed unimpressed by the dog's excitement. It yawned and returned to napping in the sun.
    TEXT
    result = analyzer(text).call
    assert_operator result.score, :>=, 80.0
  end

  def test_disorganized_text_scores_lower_than_organized_text
    organized = <<~TEXT
      The dog ran across the yard. The dog barked at a squirrel that had climbed the old oak tree. The squirrel chattered back before disappearing into the branches.

      Meanwhile, the cat watched from the porch. The cat seemed unimpressed by the dog's excitement. It yawned and returned to napping in the sun.
    TEXT
    disorganized = <<~TEXT
      It rained.

      Cats are animals. Dogs are animals. Birds are animals. Fish are animals. Snakes are animals. Frogs are animals.
    TEXT
    organized_score = analyzer(organized).call.score
    disorganized_score = analyzer(disorganized).call.score
    assert_operator disorganized_score, :<, organized_score
  end

  def test_empty_text_scores_100_with_no_issues
    result = analyzer('').call
    assert_equal 100.0, result.score
    assert_empty result.issues
  end
end
