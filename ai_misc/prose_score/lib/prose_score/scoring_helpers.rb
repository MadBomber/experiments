#!/usr/bin/env ruby
# frozen_string_literal: true

##########################################################
###
##  File: prose_score/lib/prose_score/scoring_helpers.rb
##  Desc: Shared "issue rate -> 0-100 score" conversion used by every check
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

module ProseScore
  module ScoringHelpers
    # rate: issues per unit (per sentence, per 100 words, etc.)
    # sensitivity: score lost per full unit of rate. A rate of 1.0 with the
    # default sensitivity (100.0) drives the score to zero; tune sensitivity
    # down for checks where occasional hits are normal (e.g. one filler
    # phrase per 100 words shouldn't zero the score).
    def self.score_from_rate(rate, sensitivity: 100.0)
      [100.0 - (rate * sensitivity), 0.0].max.round(1)
    end

    def self.rate_per(count, denominator) = denominator.zero? ? 0.0 : count.to_f / denominator

    # combine several {score:, weight:} sub-checks into one weighted score
    def self.weighted_average(components)
      total_weight = components.sum { it[:weight] }
      return 100.0 if total_weight.zero?

      components.sum { it[:score] * it[:weight] }.fdiv(total_weight).round(1)
    end
  end
end
