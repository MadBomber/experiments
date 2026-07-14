#!/usr/bin/env ruby
# frozen_string_literal: true

##########################################################
###
##  File: prose_score/lib/prose_score/analyzers/readability_analyzer.rb
##  Desc: Flesch readability, sentence-rhythm variety, and vocabulary
##        richness. Readability and vocabulary are scored against a target
##        band rather than "higher/lower is always better" -- the
##        Excellence in Literature rubric explicitly warns that vivid
##        vocabulary is "not necessarily exotic," and the same principle
##        applies to reading ease: simplest isn't automatically best prose.
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

module ProseScore
  module Analyzers
    class ReadabilityAnalyzer
      READING_EASE_TARGET = (40.0..80.0)
      TTR_TARGET = (0.45..0.85)
      HEALTHY_SENTENCE_LENGTH_STDEV = 6.0
      TTR_WINDOW = 50

      def self.analyze(text) = new(text).call

      def initialize(text)
        @text = text
        @sentences = TextUtils.sentences(text)
        @words = TextUtils.words(text)
      end

      attr_reader :sentences, :words

      # ---- Flesch metrics ----

      def total_syllables = words.sum { TextUtils.syllable_count(it) }

      def words_per_sentence = words.empty? || sentences.empty? ? 0.0 : words.size.fdiv(sentences.size)
      def syllables_per_word = words.empty? ? 0.0 : total_syllables.fdiv(words.size)

      def flesch_reading_ease
        return 100.0 if sentences.empty? || words.empty?

        206.835 - (1.015 * words_per_sentence) - (84.6 * syllables_per_word)
      end

      def flesch_kincaid_grade_level
        return 0.0 if sentences.empty? || words.empty?

        (0.39 * words_per_sentence) + (11.8 * syllables_per_word) - 15.59
      end

      # ---- sentence-length variety (rhythm) ----

      def sentence_lengths = sentences.map { TextUtils.word_count(it) }

      def mean_sentence_length = sentence_lengths.empty? ? 0.0 : sentence_lengths.sum.fdiv(sentence_lengths.size)

      def sentence_length_stdev
        return 0.0 if sentence_lengths.size < 2

        mean = mean_sentence_length
        variance = sentence_lengths.sum { (it - mean)**2 }.fdiv(sentence_lengths.size)
        Math.sqrt(variance)
      end

      # ---- vocabulary richness ----

      # chunked type-token ratio: avoids the well-known bias where TTR falls
      # simply because a text is longer, by averaging the ratio over fixed-
      # size word windows instead of computing it over the whole document
      def vocabulary_richness
        return 1.0 if words.empty?
        return words.uniq.size.fdiv(words.size) if words.size <= TTR_WINDOW

        ratios = words.each_slice(TTR_WINDOW).map { |chunk| chunk.uniq.size.fdiv(chunk.size) }
        ratios.sum.fdiv(ratios.size)
      end

      def call
        return AnalysisResult.new(score: 100.0, issues: [], metrics: {}) if sentences.empty? || words.empty?

        AnalysisResult.new(score: build_score, issues: build_issues, metrics: build_metrics)
      end

      private

      def distance_from_band(value, band) = value < band.begin ? band.begin - value : [value - band.end, 0.0].max

      def readability_component_score
        distance = distance_from_band(flesch_reading_ease, READING_EASE_TARGET)
        [100.0 - (distance * 1.2), 0.0].max.round(1)
      end

      def vocabulary_component_score
        distance = distance_from_band(vocabulary_richness, TTR_TARGET)
        [100.0 - (distance * 300.0), 0.0].max.round(1)
      end

      def sentence_variety_component_score
        [100.0 * (sentence_length_stdev / HEALTHY_SENTENCE_LENGTH_STDEV),
         100.0].min.round(1)
      end

      def build_issues
        issues = []

        fre = flesch_reading_ease
        unless READING_EASE_TARGET.cover?(fre)
          direction = fre < READING_EASE_TARGET.begin ? 'dense/complex' : 'simplistic'
          message = "Flesch reading ease #{fre.round(1)} is outside the target band (#{direction})"
          issues << Issue.new(category: 'readability_band', message:, excerpt: @text[0, 40])
        end

        ttr = vocabulary_richness
        unless TTR_TARGET.cover?(ttr)
          direction = ttr < TTR_TARGET.begin ? 'repetitive word choice' : "unusually high word variety for the length (verify it isn't just very short)"
          message = "Vocabulary richness #{ttr.round(2)} is outside the target band (#{direction})"
          issues << Issue.new(category: 'vocabulary_band', message:, excerpt: @text[0, 40])
        end

        if sentence_length_stdev < HEALTHY_SENTENCE_LENGTH_STDEV / 2.0
          message = "Sentence lengths vary little (stdev #{sentence_length_stdev.round(1)}); mix short and long sentences"
          issues << Issue.new(category: 'flat_rhythm', message:, excerpt: @text[0, 40])
        end

        issues
      end

      def build_score
        components = [
          { score: readability_component_score, weight: 2 },
          { score: vocabulary_component_score, weight: 2 },
          { score: sentence_variety_component_score, weight: 2 }
        ]
        ScoringHelpers.weighted_average(components)
      end

      def build_metrics
        {
          flesch_reading_ease: flesch_reading_ease.round(1),
          flesch_kincaid_grade_level: flesch_kincaid_grade_level.round(1),
          mean_sentence_length: mean_sentence_length.round(1),
          sentence_length_stdev: sentence_length_stdev.round(1),
          vocabulary_richness: vocabulary_richness.round(3)
        }
      end
    end
  end
end
