#!/usr/bin/env ruby
# frozen_string_literal: true

##########################################################
###
##  File: prose_score/lib/prose_score/scorer.rb
##  Desc: Combines every analyzer into one 0-100% prose-quality score.
##
##        Two modes:
##
##        deterministic (default) -- Conventions/Clarity/Coherence/
##        Readability weighted equally. Fully reproducible, no network
##        calls, no API keys. This is a Mechanics & Style score: it cannot
##        see whether the piece has anything worth saying.
##
##        llm_enhanced (use_llm: true) -- adds the Excellence in Literature
##        6+1 Traits weighting (content > style > mechanics): Ideas and
##        Organization from the LLM judge dominate, Conventions drops to a
##        minor share. Requires ruby_llm to be configured; falls back to
##        deterministic-only if the judge call fails.
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

module ProseScore
  class Scorer
    DETERMINISTIC_WEIGHTS = {
      conventions: 25,
      clarity: 25,
      coherence: 25,
      readability: 25
    }.freeze

    # content-first weighting per the Excellence in Literature triage:
    # "if the ideas are muddled ... all the style and perfect spelling in
    # the world doesn't really matter"
    LLM_ENHANCED_WEIGHTS = {
      ideas: 25,
      organization: 20,
      voice: 15,
      word_choice: 15,
      sentence_fluency: 15,
      conventions: 10
    }.freeze

    def self.score(text, use_llm: false, llm_options: {}) = new(text).score(use_llm:, llm_options:)

    def initialize(text)
      @text = text
    end

    def analyzer_results
      @analyzer_results ||= {
        conventions: Analyzers::ConventionsAnalyzer.analyze(@text),
        clarity: Analyzers::ClarityAnalyzer.analyze(@text),
        coherence: Analyzers::CoherenceAnalyzer.analyze(@text),
        readability: Analyzers::ReadabilityAnalyzer.analyze(@text)
      }
    end

    def score(use_llm: false, llm_options: {})
      results = analyzer_results
      return deterministic_report(results) unless use_llm

      llm_result = Analyzers::LlmJudgeAnalyzer.analyze(@text, **llm_options)
      llm_enhanced_report(results, llm_result)
    end

    private

    def deterministic_report(results)
      overall = ScoringHelpers.weighted_average(DETERMINISTIC_WEIGHTS.map do |key, weight|
        { score: results[key].score, weight: }
      end)
      build_report(mode: 'deterministic', overall:, results:)
    end

    def llm_enhanced_report(results, llm_result)
      return deterministic_report(results).merge(mode: 'deterministic_fallback') unless llm_result.metrics[:available]

      sentence_fluency = ScoringHelpers.weighted_average([
                                                           { score: results[:clarity].score, weight: 1 },
                                                           { score: results[:readability].score, weight: 1 }
                                                         ])
      organization = ScoringHelpers.weighted_average([
                                                       { score: llm_result.metrics[:organization], weight: 1 },
                                                       { score: results[:coherence].score, weight: 1 }
                                                     ])

      components = [
        { score: llm_result.metrics[:ideas], weight: LLM_ENHANCED_WEIGHTS[:ideas] },
        { score: organization, weight: LLM_ENHANCED_WEIGHTS[:organization] },
        { score: llm_result.metrics[:voice], weight: LLM_ENHANCED_WEIGHTS[:voice] },
        { score: llm_result.metrics[:word_choice], weight: LLM_ENHANCED_WEIGHTS[:word_choice] },
        { score: sentence_fluency, weight: LLM_ENHANCED_WEIGHTS[:sentence_fluency] },
        { score: results[:conventions].score, weight: LLM_ENHANCED_WEIGHTS[:conventions] }
      ]
      overall = ScoringHelpers.weighted_average(components)
      build_report(mode: 'llm_enhanced', overall:, results: results.merge(llm_judge: llm_result))
    end

    def build_report(mode:, overall:, results:)
      {
        score: overall,
        mode:,
        analyzers: results.transform_values { { score: it.score, issues: it.issues, metrics: it.metrics } }
      }
    end
  end
end
