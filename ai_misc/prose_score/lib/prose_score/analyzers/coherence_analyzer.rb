#!/usr/bin/env ruby
# frozen_string_literal: true

##########################################################
###
##  File: prose_score/lib/prose_score/analyzers/coherence_analyzer.rb
##  Desc: Paragraph-level organization/coherence checks -- sourced from the
##        Purdue OWL paragraphing page (Unity, Coherence, Topic Sentence,
##        Adequate Development), the Lumen Learning transition taxonomy,
##        and the Fiveable sentence-variety guidance. No embeddings are
##        used here, so "coherence" is approximated with lexical overlap
##        rather than true semantic similarity -- see the conversation
##        notes on why that's a different implementation shape.
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

module ProseScore
  module Analyzers
    class CoherenceAnalyzer
      include Dictionaries

      UNDERDEVELOPED_SENTENCE_MAX = 2
      LONG_PARAGRAPH_SENTENCE_MAX = 12
      MONOTONY_SHARE_THRESHOLD = 0.85
      MONOTONY_MIN_SENTENCES = 5

      UNDERDEVELOPED_MESSAGE = "Paragraph of #{UNDERDEVELOPED_SENTENCE_MAX} sentences or fewer is likely underdeveloped".freeze
      LONG_PARAGRAPH_MESSAGE = "Paragraph exceeds #{LONG_PARAGRAPH_SENTENCE_MAX} sentences; consider a reader's-pause break".freeze
      MISSING_TRANSITION_MESSAGE = 'Paragraph opening has no transitional cue linking it to the previous one'

      def self.analyze(text) = new(text).call

      def initialize(text)
        @text = text
        @paragraphs = TextUtils.paragraphs(text)
        @sentences = TextUtils.sentences(text)
      end

      attr_reader :paragraphs, :sentences

      # ---- adequate development ----

      def underdeveloped_paragraph?(paragraph) = TextUtils.sentences(paragraph).size.between?(1, UNDERDEVELOPED_SENTENCE_MAX)
      def long_paragraph?(paragraph, threshold: LONG_PARAGRAPH_SENTENCE_MAX) = TextUtils.sentences(paragraph).size > threshold

      def underdeveloped_paragraphs = paragraphs.select { underdeveloped_paragraph?(it) }
      def long_paragraphs           = paragraphs.select { long_paragraph?(it) }

      # ---- transitions between paragraphs ----

      def transition_opener?(paragraph)
        first_sentence = TextUtils.sentences(paragraph).first
        return false unless first_sentence

        text = first_sentence.downcase
        ALL_TRANSITION_PHRASES.any? { text.start_with?(it) }
      end

      # the opening paragraph never needs a transition into what came before it
      def paragraphs_missing_transitions = paragraphs.drop(1).reject { transition_opener?(it) }

      # ---- verbal bridges: lexical overlap between consecutive sentences ----

      def content_words(sentence) = TextUtils.words(sentence).reject { STOPWORDS.include?(it) }

      def bridged?(sentence_a, sentence_b)
        a = content_words(sentence_a)
        b = content_words(sentence_b)
        return true if a.empty? || b.empty?

        !!a.intersect?(b)
      end

      def disconnected_sentence_pairs
        paragraphs.sum do |paragraph|
          TextUtils.sentences(paragraph).each_cons(2).count { |s1, s2| !bridged?(s1, s2) }
        end
      end

      def sentence_pair_count = paragraphs.sum { [TextUtils.sentences(it).size - 1, 0].max }

      # ---- sentence-type variety ----

      def sentence_type(sentence)
        has_compound_marker = sentence.match?(/,\s*(#{COORDINATING_CONJUNCTIONS.join('|')})\b/i) || sentence.include?(';')
        words = TextUtils.words(sentence)
        has_subordinate_marker = words.any? { |w| SUBORDINATING_CONJUNCTIONS.include?(w) || RELATIVE_PRONOUNS.include?(w) }

        if has_compound_marker && has_subordinate_marker
          :compound_complex
        elsif has_compound_marker
          :compound
        elsif has_subordinate_marker
          :complex
        else
          :simple
        end
      end

      def sentence_type_distribution = sentences.map { sentence_type(it) }.tally

      def monotonous_sentence_types?
        return false if sentences.size < MONOTONY_MIN_SENTENCES

        sentence_type_distribution.values.max.fdiv(sentences.size) >= MONOTONY_SHARE_THRESHOLD
      end

      def call
        return AnalysisResult.new(score: 100.0, issues: [], metrics: { paragraph_count: 0 }) if paragraphs.empty?

        AnalysisResult.new(score: build_score, issues: build_issues, metrics: build_metrics)
      end

      private

      def build_issues
        issues = underdeveloped_paragraphs.map { Issue.new(category: 'underdeveloped_paragraph', message: UNDERDEVELOPED_MESSAGE, excerpt: it[0, 60]) }
        issues.concat(long_paragraphs.map { Issue.new(category: 'long_paragraph', message: LONG_PARAGRAPH_MESSAGE, excerpt: it[0, 60]) })
        issues.concat(paragraphs_missing_transitions.map { Issue.new(category: 'missing_transition', message: MISSING_TRANSITION_MESSAGE, excerpt: it[0, 60]) })
        if disconnected_sentence_pairs.positive?
          message = "#{disconnected_sentence_pairs} sentence pair(s) share no repeated word/synonym/pronoun link"
          issues << Issue.new(category: 'weak_verbal_bridge', message:, excerpt: @text[0, 40])
        end
        if monotonous_sentence_types?
          dominant = sentence_type_distribution.max_by { it[1] }.first
          issues << Issue.new(category: 'monotonous_sentence_types', message: "Sentences are overwhelmingly #{dominant}; vary sentence structure", excerpt: @text[0, 40])
        end
        issues
      end

      def rate_score(count, denominator, sensitivity:) = ScoringHelpers.score_from_rate(ScoringHelpers.rate_per(count, denominator), sensitivity:)

      def build_score
        components = [
          { score: rate_score(underdeveloped_paragraphs.size, paragraphs.size, sensitivity: 100), weight: 2 },
          { score: rate_score(long_paragraphs.size, paragraphs.size, sensitivity: 150), weight: 1 },
          { score: rate_score(paragraphs_missing_transitions.size, [paragraphs.size - 1, 1].max, sensitivity: 80), weight: 2 },
          { score: rate_score(disconnected_sentence_pairs, [sentence_pair_count, 1].max, sensitivity: 120), weight: 2 },
          { score: monotonous_sentence_types? ? 60.0 : 100.0, weight: 1 }
        ]
        ScoringHelpers.weighted_average(components)
      end

      def build_metrics
        {
          paragraph_count: paragraphs.size,
          sentence_count: sentences.size,
          sentence_type_distribution:
        }
      end
    end
  end
end
