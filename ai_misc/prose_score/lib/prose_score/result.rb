#!/usr/bin/env ruby
# frozen_string_literal: true

##########################################################
###
##  File: prose_score/lib/prose_score/result.rb
##  Desc: Shared value objects returned by every analyzer
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

module ProseScore
  # One flagged issue found by an analyzer's check.
  Issue = Data.define(:category, :message, :excerpt)

  # One analyzer's output: a 0-100 sub-score plus the issues that produced it.
  AnalysisResult = Data.define(:score, :issues, :metrics) do
    def summary = "#{score.round(1)}% (#{issues.size} issue#{'s' unless issues.size == 1})"
  end
end
