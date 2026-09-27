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
##
##        Also computes Gunning Fog, Coleman-Liau, and ARI as grade-level
##        cross-checks alongside Flesch-Kincaid, and MTLD as a length-bias-
##        resistant replacement for plain type-token ratio. The grade-level
##        formulas are diagnostic only (metrics, not scored) -- they're all
##        measuring the same underlying sentence/word-complexity construct
##        as Flesch, so weighting all four into the composite would just
##        amplify one signal rather than add information. MTLD *does*
##        replace TTR in the score, because it's a strict improvement on
##        the same role TTR was playing, not a redundant additional signal.
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

module ProseScore
  module Analyzers
    class ReadabilityAnalyzer
      READING_EASE_TARGET = (40.0..80.0)
      TTR_TARGET = (0.45..0.85)
      MTLD_TARGET = (40.0..90.0)
      MTLD_TTR_THRESHOLD = 0.72
      HEALTHY_SENTENCE_LENGTH_STDEV = 6.0
      TTR_WINDOW = 50
      INFLECTIONAL_SUFFIXES = %w[es ed ing].freeze

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

      # ---- other grade-level formulas (diagnostic cross-checks) ----

      def total_letters = words.sum(&:length)

      # a word ending in -es/-ed/-ing is excluded from the Gunning Fog
      # "complex word" count if its bare stem is under 3 syllables -- the
      # classic exception for words like "created" or "trespasses" that
      # only reach 3 syllables via a common inflection, not real complexity
      def inflected_from_simple_word?(word)
        INFLECTIONAL_SUFFIXES.any? do |suffix|
          next false unless word.end_with?(suffix)

          stem = word.delete_suffix(suffix)
          stem.length >= 2 && TextUtils.syllable_count(stem) < 3
        end
      end

      def complex_word?(word) = TextUtils.syllable_count(word) >= 3 && !inflected_from_simple_word?(word)

      def gunning_fog_index
        return 0.0 if sentences.empty? || words.empty?

        complex_word_ratio = words.count { complex_word?(it) }.fdiv(words.size)
        0.4 * (words_per_sentence + (100 * complex_word_ratio))
      end

      def coleman_liau_index
        return 0.0 if words.empty?

        letters_per_100_words = total_letters.fdiv(words.size) * 100
        sentences_per_100_words = sentences.size.fdiv(words.size) * 100
        (0.0588 * letters_per_100_words) - (0.296 * sentences_per_100_words) - 15.8
      end

      def automated_readability_index
        return 0.0 if sentences.empty? || words.empty?

        (4.71 * total_letters.fdiv(words.size)) + (0.5 * words_per_sentence) - 21.43
      end

      # average of the four grade-level formulas above -- a single formula's
      # quirks (Flesch/Fog lean on the syllable-count heuristic, Coleman-
      # Liau/ARI lean on raw letter counts instead) wash out in the average
      def grade_level_estimate
        return 0.0 if sentences.empty? || words.empty?

        [flesch_kincaid_grade_level, gunning_fog_index, coleman_liau_index, automated_readability_index].sum / 4.0
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

      # Measure of Textual Lexical Diversity: walks the word sequence,
      # accumulating a running TTR until it drops to MTLD_TTR_THRESHOLD,
      # counts that as one "factor," and resets. The score is total words
      # divided by the average factor count -- unlike plain TTR, it doesn't
      # keep falling as the text gets longer, so it needs no windowing.
      # Computed in both directions and averaged, per the standard algorithm,
      # since forward-only counting is sensitive to where the text happens
      # to start.
      def mtld
        return 0.0 if words.empty?

        average_factors = (mtld_factor_count(words) + mtld_factor_count(words.reverse)) / 2.0
        return words.size.to_f if average_factors.zero?

        words.size.fdiv(average_factors)
      end

      def call
        return AnalysisResult.new(score: 100.0, issues: [], metrics: {}) if sentences.empty? || words.empty?

        AnalysisResult.new(score: build_score, issues: build_issues, metrics: build_metrics)
      end

      private

      def mtld_factor_count(word_sequence, threshold: MTLD_TTR_THRESHOLD)
        factor_count = 0.0
        types = Set.new
        token_count = 0

        word_sequence.each do |word|
          types << word
          token_count += 1
          next unless types.size.fdiv(token_count) <= threshold

          factor_count += 1
          types = Set.new
          token_count = 0
        end

        if token_count.positive?
          remaining_ttr = types.size.fdiv(token_count)
          factor_count += (1.0 - remaining_ttr) / (1.0 - threshold)
        end

        factor_count
      end

      def distance_from_band(value, band) = value < band.begin ? band.begin - value : [value - band.end, 0.0].max

      def readability_component_score
        distance = distance_from_band(flesch_reading_ease, READING_EASE_TARGET)
        [100.0 - (distance * 1.2), 0.0].max.round(1)
      end

      def vocabulary_component_score
        distance = distance_from_band(mtld, MTLD_TARGET)
        [100.0 - (distance * 1.5), 0.0].max.round(1)
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

        diversity = mtld
        unless MTLD_TARGET.cover?(diversity)
          direction = diversity < MTLD_TARGET.begin ? 'repetitive word choice' : 'unusually wide vocabulary for the length'
          message = "MTLD lexical diversity #{diversity.round(1)} is outside the target band (#{direction})"
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
          gunning_fog_index: gunning_fog_index.round(1),
          coleman_liau_index: coleman_liau_index.round(1),
          automated_readability_index: automated_readability_index.round(1),
          grade_level_estimate: grade_level_estimate.round(1),
          mean_sentence_length: mean_sentence_length.round(1),
          sentence_length_stdev: sentence_length_stdev.round(1),
          vocabulary_richness: vocabulary_richness.round(3),
          mtld: mtld.round(1)
        }
      end
    end
  end
end
