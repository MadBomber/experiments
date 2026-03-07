#!/usr/bin/env ruby
# spacetime_event.rb — Unified 4D event model
#
# Combines temporal, spatial, and commitment dimensions into a single
# event representation that preserves fuzziness, partial knowledge,
# and explicit uncertainty.
#
# Key concept: PARTIAL KNOWLEDGE
# "We are planning to vacation in Europe sometime next spring.
#  We don't know which countries we will be visiting other than Italy."
#
# This encodes:
#   Temporal:    TemporalRange(spring 2027) — fuzzy, seasonal
#   Spatial:     Region(Europe) with known sub-region(Italy) + unknown sub-regions
#   Commitment:  TENTATIVE ("planning to")
#   Uncertainty: EXPLICIT ("we don't know") — not just missing data, stated unknown
#
# The difference between "missing" and "explicitly unknown" matters.
# Missing data might be filled in later from another source.
# Explicitly unknown means the source HAS no better information.
#
# Status: SKETCH / EXPLORATION

require 'date'
require 'time'

module SpaceTime

  #############################################
  ## Precision / Resolution

  module Precision
    EXACT        = :exact
    ADDRESS      = :address
    CITY         = :city
    REGION       = :region
    COUNTRY      = :country
    CONTINENT    = :continent
    UNBOUNDED    = :unbounded
  end

  module Resolution
    EXACT    = :exact
    DAY      = :day
    WEEK     = :week
    MONTH    = :month
    SEASON   = :season
    YEAR     = :year
    UNBOUNDED = :unbounded
  end

  module Commitment
    FIXED       = :fixed
    TENTATIVE   = :tentative
    PROPOSED    = :proposed
    CONDITIONAL = :conditional
    DEFERRED    = :deferred
    CANCELLED   = :cancelled
  end


  #############################################
  ## Knowledge State
  ##
  ## Tracks what is known, partially known, and explicitly unknown
  ## about a dimension of the event.

  module KnowledgeState
    KNOWN             = :known              # "Italy" — we know this
    PARTIALLY_KNOWN   = :partially_known    # "Europe, including Italy" — we know some
    EXPLICITLY_UNKNOWN = :explicitly_unknown # "we don't know" — source stated uncertainty
    MISSING           = :missing            # not mentioned — might learn later
  end

  class KnowledgeFact
    attr_reader :value, :state, :confidence, :source_text

    def initialize(value, state:, confidence: nil, source_text: nil)
      @value       = value
      @state       = state
      @confidence  = confidence    # 0.0 to 1.0, nil if not applicable
      @source_text = source_text   # the original words that produced this fact
    end

    def known?              = @state == KnowledgeState::KNOWN
    def partially_known?    = @state == KnowledgeState::PARTIALLY_KNOWN
    def explicitly_unknown? = @state == KnowledgeState::EXPLICITLY_UNKNOWN
    def missing?            = @state == KnowledgeState::MISSING

    def to_s
      case @state
      when KnowledgeState::KNOWN
        "#{@value}"
      when KnowledgeState::PARTIALLY_KNOWN
        "#{@value} (partial)"
      when KnowledgeState::EXPLICITLY_UNKNOWN
        "UNKNOWN (stated: \"#{@source_text}\")"
      when KnowledgeState::MISSING
        "—"
      end
    end
  end


  #############################################
  ## Spatial Types (simplified from spatial_coordinate.rb)

  class SpatialPoint
    attr_reader :latitude, :longitude, :label

    def initialize(latitude:, longitude:, label: nil)
      @latitude  = latitude
      @longitude = longitude
      @label     = label
    end

    def to_s = @label || "%.4f, %.4f" % [@latitude, @longitude]
  end

  class SpatialRegion
    attr_reader :name, :center, :radius_km, :precision,
                :known_sub_regions, :unknown_sub_regions

    def initialize(name, center:, radius_km:, precision:,
                   known_sub_regions: [], unknown_sub_regions: nil)
      @name                = name
      @center              = center
      @radius_km           = radius_km
      @precision           = precision
      @known_sub_regions   = known_sub_regions    # confirmed parts
      @unknown_sub_regions = unknown_sub_regions  # explicitly stated as unknown
    end

    def to_s
      s = "#{@name} (#{@precision}, ~#{@radius_km}km radius)"
      if @known_sub_regions.any?
        s += "\n    Confirmed: #{@known_sub_regions.map(&:to_s).join(', ')}"
      end
      if @unknown_sub_regions
        s += "\n    Unknown:   #{@unknown_sub_regions}"
      end
      s
    end
  end

  class SubRegion
    attr_reader :name, :state

    def initialize(name, state: KnowledgeState::KNOWN)
      @name  = name
      @state = state
    end

    def to_s = @name
  end


  #############################################
  ## Temporal Types (simplified)

  class TemporalRange
    attr_reader :earliest, :latest, :resolution, :label

    def initialize(earliest, latest, resolution:, label: nil)
      @earliest   = earliest
      @latest     = latest
      @resolution = resolution
      @label      = label
    end

    def duration_days
      ((@latest - @earliest) / 86400).to_i
    end

    def to_s
      "#{@label || 'range'} (#{@earliest.strftime('%Y-%m-%d')}..#{@latest.strftime('%Y-%m-%d')}, #{@resolution})"
    end
  end


  #############################################
  ## The Unified SpaceTimeEvent
  ##
  ## An event located in 4D spacetime with knowledge tracking
  ## on each dimension.

  class Event
    attr_reader :description, :spatial, :temporal, :commitment,
                :knowledge, :original_text, :participants

    def initialize(
      description,
      spatial: nil,
      temporal: nil,
      commitment: Commitment::FIXED,
      original_text: nil,
      participants: []
    )
      @description   = description
      @spatial       = spatial
      @temporal      = temporal
      @commitment    = commitment
      @original_text = original_text
      @participants  = participants

      # Knowledge tracking per dimension
      @knowledge = {
        spatial:  classify_spatial_knowledge,
        temporal: classify_temporal_knowledge,
      }
    end

    def to_s
      lines = []
      lines << "=" * 70
      lines << "EVENT: #{@description}"
      lines << "=" * 70
      lines << ""

      if @original_text
        lines << "Source text:"
        lines << "  \"#{@original_text}\""
        lines << ""
      end

      lines << "Commitment: #{@commitment}"
      lines << ""

      lines << "TEMPORAL:"
      if @temporal
        lines << "  #{@temporal}"
        lines << "  Knowledge: #{@knowledge[:temporal]}"
      else
        lines << "  —"
      end
      lines << ""

      lines << "SPATIAL:"
      if @spatial
        lines << "  #{@spatial}".gsub("\n", "\n  ")
        lines << "  Knowledge: #{@knowledge[:spatial]}"
      else
        lines << "  —"
      end
      lines << ""

      if @participants.any?
        lines << "PARTICIPANTS:"
        @participants.each { |p| lines << "  #{p}" }
        lines << ""
      end

      lines.join("\n")
    end

    private

    def classify_spatial_knowledge
      return KnowledgeState::MISSING unless @spatial
      if @spatial.is_a?(SpatialRegion) && @spatial.unknown_sub_regions
        KnowledgeState::PARTIALLY_KNOWN
      elsif @spatial.precision == Precision::UNBOUNDED
        KnowledgeState::EXPLICITLY_UNKNOWN
      else
        KnowledgeState::KNOWN
      end
    end

    def classify_temporal_knowledge
      return KnowledgeState::MISSING unless @temporal
      if @temporal.resolution == Resolution::SEASON || @temporal.resolution == Resolution::YEAR
        KnowledgeState::PARTIALLY_KNOWN
      elsif @temporal.resolution == Resolution::UNBOUNDED
        KnowledgeState::EXPLICITLY_UNKNOWN
      else
        KnowledgeState::KNOWN
      end
    end
  end


  #############################################
  ## Participant — who is involved
  ##
  ## Events often reference participants with varying identification:
  ## "We" (speaker + others), "a man", "the suspect"

  class Participant
    attr_reader :reference, :identity_state, :role

    def initialize(reference, identity_state: KnowledgeState::KNOWN, role: nil)
      @reference      = reference       # "we", "a man", "the suspect"
      @identity_state = identity_state  # do we know WHO this is?
      @role           = role            # victim, suspect, witness, participant
    end

    def to_s
      parts = [@reference]
      parts << "(#{@role})" if @role
      parts << "[identity: #{@identity_state}]" unless @identity_state == KnowledgeState::KNOWN
      parts.join(" ")
    end
  end


  #############################################
  ## Region Registry

  module Regions
    EUROPE = SpatialRegion.new(
      "Europe",
      center: SpatialPoint.new(latitude: 50.0, longitude: 10.0, label: "Central Europe"),
      radius_km: 2500,
      precision: Precision::CONTINENT
    )

    ITALY = SpatialRegion.new(
      "Italy",
      center: SpatialPoint.new(latitude: 42.5, longitude: 12.5, label: "Central Italy"),
      radius_km: 500,
      precision: Precision::COUNTRY
    )

    FRANCE = SpatialRegion.new(
      "France",
      center: SpatialPoint.new(latitude: 46.6, longitude: 2.2, label: "Central France"),
      radius_km: 500,
      precision: Precision::COUNTRY
    )

    EAST_TEXAS = SpatialRegion.new(
      "East Texas",
      center: SpatialPoint.new(latitude: 31.5, longitude: -95.0, label: "East Texas"),
      radius_km: 150,
      precision: Precision::REGION
    )

    IRAQ = SpatialRegion.new(
      "Iraq",
      center: SpatialPoint.new(latitude: 33.0, longitude: 44.0, label: "Central Iraq"),
      radius_km: 500,
      precision: Precision::COUNTRY
    )
  end

  module Seasons
    def self.spring(year, hemisphere: :northern)
      if hemisphere == :northern
        TemporalRange.new(
          Time.new(year, 3, 1), Time.new(year, 5, 31, 23, 59, 59),
          resolution: Resolution::SEASON,
          label: "spring #{year}"
        )
      else
        TemporalRange.new(
          Time.new(year, 9, 1), Time.new(year, 11, 30, 23, 59, 59),
          resolution: Resolution::SEASON,
          label: "spring #{year} (southern)"
        )
      end
    end
  end


  #############################################
  ## Examples

  def self.examples
    puts
    puts "#" * 70
    puts "# 4D SPACETIME EVENT EXAMPLES"
    puts "#" * 70
    puts

    # --- Example 1: The vacation ---
    # "We are planning to vacation in Europe sometime next spring.
    #  We don't know which countries we will be visiting other than Italy."

    europe_vacation_spatial = SpatialRegion.new(
      "Europe",
      center: SpatialPoint.new(latitude: 50.0, longitude: 10.0, label: "Europe"),
      radius_km: 2500,
      precision: Precision::CONTINENT,
      known_sub_regions: [SubRegion.new("Italy")],
      unknown_sub_regions: "other countries TBD (explicitly stated unknown)"
    )

    europe_vacation = Event.new(
      "Vacation in Europe",
      spatial: europe_vacation_spatial,
      temporal: Seasons.spring(2027),
      commitment: Commitment::TENTATIVE,
      original_text: "We are planning to vacation in Europe sometime next spring. " \
                     "We don't know which countries we will be visiting other than Italy.",
      participants: [
        Participant.new("we", role: :traveler),
      ]
    )
    puts europe_vacation
    puts

    # --- Example 2: The shooting (from earlier) ---
    # "Two blocks down the street from where I live, a man was shot on Dec 24"

    shooting_spatial = SpatialRegion.new(
      "~200m from home",
      center: SpatialPoint.new(latitude: 32.35, longitude: -95.30, label: "home vicinity"),
      radius_km: 0.2,
      precision: Precision::CITY  # using CITY as proxy for "block" in simplified model
    )

    shooting = Event.new(
      "Shooting",
      spatial: shooting_spatial,
      temporal: TemporalRange.new(
        Time.new(2025, 12, 24), Time.new(2025, 12, 24, 23, 59, 59),
        resolution: Resolution::DAY,
        label: "Dec 24, 2025"
      ),
      commitment: Commitment::FIXED,
      original_text: "Two blocks down the street from where I live, a man was shot on Dec 24",
      participants: [
        Participant.new("a man", identity_state: KnowledgeState::EXPLICITLY_UNKNOWN, role: :victim),
        Participant.new("speaker", role: :witness),
      ]
    )
    puts shooting
    puts

    # --- Example 3: Intelligence assessment ---
    # "We believe the insurgents are planning an attack somewhere in
    #  the Anbar province after Ramadan, possibly targeting the
    #  coalition base near Fallujah."

    anbar_spatial = SpatialRegion.new(
      "Anbar Province",
      center: SpatialPoint.new(latitude: 33.4, longitude: 43.3, label: "Anbar Province"),
      radius_km: 150,
      precision: Precision::REGION,
      known_sub_regions: [
        SubRegion.new("vicinity of coalition base near Fallujah")
      ],
      unknown_sub_regions: "exact location unknown"
    )

    ramadan_end = Time.new(2026, 3, 19, 23, 59, 59)
    after_ramadan = TemporalRange.new(
      ramadan_end,
      Time.new(2026, 12, 31, 23, 59, 59),  # open-ended, capped at year
      resolution: Resolution::UNBOUNDED,
      label: "after Ramadan 2026 (open-ended)"
    )

    intel_event = Event.new(
      "Planned insurgent attack",
      spatial: anbar_spatial,
      temporal: after_ramadan,
      commitment: Commitment::TENTATIVE,  # intelligence assessment
      original_text: "We believe the insurgents are planning an attack somewhere in " \
                     "the Anbar province after Ramadan, possibly targeting the " \
                     "coalition base near Fallujah.",
      participants: [
        Participant.new("insurgents", identity_state: KnowledgeState::PARTIALLY_KNOWN, role: :threat),
        Participant.new("coalition forces", role: :target),
      ]
    )
    puts intel_event
    puts

    # --- Example 4: Fully known event ---
    # "The quilt guild meets the second Thursday at the Rose Garden
    #  Center, 420 Rose Park Dr, Tyler TX 75702, from 9:30am to 11:30am"

    quilt_guild = Event.new(
      "East Texas Quilt Guild meeting",
      spatial: SpatialRegion.new(
        "Rose Garden Center",
        center: SpatialPoint.new(latitude: 32.3407, longitude: -95.2978,
                                 label: "420 Rose Park Dr, Tyler TX 75702"),
        radius_km: 0.05,
        precision: Precision::ADDRESS
      ),
      temporal: TemporalRange.new(
        Time.new(2026, 3, 12, 9, 30), Time.new(2026, 3, 12, 11, 30),
        resolution: Resolution::EXACT,
        label: "2nd Thursday, 9:30am-11:30am"
      ),
      commitment: Commitment::FIXED,
      original_text: "The quilt guild meets the second Thursday at the Rose Garden " \
                     "Center, 420 Rose Park Dr, Tyler TX, from 9:30am to 11:30am"
    )
    puts quilt_guild
    puts

    # --- Knowledge comparison ---
    puts "=" * 70
    puts "KNOWLEDGE STATE COMPARISON ACROSS EVENTS"
    puts "=" * 70
    puts

    events = {
      "Europe vacation"  => europe_vacation,
      "Shooting"         => shooting,
      "Intel assessment"  => intel_event,
      "Quilt guild"      => quilt_guild,
    }

    puts "  %-20s %-15s %-15s %-15s %-12s" % [
      "Event", "Spatial", "Temporal", "Commitment", "Actionable?"
    ]
    puts "  " + "-" * 75

    events.each do |name, event|
      spatial_k  = event.knowledge[:spatial]
      temporal_k = event.knowledge[:temporal]
      actionable = event.commitment == Commitment::FIXED ? "YES" : "no"

      puts "  %-20s %-15s %-15s %-15s %-12s" % [
        name, spatial_k, temporal_k, event.commitment, actionable
      ]
    end
    puts

    puts "=" * 70
    puts "THE KNOWLEDGE GRADIENT"
    puts "=" * 70
    puts
    puts "  Events exist on a gradient from fully known to almost entirely unknown."
    puts "  The system must represent WHERE on this gradient each dimension falls,"
    puts "  and distinguish between 'we don't have that data' (MISSING) and"
    puts "  'the source explicitly said they don't know' (EXPLICITLY_UNKNOWN)."
    puts
    puts "  Fully known:  Quilt guild — exact place, exact time, fixed"
    puts "  Mostly known: Shooting — approximate place, exact day, fixed"
    puts "  Partially:    Vacation — continent + 1 country, season, tentative"
    puts "  Mostly fuzzy: Intel — region + possible target, open-ended, tentative"
    puts
  end
end


if __FILE__ == $0
  SpaceTime.examples
end
