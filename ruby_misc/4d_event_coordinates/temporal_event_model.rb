#!/usr/bin/env ruby
# temporal_event_model.rb — Domain model sketch for natural language
# event-in-time to remind(1) syntax conversion.
#
# Core idea: An event is a description anchored to a temporal coordinate.
# Coordinates can be absolute, relative to other coordinates, or recurring.
# This is not a parser — it's the object model the parser would produce.
#
# Status: SKETCH / EXPLORATION — not production code

require 'date'
require 'time'

module TemporalEvent

  # A point in time, fully resolved to a specific datetime.
  # This is the leaf node — everything eventually resolves to one or more of these.
  class Instant
    attr_reader :datetime

    def initialize(datetime)
      @datetime = datetime
    end

    def to_remind
      dt = @datetime
      month = Date::MONTHNAMES[dt.month][0..2]
      line = "REM #{month} #{dt.day} #{dt.year}"
      line += " AT %02d:%02d" % [dt.hour, dt.min] unless dt.hour == 0 && dt.min == 0
      line
    end

    def to_s = @datetime.to_s
  end


  # A span of time between two temporal references.
  # The references can be Instants, NamedAnchors, or EventRefs.
  class Span
    attr_reader :start_ref, :end_ref

    def initialize(start_ref, end_ref)
      @start_ref = start_ref
      @end_ref   = end_ref
    end

    def duration_minutes
      s = @start_ref.resolve
      e = @end_ref.resolve
      ((e.datetime - s.datetime) / 60).to_i  # Time objects: difference is in seconds
    end

    def to_remind
      s = @start_ref.resolve
      e = @end_ref.resolve
      diff = duration_minutes
      days, remaining = diff.divmod(60 * 24)
      hours, mins = remaining.divmod(60)

      line = s.to_remind
      if days > 0
        # Multi-day spans: use UNTIL instead of DURATION
        month = Date::MONTHNAMES[e.datetime.month][0..2]
        line += " UNTIL #{month} #{e.datetime.day} #{e.datetime.year}"
      else
        line += " DURATION #{hours}:#{"%02d" % mins}"
      end
      line
    end
  end


  # A named temporal anchor — "christmas", "easter", "new years",
  # "thanksgiving", "my birthday". These resolve to Instants via
  # a registry of known anchors.
  class NamedAnchor
    attr_reader :name, :year

    def initialize(name, year: nil)
      @name = name.downcase.strip
      @year = year || Date.today.year
    end

    def resolve
      resolver = AnchorRegistry.resolve(@name, @year)
      raise "Unknown anchor: #{@name}" unless resolver
      resolver
    end

    def to_s = "#{@name} (#{@year})"
  end


  # A reference to another event by name or ID.
  # "the day after my dentist appointment" — the dentist appointment
  # is an EventRef whose coordinates come from looking it up.
  class EventRef
    attr_reader :event_name, :offset

    def initialize(event_name, offset: nil)
      @event_name = event_name
      @offset     = offset  # e.g., { days: 1 } for "the day after"
    end

    def resolve(event_store:)
      event = event_store.find(@event_name)
      raise "Unknown event: #{@event_name}" unless event
      base = event.coordinate.resolve
      return base unless @offset
      adjusted = base.datetime + (@offset[:days] || 0)
      Instant.new(adjusted)
    end
  end


  # An offset from another temporal reference.
  # "3 days before christmas", "the friday after thanksgiving"
  class RelativeAnchor
    attr_reader :base_ref, :offset, :direction, :snap_to

    # base_ref:   the thing we're relative to (NamedAnchor, EventRef, Instant)
    # offset:     { days: 3 } or { weeks: 1 } or nil if using snap_to
    # direction:  :before or :after
    # snap_to:    :friday, :monday, etc. — "the friday after thanksgiving"
    def initialize(base_ref, offset: nil, direction: :after, snap_to: nil)
      @base_ref  = base_ref
      @offset    = offset
      @direction = direction
      @snap_to   = snap_to
    end

    def resolve
      base = @base_ref.resolve
      dt   = base.datetime

      if @snap_to
        dt = snap_to_day(dt, @snap_to, @direction)
      elsif @offset
        total_days = (@offset[:days] || 0) + (@offset[:weeks] || 0) * 7
        total_days = -total_days if @direction == :before
        dt = dt + (total_days * 86400)
      end

      Instant.new(dt)
    end

    def to_remind
      resolve.to_remind
    end

    private

    def snap_to_day(dt, day_sym, direction)
      target_wday = Date::DAYNAMES.index(day_sym.to_s.capitalize)
      current_wday = dt.wday
      if direction == :after
        diff = (target_wday - current_wday) % 7
        diff = 7 if diff == 0  # "the friday AFTER" means next one, not same day
      else
        diff = (current_wday - target_wday) % 7
        diff = 7 if diff == 0
        diff = -diff
      end
      dt + diff
    end
  end


  # A recurrence pattern. This is the heart of remind's power.
  #
  # Recurrences have:
  #   - a period:    :daily, :weekly, :biweekly, :monthly, :yearly
  #   - a day spec:  which day(s) — :monday, [:mon, :wed, :fri], ordinal (2nd thursday)
  #   - a time spec: optional time of day
  #   - a duration:  optional length
  #   - an until:    optional end date
  #   - exclusions:  optional dates/anchors to skip (OMIT in remind)
  class Recurrence
    attr_reader :period, :days, :ordinal, :month,
                :time_of_day, :duration_minutes,
                :until_ref, :exclusions

    def initialize(
      period:,
      days: nil,
      ordinal: nil,
      month: nil,
      time_of_day: nil,
      duration_minutes: nil,
      until_ref: nil,
      exclusions: []
    )
      @period           = period
      @days             = Array(days)
      @ordinal          = ordinal      # e.g., :second, :third, :last
      @month            = month        # e.g., :november (for "third thursday in november")
      @time_of_day      = time_of_day  # { hour: 9, min: 30 }
      @duration_minutes = duration_minutes
      @until_ref        = until_ref    # NamedAnchor, Instant, or nil
      @exclusions       = exclusions   # array of NamedAnchors or Instants
    end

    ORDINAL_START_DAYS = {
      first: 1, second: 8, third: 15, fourth: 22, last: 25
    }

    DAY_ABBREVS = Date::DAYNAMES.map { |d| d[0..2] }

    def to_remind
      parts = ["REM"]

      case @period
      when :daily
        # no day restriction
      when :weekdays
        parts << "Mon Tue Wed Thu Fri"
      when :weekends
        parts << "Sat Sun"
      when :weekly
        parts << @days.map { |d| d.to_s.capitalize[0..2] }.join(" ")
      when :biweekly
        parts << @days.map { |d| d.to_s.capitalize[0..2] }.join(" ")
      when :monthly
        if @ordinal && @days.any?
          day_abbrev = @days.first.to_s.capitalize[0..2]
          start_day  = ORDINAL_START_DAYS[@ordinal]
          parts << "#{day_abbrev} #{start_day} ++7"
        end
        # plain monthly by date handled differently
      when :yearly
        if @ordinal && @days.any? && @month
          day_abbrev   = @days.first.to_s.capitalize[0..2]
          start_day    = ORDINAL_START_DAYS[@ordinal]
          month_abbrev = @month.to_s.capitalize[0..2]
          parts << "#{day_abbrev} #{month_abbrev} #{start_day} ++7"
        end
      end

      if @time_of_day
        parts << "AT %02d:%02d" % [@time_of_day[:hour], @time_of_day[:min]]
      end

      if @duration_minutes && @duration_minutes > 0
        h, m = @duration_minutes.divmod(60)
        parts << "DURATION #{h}:#{"%02d" % m}"
      end

      if @period == :biweekly
        parts << 'SATISFY [trigger(trigdate()) && ((coerce("INT", trigdate()) / 7) % 2) == 0]'
      end

      if @until_ref
        resolved = @until_ref.resolve
        dt = resolved.datetime
        month = Date::MONTHNAMES[dt.month][0..2]
        parts << "UNTIL #{month} #{dt.day} #{dt.year}"
      end

      if @exclusions.any?
        @exclusions.each do |exc|
          resolved = exc.resolve
          dt = resolved.datetime
          month = Date::MONTHNAMES[dt.month][0..2]
          parts << "OMIT #{month} #{dt.day}"
        end
      end

      parts.join(" ")
    end
  end


  # The top-level object: an Event is a description + a temporal coordinate.
  # The coordinate can be an Instant, Span, or Recurrence.
  class Event
    attr_reader :description, :coordinate

    def initialize(description, coordinate)
      @description = description
      @coordinate  = coordinate
    end

    def to_remind
      rem = @coordinate.to_remind
      "#{rem} MSG #{@description} %"
    end

    def to_s
      "Event: #{@description} @ #{@coordinate}"
    end
  end


  #############################################
  ## Anchor Registry
  ##
  ## Maps names like "christmas", "thanksgiving", "easter"
  ## to resolved Instants for a given year.
  ## This is where remind's hebdate() and easterdate()
  ## equivalents live on the Ruby side.

  module AnchorRegistry
    FIXED_DATES = {
      "new years"          => [1, 1],
      "new years day"      => [1, 1],
      "new years eve"      => [12, 31],
      "valentines day"     => [2, 14],
      "st patricks day"    => [3, 17],
      "independence day"   => [7, 4],
      "fourth of july"     => [7, 4],
      "halloween"          => [10, 31],
      "christmas eve"      => [12, 24],
      "christmas"          => [12, 25],
      "christmas day"      => [12, 25],
      "juneteenth"         => [6, 19],
      "veterans day"       => [11, 11],
    }

    # Floating holidays: [month, weekday (0=Sun), ordinal (1-based)]
    FLOATING_DATES = {
      "mlk day"            => [1, 1, 3],   # 3rd Monday in January
      "martin luther king" => [1, 1, 3],
      "presidents day"     => [2, 1, 3],   # 3rd Monday in February
      "memorial day"       => [5, 1, :last],
      "labor day"          => [9, 1, 1],   # 1st Monday in September
      "columbus day"       => [10, 1, 2],  # 2nd Monday in October
      "thanksgiving"       => [11, 4, 4],  # 4th Thursday in November
      "mothers day"        => [5, 0, 2],   # 2nd Sunday in May
      "fathers day"        => [6, 0, 3],   # 3rd Sunday in June
    }

    def self.resolve(name, year)
      name = name.downcase.gsub(/[''']s?\s*$/, '').strip

      if (fixed = FIXED_DATES[name])
        month, day = fixed
        Instant.new(Time.new(year, month, day))
      elsif (floating = FLOATING_DATES[name])
        month, wday, ordinal = floating
        Instant.new(compute_floating(year, month, wday, ordinal))
      elsif name == "easter"
        Instant.new(compute_easter(year))
      elsif name == "good friday"
        easter = compute_easter(year)
        Instant.new(easter - 2 * 86400)
      elsif name == "palm sunday"
        easter = compute_easter(year)
        Instant.new(easter - 7 * 86400)
      elsif name == "ash wednesday"
        easter = compute_easter(year)
        Instant.new(easter - 46 * 86400)
      else
        nil
      end
    end

    def self.compute_floating(year, month, wday, ordinal)
      if ordinal == :last
        # Start from last day of month, walk backward
        last_day = Date.new(year, month, -1)
        d = last_day
        d -= 1 until d.wday == wday
        Time.new(d.year, d.month, d.day)
      else
        # Start from 1st of month, find nth occurrence
        d = Date.new(year, month, 1)
        d += 1 until d.wday == wday
        d += 7 * (ordinal - 1)
        Time.new(d.year, d.month, d.day)
      end
    end

    # Anonymous Gregorian Easter (Meeus algorithm)
    def self.compute_easter(year)
      a = year % 19
      b, c = year.divmod(100)
      d, e = b.divmod(4)
      f = (b + 8) / 25
      g = (b - f + 1) / 3
      h = (19 * a + b - d - g + 15) % 30
      i, k = c.divmod(4)
      l = (32 + 2 * e + 2 * i - h - k) % 7
      m = (a + 11 * h + 22 * l) / 451
      month, day = (h + l - 7 * m + 114).divmod(31)
      day += 1
      Time.new(year, month, day)
    end
  end


  #############################################
  ## Usage examples — what the parser would produce

  def self.examples
    year = Date.today.year

    puts "=== Single event ==="
    e1 = Event.new(
      "Dentist appointment",
      Instant.new(Time.new(year, 3, 15, 14, 30))
    )
    puts e1.to_remind
    puts

    puts "=== Recurring event ==="
    e2 = Event.new(
      "Team standup",
      Recurrence.new(
        period: :weekdays,
        time_of_day: { hour: 9, min: 0 }
      )
    )
    puts e2.to_remind
    puts

    puts "=== Ordinal weekday ==="
    e3 = Event.new(
      "Quilt Guild in Tyler TX",
      Recurrence.new(
        period: :monthly,
        ordinal: :second,
        days: [:thursday],
        time_of_day: { hour: 9, min: 30 },
        duration_minutes: 120
      )
    )
    puts e3.to_remind
    puts

    puts "=== Yearly ordinal ==="
    e4 = Event.new(
      "Thanksgiving dinner",
      Recurrence.new(
        period: :yearly,
        ordinal: :fourth,
        days: [:thursday],
        month: :november,
        time_of_day: { hour: 14, min: 0 },
        duration_minutes: 180
      )
    )
    puts e4.to_remind
    puts

    puts "=== Anchored to named event ==="
    christmas = NamedAnchor.new("christmas", year: year)
    new_years = NamedAnchor.new("new years", year: year + 1)
    e5 = Event.new(
      "Family vacation",
      Span.new(christmas, new_years)
    )
    puts e5.to_remind
    puts

    puts "=== Relative to named anchor ==="
    black_friday = RelativeAnchor.new(
      NamedAnchor.new("thanksgiving", year: year),
      offset: { days: 1 },
      direction: :after
    )
    e6 = Event.new(
      "Black Friday shopping",
      black_friday
    )
    puts "#{e6.to_remind}"  # need to wrap in Event-compatible way
    puts

    puts "=== Biweekly ==="
    e7 = Event.new(
      "Sprint review",
      Recurrence.new(
        period: :biweekly,
        days: [:friday],
        time_of_day: { hour: 14, min: 0 },
        duration_minutes: 60
      )
    )
    puts e7.to_remind
    puts

    puts "=== With until ==="
    e8 = Event.new(
      "Morning yoga",
      Recurrence.new(
        period: :daily,
        time_of_day: { hour: 6, min: 0 },
        duration_minutes: 90,
        until_ref: NamedAnchor.new("memorial day", year: year)
      )
    )
    puts e8.to_remind
    puts
  end
end


if __FILE__ == $0
  TemporalEvent.examples
end
