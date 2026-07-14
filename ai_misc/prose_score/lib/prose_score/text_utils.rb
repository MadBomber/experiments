#!/usr/bin/env ruby
# frozen_string_literal: true

##########################################################
###
##  File: prose_score/lib/prose_score/text_utils.rb
##  Desc: Tokenization helpers shared by all prose_score analyzers
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

module ProseScore
  # Regex-based tokenization. There is no POS tagger in play here, so every
  # analyzer built on top of these methods is a heuristic, not a parser.
  module TextUtils
    ABBREVIATIONS = %w[Mr Mrs Ms Dr Prof Sr Jr St vs etc Gen Rep Sen Gov Ave Blvd Inc Ltd Co].freeze
    ABBREVIATION_PATTERN = /\b(#{ABBREVIATIONS.join('|')})\./
    ABBREVIATION_MARKER  = '@@ABBR_DOT@@'
    SENTENCE_SPLIT = /(?<=[.!?])\s+(?=[A-Z0-9"'])/

    def self.paragraphs(text) = text.to_s.split(/\n\s*\n+/).map(&:strip).reject(&:empty?)

    def self.sentences(text)
      normalized = text.to_s.gsub(/\s+/, ' ').strip
      return [] if normalized.empty?

      guarded = normalized.gsub(ABBREVIATION_PATTERN) { "#{::Regexp.last_match(1)}#{ABBREVIATION_MARKER}" }
      guarded
        .split(SENTENCE_SPLIT)
        .map { it.gsub(ABBREVIATION_MARKER, '.').strip }
        .reject(&:empty?)
    end

    def self.words(text) = text.to_s.downcase.scan(/[a-z']+/).map { it.gsub(/\A'+|'+\z/, '') }.reject(&:empty?)

    def self.word_count(text) = words(text).size

    # Classic vowel-group approximation. Not phonetically exact, but stable
    # and dependency-free, which is what a deterministic score requires.
    def self.syllable_count(word)
      w = word.to_s.downcase.gsub(/[^a-z]/, '')
      return 0 if w.empty?

      w = w.sub(/e\z/, '') if w.end_with?('e') && !w.end_with?('le') && w.length > 3
      groups = w.scan(/[aeiouy]+/)
      [groups.size, 1].max
    end

    # first token of a sentence, useful for opener-repetition and
    # subordinating/coordinating-conjunction checks
    def self.first_word(sentence) = words(sentence).first
  end
end
