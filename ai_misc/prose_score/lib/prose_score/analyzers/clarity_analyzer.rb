#!/usr/bin/env ruby
# frozen_string_literal: true

##########################################################
###
##  File: prose_score/lib/prose_score/analyzers/clarity_analyzer.rb
##  Desc: Sentence-level clarity/conciseness checks -- sourced from the
##        Purdue OWL "Improving Sentence Clarity" page and the Fiveable
##        AP English Prose Style guide (filler phrases, vague quantifiers,
##        generic verbs, sentence-opener repetition).
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

module ProseScore
  module Analyzers
    class ClarityAnalyzer
      include Dictionaries

      ISSUE_SOURCES = [
        [:passive_sentences, 'passive_voice', 'Passive-voice construction'],
        [:noun_string_sentences, 'noun_string', 'String of nouns is hard to parse'],
        [:multi_negative_sentences, 'multiple_negatives', 'Multiple negatives']
      ].freeze

      def self.analyze(text) = new(text).call

      def initialize(text)
        @text = text
        @sentences = TextUtils.sentences(text)
      end

      attr_reader :sentences

      # ---- passive voice (be-verb + past participle) ----

      def past_participle?(word) = IRREGULAR_PAST_PARTICIPLES.include?(word) || (word.end_with?('ed') && word.length > 3)

      def passive_voice?(sentence)
        words = TextUtils.words(sentence)
        words.each_cons(2).any? { |a, b| BE_VERBS.include?(a) && past_participle?(b) }
      end

      # ---- be-verb overuse (document-level rate, not per-sentence) ----

      def be_verb_count = TextUtils.words(@text).count { BE_VERBS.include?(it) }

      # ---- nominalization overuse ----

      def nominalization?(word) = word.length > 5 && NOMINALIZATION_SUFFIXES.any? { word.end_with?(it) }

      def nominalizations_in(sentence) = TextUtils.words(sentence).select { nominalization?(it) }

      # ---- noun strings (runs of bare content words with no function word) ----

      def content_word?(word)
        return false if STOPWORDS.include?(word)
        return false if BE_VERBS.include?(word) || MODAL_VERBS.include?(word)
        return false if COORDINATING_CONJUNCTIONS.include?(word) || SUBORDINATING_CONJUNCTIONS.include?(word)
        return false if PREPOSITIONS.include?(word)
        return false if word.end_with?('ly')

        word.length >= 3
      end

      def noun_string?(sentence)
        run = 0
        TextUtils.words(sentence).each do |word|
          run = content_word?(word) ? run + 1 : 0
          return true if run >= 3
        end
        false
      end

      # ---- multiple negatives ----

      def negation_count(sentence)
        TextUtils.words(sentence).count { NEGATION_WORDS.include?(it) } + sentence.downcase.scan('n\'t').size
      end

      def multiple_negatives?(sentence) = negation_count(sentence) >= 2

      # ---- sentence-opener repetition (document-level) ----

      def repeated_openers
        openers = sentences.map { TextUtils.first_word(it) }
        openers.each_cons(3).count { |a, b, c| a && a == b && b == c }
      end

      # ---- lookup-table checks ----

      def cliches_in(sentence)
        text = sentence.downcase
        CLICHES.select { text.include?(it) }
      end

      def fillers_in(sentence)
        text = sentence.downcase
        FILLER_PHRASES.keys.select { text.include?(it) }
      end

      def vague_quantifiers_in(sentence)
        text = sentence.downcase
        VAGUE_QUANTIFIERS.select { |phrase| text.match?(/\b#{Regexp.escape(phrase)}\b/) }
      end

      def generic_words_in(sentence) = TextUtils.words(sentence) & (GENERIC_VERBS + VAGUE_NOUNS)

      def passive_sentences        = sentences.select { passive_voice?(it) }
      def noun_string_sentences    = sentences.select { noun_string?(it) }
      def multi_negative_sentences = sentences.select { multiple_negatives?(it) }
      def all_nominalizations      = sentences.flat_map { nominalizations_in(it) }
      def all_cliches              = sentences.flat_map { cliches_in(it) }
      def all_fillers              = sentences.flat_map { fillers_in(it) }
      def all_vague_quantifiers    = sentences.flat_map { vague_quantifiers_in(it) }
      def all_generic_words        = sentences.flat_map { generic_words_in(it) }

      def call
        return AnalysisResult.new(score: 100.0, issues: [], metrics: { sentence_count: 0 }) if sentences.empty?

        AnalysisResult.new(score: build_score, issues: build_issues, metrics: build_metrics)
      end

      private

      def build_issues
        issues = ISSUE_SOURCES.flat_map { |method_name, category, message| send(method_name).map { Issue.new(category:, message:, excerpt: it) } }
        issues.concat(all_nominalizations.map { |w| Issue.new(category: 'nominalization', message: "Nominalization: prefer the verb form of \"#{w}\"", excerpt: w) })
        issues.concat(all_cliches.map { |c| Issue.new(category: 'cliche', message: "Cliche: \"#{c}\"", excerpt: c) })
        issues.concat(all_fillers.map { |f| Issue.new(category: 'filler_phrase', message: "Wordy phrase: \"#{f}\" -> \"#{FILLER_PHRASES[f] || '(cut it)'}\"", excerpt: f) })
        issues.concat(all_vague_quantifiers.map { |v| Issue.new(category: 'vague_quantifier', message: "Vague quantifier: \"#{v}\"", excerpt: v) })
        issues.concat(all_generic_words.map { |g| Issue.new(category: 'generic_word', message: "Generic word: \"#{g}\"", excerpt: g) })
        issues << Issue.new(category: 'opener_repetition', message: '3+ consecutive sentences share the same opening word', excerpt: @text[0, 40]) if repeated_openers.positive?
        issues
      end

      def rate_score(count, denominator, sensitivity:) = ScoringHelpers.score_from_rate(ScoringHelpers.rate_per(count, denominator), sensitivity:)

      def build_score
        n = sentences.size
        word_count = TextUtils.word_count(@text)

        components = [
          { score: rate_score(passive_sentences.size, n, sensitivity: 80), weight: 3 },
          { score: rate_score(be_verb_count, word_count, sensitivity: 250), weight: 2 },
          { score: rate_score(all_nominalizations.size, word_count, sensitivity: 300), weight: 2 },
          { score: rate_score(noun_string_sentences.size, n, sensitivity: 150), weight: 1 },
          { score: rate_score(multi_negative_sentences.size, n, sensitivity: 150), weight: 1 },
          { score: rate_score(repeated_openers, n, sensitivity: 150), weight: 1 },
          { score: rate_score(all_cliches.size, word_count, sensitivity: 400), weight: 2 },
          { score: rate_score(all_fillers.size, word_count, sensitivity: 300), weight: 2 },
          { score: rate_score(all_vague_quantifiers.size, word_count, sensitivity: 150), weight: 1 },
          { score: rate_score(all_generic_words.size, word_count, sensitivity: 150), weight: 1 }
        ]
        ScoringHelpers.weighted_average(components)
      end

      def build_metrics
        {
          sentence_count: sentences.size,
          word_count: TextUtils.word_count(@text),
          passive_rate: ScoringHelpers.rate_per(passive_sentences.size, sentences.size).round(3),
          be_verb_rate: ScoringHelpers.rate_per(be_verb_count, TextUtils.word_count(@text)).round(3)
        }
      end
    end
  end
end
