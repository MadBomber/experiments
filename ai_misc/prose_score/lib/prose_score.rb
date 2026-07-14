#!/usr/bin/env ruby
# frozen_string_literal: true

##########################################################
###
##  File: prose_score/lib/prose_score.rb
##  Desc: Deterministic prose-quality percentage scorer
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

require_relative 'prose_score/result'
require_relative 'prose_score/scoring_helpers'
require_relative 'prose_score/text_utils'
require_relative 'prose_score/dictionaries'
require_relative 'prose_score/spell_checker'

require_relative 'prose_score/analyzers/conventions_analyzer'
require_relative 'prose_score/analyzers/clarity_analyzer'
require_relative 'prose_score/analyzers/coherence_analyzer'
require_relative 'prose_score/analyzers/readability_analyzer'
require_relative 'prose_score/analyzers/llm_judge_analyzer'

require_relative 'prose_score/scorer'
require_relative 'prose_score/report_formatter'

module ProseScore
  # Primary entry point for programmatic use (e.g. a generate/critique/rewrite
  # loop): just the 0-100 percentage, nothing else.
  #
  #   score = ProseScore.score(draft)
  #   draft = rewrite(draft) while ProseScore.score(draft) < 75.0
  def self.score(text, use_llm: false) = Scorer.score(text, use_llm:)[:score]

  # Convenience predicate for a "does this need a rewrite?" loop condition.
  #
  #   draft = rewrite(draft) until ProseScore.acceptable?(draft, threshold: 75.0)
  def self.acceptable?(text, threshold: 70.0, use_llm: false) = score(text, use_llm:) >= threshold
end
