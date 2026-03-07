#!/usr/bin/env ruby
# temporal_commitment.rb — Certainty and commitment in temporal expressions
#
# Natural language carries intent signals about how committed the speaker
# is to a temporal coordinate. This affects how the event should be
# represented, scheduled, and acted upon.
#
# "I'm planning a vacation in the spring" → tentative
# "I'm leaving the day after Christmas"   → committed
# "We might do Thanksgiving at mom's"     → proposed
# "The meeting was cancelled"             → cancelled
# "Rain check on Friday's lunch"          → deferred
#
# Status: SKETCH / EXPLORATION

require 'date'
require 'time'

module TemporalEvent

  #############################################
  ## Commitment Level
  ##
  ## How certain/committed is this temporal placement?
  ## This is metadata carried by the Event, not the coordinate.
  ## The same coordinate can be tentative or fixed depending on
  ## the speaker's intent.

  module Commitment
    FIXED       = :fixed        # "I leave on Dec 26" — it's happening
    TENTATIVE   = :tentative    # "planning to", "thinking about", "hoping to"
    PROPOSED    = :proposed     # "we could", "how about", "what if"
    CONDITIONAL = :conditional  # "if the weather holds", "assuming approval"
    DEFERRED    = :deferred     # "rain check", "postponed", "pushed back"
    CANCELLED   = :cancelled    # "cancelled", "called off", "not happening"
    RECURRING   = :recurring    # inherently committed by pattern, but individual
                                # occurrences can be overridden
  end

  # Intent signals — words/phrases that indicate commitment level.
  # A parser would use these to classify the expression.
  INTENT_SIGNALS = {
    Commitment::FIXED => [
      # Direct statements — no hedging
      /\b(will|going to|leaving|departing|arriving|starts?|begins?|ends?)\b/i,
      /\b(booked|confirmed|scheduled|reserved|set for)\b/i,
      /\b(have to|must|need to)\b/i,
    ],
    Commitment::TENTATIVE => [
      /\b(planning|plan to|thinking about|considering|hoping|looking at)\b/i,
      /\b(probably|likely|expect to|intend to|aiming for)\b/i,
      /\b(want to|would like to|trying to)\b/i,
      /\b(should be|ought to)\b/i,
    ],
    Commitment::PROPOSED => [
      /\b(could|might|maybe|perhaps|possibly)\b/i,
      /\b(how about|what about|what if|shall we)\b/i,
      /\b(suggesting|propose|let's consider)\b/i,
      /\b(option|alternative|idea)\b/i,
    ],
    Commitment::CONDITIONAL => [
      /\b(if|assuming|provided|unless|depending|contingent)\b/i,
      /\b(weather permitting|budget allows|pending approval)\b/i,
      /\b(as long as|on the condition)\b/i,
    ],
    Commitment::DEFERRED => [
      /\b(postpone|defer|push back|push to|rain check|reschedule|delay)\b/i,
      /\b(moved to|bumped to|later|another time)\b/i,
      /\b(tbd|to be determined|tba|to be announced)\b/i,
    ],
    Commitment::CANCELLED => [
      /\b(cancell?e?d?|called off|not happening|scrapped|abandoned)\b/i,
      /\b(won't|will not|no longer|dropped)\b/i,
    ],
  }

  def self.detect_commitment(text)
    # Check from most specific to least
    check_order = [
      Commitment::CANCELLED,
      Commitment::DEFERRED,
      Commitment::CONDITIONAL,
      Commitment::PROPOSED,
      Commitment::TENTATIVE,
      Commitment::FIXED,
    ]

    check_order.each do |level|
      patterns = INTENT_SIGNALS[level]
      return level if patterns.any? { |p| text.match?(p) }
    end

    # Default: if someone states something without hedging, it's fixed
    Commitment::FIXED
  end


  #############################################
  ## TemporalRange (minimal version for this file)

  class TemporalRange
    attr_reader :earliest, :latest, :label

    def initialize(earliest, latest, label: nil)
      @earliest = earliest
      @latest   = latest
      @label    = label
    end

    def to_s
      @label || "#{@earliest}..#{@latest}"
    end
  end


  #############################################
  ## Event with Commitment

  class Event
    attr_reader :description, :coordinate, :commitment, :conditions,
                :original_text, :transitions

    def initialize(description, coordinate, commitment: nil, original_text: nil, conditions: nil)
      @description   = description
      @coordinate    = coordinate
      @commitment    = commitment || Commitment::FIXED
      @original_text = original_text
      @conditions    = conditions  # for CONDITIONAL: what must be true
      @transitions   = []          # history of commitment changes
    end

    def tentative?  = @commitment == Commitment::TENTATIVE
    def fixed?      = @commitment == Commitment::FIXED
    def proposed?   = @commitment == Commitment::PROPOSED
    def cancelled?  = @commitment == Commitment::CANCELLED
    def actionable? = [:fixed, :recurring].include?(@commitment)

    # Commitment can change over time:
    # proposed → tentative → fixed → (possibly cancelled or deferred)
    def transition_to(new_commitment, reason: nil)
      @transitions << {
        from: @commitment,
        to: new_commitment,
        at: Time.now,
        reason: reason
      }
      @commitment = new_commitment
    end

    # For remind(1): only fixed/recurring events get REM lines.
    # Tentative events could get a different marker or be commented out.
    def to_remind
      case @commitment
      when Commitment::FIXED, Commitment::RECURRING
        "#{coordinate_to_remind} MSG #{@description} %"
      when Commitment::TENTATIVE
        "# TENTATIVE: #{coordinate_to_remind} MSG #{@description} %"
      when Commitment::PROPOSED
        "# PROPOSED: #{coordinate_to_remind} MSG #{@description} %"
      when Commitment::CONDITIONAL
        cond_note = @conditions ? " [#{@conditions}]" : ""
        "# CONDITIONAL#{cond_note}: #{coordinate_to_remind} MSG #{@description} %"
      when Commitment::DEFERRED
        "# DEFERRED: #{@description}"
      when Commitment::CANCELLED
        "# CANCELLED: #{@description}"
      end
    end

    private

    def coordinate_to_remind
      return "REM" unless @coordinate

      dt = @coordinate
      if dt.is_a?(TemporalRange)
        earliest = dt.earliest
        month = Date::MONTHNAMES[earliest.month][0..2]
        line = "REM #{month} #{earliest.day} #{earliest.year}"
        if earliest.hour != 0 || earliest.min != 0
          line += " AT %02d:%02d" % [earliest.hour, earliest.min]
        end
        if dt.latest && dt.latest != dt.earliest
          latest = dt.latest
          diff_min = ((latest - earliest) / 60).to_i
          if diff_min > 0 && diff_min < 1440  # less than a day
            h, m = diff_min.divmod(60)
            line += " DURATION #{h}:#{"%02d" % m}"
          else
            end_month = Date::MONTHNAMES[latest.month][0..2]
            line += " UNTIL #{end_month} #{latest.day} #{latest.year}"
          end
        end
        line
      elsif dt.respond_to?(:to_remind)
        dt.to_remind
      else
        "REM"
      end
    end
  end


  #############################################
  ## Examples

  def self.commitment_examples
    year = 2026

    puts "=" * 65
    puts "COMMITMENT DETECTION FROM NATURAL LANGUAGE"
    puts "=" * 65
    puts

    examples = [
      "I am planning a vacation in the spring",
      "I'm leaving on vacation the day after Christmas",
      "We might do Thanksgiving at mom's house this year",
      "Doctor appointment on March 15 at 2pm",
      "Maybe we should have a team dinner next Friday",
      "The conference has been cancelled",
      "Let's push the review to next week",
      "If the weather holds, we'll go hiking Saturday",
      "Dentist on Tuesday, assuming they have availability",
      "Sprint review every other Friday at 2pm",
      "I want to start running in the mornings",
      "Lunch is booked for noon at the Italian place",
      "We could visit Grandma for Easter",
      "The wedding is June 14th",
      "Thinking about taking a class this fall",
      "Rain check on Friday's lunch",
    ]

    examples.each do |text|
      level = detect_commitment(text)
      puts "  %-12s │ %s" % [level, text]
    end
    puts

    puts "=" * 65
    puts "EVENTS WITH COMMITMENT → REMIND OUTPUT"
    puts "=" * 65
    puts

    # "I am planning a vacation in the spring" — TENTATIVE
    spring = TemporalRange.new(
      Time.new(year, 3, 1), Time.new(year, 5, 31, 23, 59, 59),
      label: "spring #{year}"
    )
    e1 = Event.new(
      "Vacation",
      spring,
      commitment: Commitment::TENTATIVE,
      original_text: "I am planning a vacation in the spring"
    )
    puts "Input:  \"#{e1.original_text}\""
    puts "Output: #{e1.to_remind}"
    puts

    # "I'm leaving on vacation the day after Christmas and will not be
    #  back until the first Monday after New Years"  — FIXED
    day_after_xmas = Time.new(year, 12, 26)
    # First Monday after Jan 1: find it
    d = Date.new(year + 1, 1, 1)
    d += 1 until d.monday?
    first_monday = Time.new(d.year, d.month, d.day)

    vacation_span = TemporalRange.new(
      day_after_xmas, first_monday,
      label: "day after Christmas to first Monday after New Years"
    )
    e2 = Event.new(
      "Vacation",
      vacation_span,
      commitment: Commitment::FIXED,
      original_text: "I'm leaving the day after Christmas and won't be back until the first Monday after New Years"
    )
    puts "Input:  \"#{e2.original_text}\""
    puts "Output: #{e2.to_remind}"
    puts

    # "We might do Thanksgiving at mom's" — PROPOSED
    # Thanksgiving 2026: 4th Thursday of November
    d = Date.new(year, 11, 1)
    d += 1 until d.thursday?
    d += 21  # 4th Thursday
    thanksgiving = TemporalRange.new(
      Time.new(d.year, d.month, d.day, 14, 0),
      Time.new(d.year, d.month, d.day, 20, 0),
      label: "Thanksgiving #{year}"
    )
    e3 = Event.new(
      "Thanksgiving at mom's",
      thanksgiving,
      commitment: Commitment::PROPOSED,
      original_text: "We might do Thanksgiving at mom's house this year"
    )
    puts "Input:  \"#{e3.original_text}\""
    puts "Output: #{e3.to_remind}"
    puts

    # "If the weather holds, hiking Saturday" — CONDITIONAL
    next_saturday = Date.today
    next_saturday += 1 until next_saturday.saturday?
    hiking = TemporalRange.new(
      Time.new(next_saturday.year, next_saturday.month, next_saturday.day, 8, 0),
      Time.new(next_saturday.year, next_saturday.month, next_saturday.day, 14, 0),
      label: "Saturday hike"
    )
    e4 = Event.new(
      "Hiking",
      hiking,
      commitment: Commitment::CONDITIONAL,
      conditions: "weather permitting",
      original_text: "If the weather holds, we'll go hiking Saturday"
    )
    puts "Input:  \"#{e4.original_text}\""
    puts "Output: #{e4.to_remind}"
    puts

    puts "=" * 65
    puts "COMMITMENT TRANSITIONS"
    puts "=" * 65
    puts

    # An event starts tentative and becomes fixed
    trip = Event.new(
      "Beach trip",
      TemporalRange.new(Time.new(year, 7, 10), Time.new(year, 7, 17),
                         label: "beach trip"),
      commitment: Commitment::TENTATIVE,
      original_text: "Thinking about a beach trip in July"
    )

    puts "1. #{trip.commitment.upcase}: #{trip.to_remind}"

    trip.transition_to(Commitment::PROPOSED, reason: "discussed with family")
    puts "2. #{trip.commitment.upcase}: #{trip.to_remind}"

    trip.transition_to(Commitment::FIXED, reason: "hotel booked")
    puts "3. #{trip.commitment.upcase}: #{trip.to_remind}"

    trip.transition_to(Commitment::CANCELLED, reason: "hurricane warning")
    puts "4. #{trip.commitment.upcase}: #{trip.to_remind}"

    puts
    puts "Transition history:"
    trip.transitions.each do |t|
      puts "  #{t[:from]} → #{t[:to]} (#{t[:reason]})"
    end
  end
end


if __FILE__ == $0
  TemporalEvent.commitment_examples
end
