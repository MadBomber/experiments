# encoding: utf-8
# frozen_string_literal: true
##########################################################
###
##  File: lib/stats_recorder.rb
##  Desc: Subscribe to events from the EventBus
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

# Collect Events
class StatsRecorder
  @@events = []

  def an_event(payload)
    # ap payload
    @@events << payload
  end

  def self.dump
    ap @@events
  end
end # class StatsRecorder
