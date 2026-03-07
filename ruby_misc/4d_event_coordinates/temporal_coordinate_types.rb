#!/usr/bin/env ruby
# temporal_coordinate_types.rb — Extended temporal reference types
#
# Origin: This problem space was first explored in 2001 during the JISR
# (Joint Intelligence, Surveillance, and Reconnaissance) project for the
# US military. The driving question: how do you codify and reason about
# temporal expressions like "Expect an attack after Ramadan" where the
# reference is cultural, calendar-system-dependent, and fuzzy?
#
# Core insight: Not all temporal references resolve to points. Many resolve
# to RANGES with varying degrees of precision. The system must preserve
# that fuzziness rather than forcing false precision.
#
# Status: SKETCH / EXPLORATION

require 'date'
require 'time'

module TemporalEvent

  #############################################
  ## Temporal Resolution — how precise is this reference?
  ##
  ## A datetime coordinate carries a resolution that tells you
  ## how much you actually know. "March 15 at 2pm" is precise.
  ## "Spring" is seasonal. "After ramadan" is bounded-start-open-end.

  module Resolution
    EXACT      = :exact       # "March 15, 2026 at 14:30"
    DAY        = :day         # "March 15" (no time)
    WEEK       = :week        # "next week"
    MONTH      = :month       # "in March"
    SEASON     = :season      # "this spring"
    QUARTER    = :quarter     # "Q2"
    YEAR       = :year        # "next year"
    PERIOD     = :period      # "morning", "evening" — sub-day range
    ASTRO      = :astronomical # "sunrise", "sunset" — computed, location-dependent
    CULTURAL   = :cultural    # "after ramadan" — calendar-system-dependent range
    UNBOUNDED  = :unbounded   # "someday", "eventually"
  end


  #############################################
  ## TemporalRange — the fundamental type
  ##
  ## Most temporal references are ranges, not points.
  ## Even "3pm" is really "3:00:00 to 3:00:59".
  ## A range has an earliest possible start, a latest possible end,
  ## and a resolution that describes the confidence.

  class TemporalRange
    attr_reader :earliest, :latest, :resolution, :label

    def initialize(earliest, latest, resolution:, label: nil)
      @earliest   = earliest   # Time object — earliest this could mean
      @latest     = latest     # Time object — latest this could mean
      @resolution = resolution
      @label      = label      # human-readable name: "spring 2026", "morning"
    end

    # The midpoint — useful when you need a single point for remind
    def midpoint
      Time.at((@earliest.to_f + @latest.to_f) / 2)
    end

    # Duration in seconds
    def duration_seconds
      @latest.to_f - @earliest.to_f
    end

    def contains?(time)
      time >= @earliest && time <= @latest
    end

    def to_s
      if @label
        "#{@label} (#{@earliest.strftime('%Y-%m-%d')}..#{@latest.strftime('%Y-%m-%d')})"
      else
        "#{@earliest}..#{@latest}"
      end
    end
  end


  #############################################
  ## Seasonal references
  ##
  ## Seasons depend on hemisphere. Meteorological vs astronomical
  ## definitions differ. We use meteorological (cleaner boundaries)
  ## by default but support astronomical (solstice/equinox based).

  module Seasons
    # Meteorological seasons (Northern Hemisphere)
    NORTHERN_MET = {
      spring: { start: [3, 1],  end: [5, 31] },
      summer: { start: [6, 1],  end: [8, 31] },
      fall:   { start: [9, 1],  end: [11, 30] },
      autumn: { start: [9, 1],  end: [11, 30] },
      winter: { start: [12, 1], end: [2, 28] },  # crosses year boundary
    }

    # Southern hemisphere is offset by 6 months
    SOUTHERN_MET = {
      spring: { start: [9, 1],  end: [11, 30] },
      summer: { start: [12, 1], end: [2, 28] },
      fall:   { start: [3, 1],  end: [5, 31] },
      autumn: { start: [3, 1],  end: [5, 31] },
      winter: { start: [6, 1],  end: [8, 31] },
    }

    def self.resolve(season_name, year, hemisphere: :northern)
      season = season_name.to_sym
      table  = hemisphere == :northern ? NORTHERN_MET : SOUTHERN_MET
      spec   = table[season]
      return nil unless spec

      s_month, s_day = spec[:start]
      e_month, e_day = spec[:end]

      # Handle winter crossing year boundary
      if s_month > e_month
        start_time = Time.new(year, s_month, s_day)
        end_time   = Time.new(year + 1, e_month, e_day, 23, 59, 59)
      else
        start_time = Time.new(year, s_month, s_day)
        end_time   = Time.new(year, e_month, e_day, 23, 59, 59)
      end

      TemporalRange.new(
        start_time, end_time,
        resolution: Resolution::SEASON,
        label: "#{season} #{year}"
      )
    end
  end


  #############################################
  ## Time-of-day periods
  ##
  ## "Morning", "afternoon", "evening", "night" — these are cultural
  ## and contextual. Military, civilian, and agricultural communities
  ## have different boundaries. We define defaults and allow override.

  module DayPeriods
    # Default civilian boundaries (24hr)
    DEFAULTS = {
      predawn:   { start: [3, 0],  end: [5, 59] },
      dawn:      { start: [5, 0],  end: [6, 59] },   # overlaps — fuzzy by nature
      morning:   { start: [6, 0],  end: [11, 59] },
      midday:    { start: [11, 0], end: [13, 0] },
      noon:      { start: [12, 0], end: [12, 0] },    # precise
      afternoon: { start: [12, 0], end: [16, 59] },
      evening:   { start: [17, 0], end: [20, 59] },
      dusk:      { start: [19, 0], end: [21, 0] },    # overlaps
      night:     { start: [21, 0], end: [2, 59] },    # crosses midnight
      midnight:  { start: [0, 0],  end: [0, 0] },     # precise
    }

    # Military boundaries — earlier starts, sharper divisions
    MILITARY = {
      morning:   { start: [5, 0],  end: [11, 59] },
      afternoon: { start: [12, 0], end: [17, 59] },
      evening:   { start: [18, 0], end: [21, 59] },
      night:     { start: [22, 0], end: [4, 59] },
    }

    def self.resolve(period_name, date, context: :civilian)
      period = period_name.to_sym
      table  = context == :military ? MILITARY : DEFAULTS
      spec   = table[period]
      return nil unless spec

      s_h, s_m = spec[:start]
      e_h, e_m = spec[:end]

      start_time = Time.new(date.year, date.month, date.day, s_h, s_m)

      # Handle night crossing midnight
      if s_h > e_h
        end_time = Time.new(date.year, date.month, date.day + 1, e_h, e_m, 59)
      else
        end_time = Time.new(date.year, date.month, date.day, e_h, e_m, 59)
      end

      TemporalRange.new(
        start_time, end_time,
        resolution: Resolution::PERIOD,
        label: "#{period} of #{date.strftime('%Y-%m-%d')}"
      )
    end
  end


  #############################################
  ## Astronomical references — sunrise, sunset, twilight
  ##
  ## These require a geographic location. Without one, we can
  ## provide approximate ranges or raise an error.
  ##
  ## Full implementation would use the NOAA solar calculator
  ## or the US Naval Observatory algorithm.

  class GeoLocation
    attr_reader :latitude, :longitude, :timezone, :name

    def initialize(latitude:, longitude:, timezone: 'UTC', name: nil)
      @latitude  = latitude
      @longitude = longitude
      @timezone  = timezone
      @name      = name
    end

    # Commonly referenced locations
    EAST_TEXAS = new(latitude: 32.35, longitude: -95.30, timezone: 'US/Central', name: 'East Texas')
    MECCA      = new(latitude: 21.42, longitude: 39.83, timezone: 'Asia/Riyadh', name: 'Mecca')
    JERUSALEM  = new(latitude: 31.77, longitude: 35.23, timezone: 'Asia/Jerusalem', name: 'Jerusalem')
    DC         = new(latitude: 38.90, longitude: -77.04, timezone: 'US/Eastern', name: 'Washington DC')
  end

  module SolarEvents
    # Simplified sunrise/sunset calculator (accurate to ~5 minutes)
    # For production: use NOAA algorithm or the `sun_times` gem
    def self.sunrise(date, location)
      # Placeholder — returns approximate range for the latitude
      # Real implementation: NOAA solar position algorithm
      approx = approximate_solar(date, location, :sunrise)
      TemporalRange.new(
        approx - 300,  # 5 min before
        approx + 300,  # 5 min after (atmospheric refraction uncertainty)
        resolution: Resolution::ASTRO,
        label: "sunrise at #{location.name || '%.1f,%.1f' % [location.latitude, location.longitude]}"
      )
    end

    def self.sunset(date, location)
      approx = approximate_solar(date, location, :sunset)
      TemporalRange.new(
        approx - 300,
        approx + 300,
        resolution: Resolution::ASTRO,
        label: "sunset at #{location.name || '%.1f,%.1f' % [location.latitude, location.longitude]}"
      )
    end

    # Civil twilight: enough light to see without artificial light
    def self.civil_twilight(date, location, which = :dawn)
      sr = approximate_solar(date, location, :sunrise)
      ss = approximate_solar(date, location, :sunset)
      if which == :dawn
        TemporalRange.new(sr - 1800, sr, resolution: Resolution::ASTRO,
                          label: "civil dawn twilight")
      else
        TemporalRange.new(ss, ss + 1800, resolution: Resolution::ASTRO,
                          label: "civil dusk twilight")
      end
    end

    # Simplified solar calculation — for sketch purposes
    # Real implementation needs equation of time, solar declination, hour angle
    def self.approximate_solar(date, location, event)
      # Very rough: 6am + latitude adjustment for sunrise, 6pm + adjustment for sunset
      day_of_year = date.yday
      lat = location.latitude

      # Approximate day length variation (hours) based on latitude and season
      declination = 23.45 * Math.sin(2 * Math::PI * (284 + day_of_year) / 365.0)
      hour_angle  = Math.acos(
        -Math.tan(lat * Math::PI / 180) * Math.tan(declination * Math::PI / 180)
      ) * 180 / Math::PI rescue 90  # handle polar regions

      day_length_hours = 2 * hour_angle / 15.0
      sunrise_hour = 12.0 - (day_length_hours / 2.0)
      sunset_hour  = 12.0 + (day_length_hours / 2.0)

      hour = event == :sunrise ? sunrise_hour : sunset_hour
      h = hour.floor
      m = ((hour - h) * 60).round

      Time.new(date.year, date.month, date.day, h, m, 0)
    end
  end


  #############################################
  ## Cultural/Religious calendar periods
  ##
  ## These are the "after ramadan" problem. Religious observances
  ## are ranges in non-Gregorian calendar systems that must be
  ## resolved to Gregorian ranges.
  ##
  ## The key difference from NamedAnchor: these are PERIODS (ranges)
  ## not points. Ramadan is ~30 days. Passover is 7-8 days. Lent is 40 days.

  module CulturalPeriods

    # Islamic calendar periods
    # The Islamic calendar is purely lunar, ~354 days/year.
    # Dates shift ~11 days earlier each Gregorian year.
    # Precise computation requires the Hijri calendar algorithm
    # or published tables (e.g., from the Umm al-Qura calendar).
    #
    # For 1447 AH (approx. 2025-2026 Gregorian):
    ISLAMIC_1447 = {
      ramadan:         { start: [2026, 2, 18],  end: [2026, 3, 19] },
      eid_al_fitr:     { start: [2026, 3, 20],  end: [2026, 3, 22] },
      hajj:            { start: [2026, 5, 16],  end: [2026, 5, 20] },
      eid_al_adha:     { start: [2026, 5, 17],  end: [2026, 5, 19] },
      muharram:        { start: [2026, 6, 17],  end: [2026, 7, 15] },
    }

    # For 1448 AH (approx. 2026-2027 Gregorian):
    ISLAMIC_1448 = {
      ramadan:         { start: [2027, 2, 8],   end: [2027, 3, 9] },
      eid_al_fitr:     { start: [2027, 3, 10],  end: [2027, 3, 12] },
      hajj:            { start: [2027, 5, 5],   end: [2027, 5, 9] },
      eid_al_adha:     { start: [2027, 5, 6],   end: [2027, 5, 8] },
    }

    # Jewish calendar periods (computed from Hebrew calendar)
    # Uses fixed Gregorian approximations per year — real implementation
    # would use a Hebrew calendar gem or algorithm.
    JEWISH_2026 = {
      passover:     { start: [2026, 4, 2],  end: [2026, 4, 9] },    # Pesach
      shavuot:      { start: [2026, 5, 22], end: [2026, 5, 23] },
      rosh_hashana: { start: [2026, 9, 12], end: [2026, 9, 13] },
      yom_kippur:   { start: [2026, 9, 21], end: [2026, 9, 21] },   # single day
      sukkot:       { start: [2026, 9, 26], end: [2026, 10, 2] },
      hanukkah:     { start: [2026, 12, 5], end: [2026, 12, 12] },
    }

    # Christian liturgical periods
    # Easter-derived dates are computed, fixed dates are fixed.
    CHRISTIAN_PERIODS = {
      advent:  -> (year) {
        # 4 Sundays before Christmas
        christmas = Date.new(year, 12, 25)
        fourth_sunday = christmas - ((christmas.wday) % 7) # Sunday before Christmas
        first_sunday = fourth_sunday - 21
        { start: [year, first_sunday.month, first_sunday.day],
          end:   [year, 12, 24] }
      },
      lent:    -> (year) {
        easter = compute_easter(year)
        ash_wed = easter - 46
        { start: [ash_wed.year, ash_wed.month, ash_wed.day],
          end:   [easter.year, easter.month, easter.day - 2] }  # ends Holy Thursday
      },
      holy_week: -> (year) {
        easter = compute_easter(year)
        palm = easter - 7
        { start: [palm.year, palm.month, palm.day],
          end:   [easter.year, easter.month, easter.day] }
      },
      easter_season: -> (year) {
        easter = compute_easter(year)
        pentecost = easter + 49
        { start: [easter.year, easter.month, easter.day],
          end:   [pentecost.year, pentecost.month, pentecost.day] }
      },
    }

    def self.resolve(period_name, year)
      name = period_name.to_s.downcase.gsub(/[\s-]/, '_').to_sym

      # Check Islamic (try current year's table)
      [ISLAMIC_1447, ISLAMIC_1448].each do |table|
        if (spec = table[name])
          s = spec[:start]
          e = spec[:end]
          next unless s[0] == year || e[0] == year
          return TemporalRange.new(
            Time.new(*s), Time.new(*e, 23, 59, 59),
            resolution: Resolution::CULTURAL,
            label: "#{period_name} #{year}"
          )
        end
      end

      # Check Jewish
      if (spec = JEWISH_2026[name]) && year == 2026
        s, e = spec[:start], spec[:end]
        return TemporalRange.new(
          Time.new(*s), Time.new(*e, 23, 59, 59),
          resolution: Resolution::CULTURAL,
          label: "#{period_name} #{year}"
        )
      end

      # Check Christian (computed)
      if (builder = CHRISTIAN_PERIODS[name])
        spec = builder.call(year)
        s, e = spec[:start], spec[:end]
        return TemporalRange.new(
          Time.new(*s), Time.new(*e, 23, 59, 59),
          resolution: Resolution::CULTURAL,
          label: "#{period_name} #{year}"
        )
      end

      nil
    end

    # Meeus algorithm for Easter
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
      Date.new(year, month, day)
    end
  end


  #############################################
  ## Temporal Relation — how one reference relates to another
  ##
  ## "after ramadan" — starts at the end of the ramadan range
  ## "before sunrise" — ends at the start of the sunrise range
  ## "during lent" — bounded by the lent range
  ## "the morning of christmas" — intersection of morning + christmas day

  module Relation
    BEFORE = :before   # ends at or before the start of the reference
    AFTER  = :after    # starts at or after the end of the reference
    DURING = :during   # contained within the reference range
    AROUND = :around   # overlapping, fuzzy proximity
    UNTIL  = :until    # from now until the start of the reference
    SINCE  = :since    # from the end of the reference until now
  end

  class RelativeToRange
    attr_reader :base_range, :relation, :label

    def initialize(base_range, relation:, label: nil)
      @base_range = base_range
      @relation   = relation
      @label      = label
    end

    # Returns a TemporalRange representing the implied time
    def resolve
      case @relation
      when Relation::AFTER
        # "after ramadan" — starts when ramadan ends, open-ended
        # The open end is the key: we know the START but not the end.
        # For remind, we'd use the start date.
        # For intelligence analysis, this is "any time from X onward"
        TemporalRange.new(
          @base_range.latest,
          @base_range.latest + (365 * 86400),  # placeholder: 1 year
          resolution: Resolution::UNBOUNDED,
          label: "after #{@base_range.label}"
        )

      when Relation::BEFORE
        # "before sunrise" — ends when the reference starts
        TemporalRange.new(
          @base_range.earliest - (365 * 86400),
          @base_range.earliest,
          resolution: Resolution::UNBOUNDED,
          label: "before #{@base_range.label}"
        )

      when Relation::DURING
        # "during lent" — same range as the reference
        TemporalRange.new(
          @base_range.earliest,
          @base_range.latest,
          resolution: @base_range.resolution,
          label: "during #{@base_range.label}"
        )

      when Relation::AROUND
        # "around christmas" — fuzzy expansion
        padding = [(@base_range.duration_seconds * 0.25).to_i, 86400].max
        TemporalRange.new(
          @base_range.earliest - padding,
          @base_range.latest + padding,
          resolution: Resolution::UNBOUNDED,
          label: "around #{@base_range.label}"
        )

      when Relation::UNTIL
        TemporalRange.new(
          Time.now,
          @base_range.earliest,
          resolution: @base_range.resolution,
          label: "until #{@base_range.label}"
        )

      when Relation::SINCE
        TemporalRange.new(
          @base_range.latest,
          Time.now,
          resolution: @base_range.resolution,
          label: "since #{@base_range.label}"
        )
      end
    end
  end


  #############################################
  ## Compound temporal expressions
  ##
  ## "the morning of the day after thanksgiving"
  ##   = DayPeriod(:morning) ∩ RelativeAnchor(thanksgiving, +1 day)
  ##
  ## "every friday evening during ramadan"
  ##   = Recurrence(:weekly, :friday) ∩ DayPeriod(:evening) ∩ CulturalPeriod(:ramadan)
  ##
  ## These are intersections of temporal ranges.

  class Intersection
    attr_reader :ranges, :label

    def initialize(*ranges, label: nil)
      @ranges = ranges
      @label  = label
    end

    def resolve
      resolved = @ranges.map { |r| r.is_a?(TemporalRange) ? r : r.resolve }
      earliest = resolved.map(&:earliest).max
      latest   = resolved.map(&:latest).min

      if earliest > latest
        # Empty intersection — the ranges don't overlap
        return nil
      end

      TemporalRange.new(
        earliest, latest,
        resolution: resolved.map(&:resolution).min_by { |r| resolution_rank(r) },
        label: @label || resolved.map(&:label).compact.join(" ∩ ")
      )
    end

    private

    def resolution_rank(res)
      # Lower = more precise
      { exact: 0, day: 1, period: 2, astronomical: 3,
        week: 4, month: 5, season: 6, cultural: 7,
        quarter: 8, year: 9, unbounded: 10 }[res] || 99
    end
  end


  #############################################
  ## Examples

  def self.extended_examples
    year = 2026

    puts "=== Seasonal ==="
    spring = Seasons.resolve(:spring, year)
    puts "  #{spring}"

    winter = Seasons.resolve(:winter, year)
    puts "  #{winter}"
    puts

    puts "=== Day periods ==="
    today = Date.today
    morning = DayPeriods.resolve(:morning, today)
    puts "  civilian: #{morning}"

    mil_morning = DayPeriods.resolve(:morning, today, context: :military)
    puts "  military: #{mil_morning}"
    puts

    puts "=== Solar events ==="
    tyler = GeoLocation::EAST_TEXAS
    sr = SolarEvents.sunrise(today, tyler)
    puts "  #{sr}"

    ss = SolarEvents.sunset(today, tyler)
    puts "  #{ss}"
    puts

    puts "=== Cultural periods ==="
    ramadan = CulturalPeriods.resolve(:ramadan, year)
    puts "  #{ramadan}"

    lent = CulturalPeriods.resolve(:lent, year)
    puts "  #{lent}"

    passover = CulturalPeriods.resolve(:passover, year)
    puts "  #{passover}"
    puts

    puts "=== 'Expect an attack after Ramadan' ==="
    after_ramadan = RelativeToRange.new(ramadan, relation: Relation::AFTER)
    resolved = after_ramadan.resolve
    puts "  #{resolved}"
    puts "  Earliest actionable date: #{resolved.earliest.strftime('%Y-%m-%d')}"
    puts "  Resolution: #{resolved.resolution}"
    puts

    puts "=== 'Meeting tomorrow morning' ==="
    tomorrow = Date.today + 1
    tom_morning = DayPeriods.resolve(:morning, tomorrow)
    puts "  #{tom_morning}"
    puts

    puts "=== 'Vacation between Christmas and New Years' ==="
    christmas = CulturalPeriods.resolve(:advent, year)  # or use NamedAnchor
    # More directly:
    xmas_range = TemporalRange.new(
      Time.new(year, 12, 25), Time.new(year + 1, 1, 1, 23, 59, 59),
      resolution: Resolution::DAY,
      label: "christmas to new years #{year}"
    )
    puts "  #{xmas_range}"
    puts

    puts "=== 'Before sunrise on Easter' ==="
    easter_date = CulturalPeriods.compute_easter(year)
    sunrise = SolarEvents.sunrise(easter_date, tyler)
    before_sunrise = RelativeToRange.new(sunrise, relation: Relation::BEFORE)
    resolved = before_sunrise.resolve
    puts "  Easter: #{easter_date}"
    puts "  Sunrise: #{sunrise}"
    puts "  Before sunrise: earliest meaningful = #{easter_date.strftime('%Y-%m-%d')} 00:00"
    puts "  Window: midnight to ~#{sunrise.earliest.strftime('%H:%M')}"
    puts

    puts "=== 'Every Friday evening during Ramadan' ==="
    friday_evening = DayPeriods.resolve(:evening, Date.new(year, 3, 1))
    puts "  Ramadan: #{ramadan}"
    puts "  This would generate reminders for:"
    d = Date.new(ramadan.earliest.year, ramadan.earliest.month, ramadan.earliest.day)
    end_d = Date.new(ramadan.latest.year, ramadan.latest.month, ramadan.latest.day)
    while d <= end_d
      puts "    #{d.strftime('%A %Y-%m-%d')} evening" if d.friday?
      d += 1
    end
    puts
  end
end


if __FILE__ == $0
  TemporalEvent.extended_examples
end
