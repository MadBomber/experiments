#!/usr/bin/env ruby
# frozen_string_literal: true

##########################################################
###
##  File: prose_score/lib/prose_score/analyzers/conventions_analyzer.rb
##  Desc: Mechanics/Conventions checks (fragments, run-ons, capitalization,
##        repeated words, spacing, spelling) -- sourced from the Howard CC
##        "Writing Basics" chapter and the WikiHow evaluation rubric.
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

module ProseScore
  module Analyzers
    # NOTE: none of this is a real grammar parser. Every check below is a
    # deliberately conservative (precision over recall) heuristic, tuned
    # against the worked examples in the source material rather than a
    # general-purpose fragment/run-on detector. See prose_score/README for
    # the reasoning.
    class ConventionsAnalyzer
      include Dictionaries

      DEPENDENT_OPENERS = (Dictionaries::SUBORDINATING_CONJUNCTIONS + Dictionaries::PREPOSITIONS).freeze
      LONG_SENTENCE_WORD_THRESHOLD = 45

      ISSUE_SOURCES = [
        [:fragments, 'fragment', 'Possible sentence fragment'],
        [:comma_splices, 'comma_splice', 'Possible comma splice'],
        [:run_ons, 'run_on', 'Unusually long sentence (possible run-on)'],
        [:capitalization_errors, 'capitalization', 'Sentence does not start with a capital letter'],
        [:repeated_words, 'repeated_word', 'Repeated word'],
        [:spacing_errors, 'spacing', 'Spacing or punctuation-spacing error']
      ].freeze

      def self.analyze(text) = new(text).call

      def initialize(text, spell_checker: ProseScore::SpellChecker)
        @text = text
        @sentences = TextUtils.sentences(text)
        @spell_checker = spell_checker
      end

      attr_reader :sentences

      def fragment?(sentence)
        words = TextUtils.words(sentence)
        return false if words.size < 2

        first = words.first
        opens_dependent = DEPENDENT_OPENERS.include?(first) || (first == 'to' && words.size > 1)
        opens_gerund    = first.end_with?('ing')
        return false unless opens_dependent || opens_gerund

        has_finite_verb_marker = words.any? { BE_VERBS.include?(it) || MODAL_VERBS.include?(it) }
        no_comma_continuation  = !sentence.include?(',')

        no_comma_continuation && !has_finite_verb_marker && words.size <= 14
      end

      def comma_splice?(sentence)
        return false unless sentence.include?(',')

        segments = sentence.split(',').map(&:strip)
        segments.each_cons(2).any? do |_left, right|
          right_words = TextUtils.words(right)
          next false if right_words.empty?
          next false if COORDINATING_CONJUNCTIONS.include?(right_words.first)
          next false if SUBORDINATING_CONJUNCTIONS.include?(right_words.first)
          next false if RELATIVE_PRONOUNS.include?(right_words.first)

          # not preceded by a conjunction/relative-pronoun and a be-verb/modal
          # shows up almost immediately -> looks like an independent clause
          # spliced on with nothing but a comma
          right_words.first(4).any? { BE_VERBS.include?(it) || MODAL_VERBS.include?(it) }
        end
      end

      def excessively_long?(sentence, threshold: LONG_SENTENCE_WORD_THRESHOLD) = TextUtils.word_count(sentence) > threshold

      def capitalization_error?(sentence)
        first_letter = sentence.lstrip[/[A-Za-z]/]
        !first_letter.nil? && first_letter != first_letter.upcase
      end

      def repeated_word?(sentence) = TextUtils.words(sentence).each_cons(2).any? { |a, b| a == b }

      def spacing_error?(sentence)
        sentence.match?(/  +/) ||
          sentence.match?(/[a-zA-Z] [,.;:!?]/) ||
          sentence.match?(/[a-zA-Z][,.;][A-Za-z]/)
      end

      def misspelled_words = @misspelled_words ||= @spell_checker.misspelled(@text)

      def fragments             = sentences.select { fragment?(it) }
      def comma_splices         = sentences.select { comma_splice?(it) }
      def run_ons               = sentences.select { excessively_long?(it) }
      def capitalization_errors = sentences.select { capitalization_error?(it) }
      def repeated_words        = sentences.select { repeated_word?(it) }
      def spacing_errors        = sentences.select { spacing_error?(it) }

      def call
        return AnalysisResult.new(score: 100.0, issues: [], metrics: { sentence_count: 0 }) if sentences.empty?

        issues = build_issues
        score  = build_score

        AnalysisResult.new(
          score:,
          issues:,
          metrics: { sentence_count: sentences.size, word_count: TextUtils.word_count(@text) }
        )
      end

      private

      def build_issues
        issues = ISSUE_SOURCES.flat_map { |method_name, category, message| send(method_name).map { Issue.new(category:, message:, excerpt: it) } }
        issues.concat(misspelled_words.map { |w| Issue.new(category: 'spelling', message: "Possibly misspelled word: #{w}", excerpt: w) })
        issues
      end

      def rate_score(count, denominator, sensitivity:) = ScoringHelpers.score_from_rate(ScoringHelpers.rate_per(count, denominator), sensitivity:)

      def build_score
        n = sentences.size
        word_count = TextUtils.word_count(@text)

        components = [
          { score: rate_score(fragments.size, n, sensitivity: 150), weight: 3 },
          { score: rate_score(comma_splices.size, n, sensitivity: 150), weight: 2 },
          { score: rate_score(run_ons.size, n, sensitivity: 200), weight: 1 },
          { score: rate_score(capitalization_errors.size, n, sensitivity: 150), weight: 2 },
          { score: rate_score(repeated_words.size, n, sensitivity: 150), weight: 1 },
          { score: rate_score(spacing_errors.size, n, sensitivity: 150), weight: 1 },
          { score: rate_score(misspelled_words.size, word_count, sensitivity: 300), weight: 3 }
        ]
        ScoringHelpers.weighted_average(components)
      end
    end
  end
end
