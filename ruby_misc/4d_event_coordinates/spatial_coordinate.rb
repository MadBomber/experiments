#!/usr/bin/env ruby
# spatial_coordinate.rb — Spatial dimension of a 4D event model
#
# Origin: JISR project (2001) — locating intelligence events in spacetime.
# "Two blocks down the street from where I live, a man was shot on Dec 24"
#
# This sentence encodes:
#   Spatial:  RelativePlace(anchor: "where I live", offset: "two blocks", direction: "down the street")
#   Temporal: Instant(Dec 24)
#   Event:    "a man was shot"
#
# Spatial coordinates, like temporal ones, can be:
#   - Absolute:  37.7749° N, 122.4194° W  (GPS fix)
#   - Relative:  "two blocks from the school"
#   - Named:     "the corner of Main and 5th"
#   - Fuzzy:     "somewhere in East Texas"
#   - Bounded:   "within city limits", "inside the compound"
#
# Status: SKETCH / EXPLORATION

require 'date'
require 'time'

module SpatialEvent

  #############################################
  ## Spatial Precision — how well do we know the location?
  ##
  ## Mirrors TemporalEvent::Resolution

  module Precision
    EXACT        = :exact         # GPS coordinates, surveyed point
    ADDRESS      = :address       # street address (resolves to ~10m)
    INTERSECTION = :intersection  # "corner of Main and 5th" (~20m)
    BLOCK        = :block         # "the 400 block of Main St" (~100m)
    NEIGHBORHOOD = :neighborhood  # "downtown", "the east side" (~1km)
    CITY         = :city          # "in Tyler, TX" (~10km)
    COUNTY       = :county        # "in Smith County" (~50km)
    REGION       = :region        # "East Texas", "the Gulf Coast" (~200km)
    STATE        = :state         # "in Texas" (~800km)
    COUNTRY      = :country       # "in Iraq" (~1000km)
    UNBOUNDED    = :unbounded     # "somewhere"
  end


  #############################################
  ## SpatialPoint — a single location in 3D space

  class SpatialPoint
    attr_reader :latitude, :longitude, :altitude, :label

    def initialize(latitude:, longitude:, altitude: nil, label: nil)
      @latitude  = latitude
      @longitude = longitude
      @altitude  = altitude   # meters above sea level, nil if unknown
      @label     = label
    end

    def to_s
      s = "%.6f, %.6f" % [@latitude, @longitude]
      s += " @ #{@altitude}m" if @altitude
      s += " (#{@label})" if @label
      s
    end

    # Haversine distance in meters to another point
    def distance_to(other)
      r = 6_371_000 # Earth radius in meters
      lat1 = @latitude * Math::PI / 180
      lat2 = other.latitude * Math::PI / 180
      dlat = (other.latitude - @latitude) * Math::PI / 180
      dlon = (other.longitude - @longitude) * Math::PI / 180

      a = Math.sin(dlat / 2)**2 +
          Math.cos(lat1) * Math.cos(lat2) * Math.sin(dlon / 2)**2
      c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
      r * c
    end

    # Bearing in degrees to another point
    def bearing_to(other)
      lat1 = @latitude * Math::PI / 180
      lat2 = other.latitude * Math::PI / 180
      dlon = (other.longitude - @longitude) * Math::PI / 180

      y = Math.sin(dlon) * Math.cos(lat2)
      x = Math.cos(lat1) * Math.sin(lat2) -
          Math.sin(lat1) * Math.cos(lat2) * Math.cos(dlon)

      bearing = Math.atan2(y, x) * 180 / Math::PI
      (bearing + 360) % 360
    end

    # Create a new point offset by distance and bearing
    def offset(distance_m:, bearing_deg:)
      r = 6_371_000.0
      lat1 = @latitude * Math::PI / 180
      lon1 = @longitude * Math::PI / 180
      brng = bearing_deg * Math::PI / 180
      d = distance_m / r

      lat2 = Math.asin(
        Math.sin(lat1) * Math.cos(d) +
        Math.cos(lat1) * Math.sin(d) * Math.cos(brng)
      )
      lon2 = lon1 + Math.atan2(
        Math.sin(brng) * Math.sin(d) * Math.cos(lat1),
        Math.cos(d) - Math.sin(lat1) * Math.sin(lat2)
      )

      SpatialPoint.new(
        latitude: lat2 * 180 / Math::PI,
        longitude: lon2 * 180 / Math::PI,
        altitude: @altitude
      )
    end
  end


  #############################################
  ## SpatialRange — an area or volume
  ##
  ## Can be defined as:
  ##   - Bounding box (two corners)
  ##   - Center + radius (circle/sphere)
  ##   - Polygon (future)
  ##
  ## Mirrors TemporalRange

  class SpatialRange
    attr_reader :center, :radius_m, :bounds, :precision, :label

    # Circle/sphere definition
    def self.from_radius(center, radius_m, precision:, label: nil)
      new(center: center, radius_m: radius_m, precision: precision, label: label)
    end

    # Bounding box definition
    def self.from_bounds(sw_corner, ne_corner, precision:, label: nil)
      center_lat = (sw_corner.latitude + ne_corner.latitude) / 2.0
      center_lon = (sw_corner.longitude + ne_corner.longitude) / 2.0
      center = SpatialPoint.new(latitude: center_lat, longitude: center_lon)
      radius = center.distance_to(ne_corner)
      new(center: center, radius_m: radius, bounds: [sw_corner, ne_corner],
          precision: precision, label: label)
    end

    def initialize(center:, radius_m: nil, bounds: nil, precision:, label: nil)
      @center    = center
      @radius_m  = radius_m
      @bounds    = bounds
      @precision = precision
      @label     = label
    end

    def contains?(point)
      @center.distance_to(point) <= (@radius_m || Float::INFINITY)
    end

    def to_s
      if @label
        "#{@label} (#{precision}, ~#{human_radius})"
      else
        "#{@center} ± #{human_radius}"
      end
    end

    private

    def human_radius
      return "?" unless @radius_m
      if @radius_m >= 1000
        "%.1f km" % (@radius_m / 1000.0)
      else
        "#{@radius_m.round} m"
      end
    end
  end


  #############################################
  ## Named Place — "where I live", "the school", "the mosque"
  ##
  ## Mirrors TemporalEvent::NamedAnchor
  ##
  ## Resolves via a place registry (personal, local, global)

  class NamedPlace
    attr_reader :name

    def initialize(name)
      @name = name.downcase.strip
    end

    def resolve(registry:)
      registry.find(@name)
    end

    def to_s = @name
  end


  #############################################
  ## Place Registry — maps names to spatial coordinates
  ##
  ## Three tiers:
  ##   Personal: "home", "work", "mom's house"
  ##   Local:    "the school", "the corner store", landmarks
  ##   Global:   cities, countries, well-known places

  class PlaceRegistry
    def initialize
      @places = {}
    end

    def register(name, spatial_ref)
      @places[name.downcase.strip] = spatial_ref
    end

    def find(name)
      @places[name.downcase.strip]
    end

    def known?(name)
      @places.key?(name.downcase.strip)
    end

    # Load a set of well-known places
    def load_defaults!
      # Some well-known reference points
      {
        "mecca"      => SpatialPoint.new(latitude: 21.4225, longitude: 39.8262, label: "Mecca"),
        "jerusalem"  => SpatialPoint.new(latitude: 31.7683, longitude: 35.2137, label: "Jerusalem"),
        "washington" => SpatialPoint.new(latitude: 38.9072, longitude: -77.0369, label: "Washington DC"),
        "baghdad"    => SpatialPoint.new(latitude: 33.3152, longitude: 44.3661, label: "Baghdad"),
        "kabul"      => SpatialPoint.new(latitude: 34.5553, longitude: 69.2075, label: "Kabul"),
        "tyler tx"   => SpatialPoint.new(latitude: 32.3513, longitude: -95.3011, label: "Tyler, TX"),
      }.each { |name, point| register(name, point) }
      self
    end
  end


  #############################################
  ## Relative Place — spatial offset from an anchor
  ##
  ## "two blocks down the street from where I live"
  ##   anchor:    NamedPlace("where I live")
  ##   offset:    2 blocks (~200m)
  ##   direction: "down the street" (bearing from context, or fuzzy)
  ##
  ## Mirrors TemporalEvent::RelativeAnchor

  class RelativePlace
    attr_reader :anchor, :distance, :direction, :precision

    # Distance units that appear in natural language
    DISTANCE_UNITS = {
      'block'      => 100,    # ~100m per city block (varies wildly)
      'blocks'     => 100,
      'meter'      => 1,
      'meters'     => 1,
      'm'          => 1,
      'kilometer'  => 1000,
      'kilometers' => 1000,
      'km'         => 1000,
      'mile'       => 1609,
      'miles'      => 1609,
      'yard'       => 0.9144,
      'yards'      => 0.9144,
      'foot'       => 0.3048,
      'feet'       => 0.3048,
    }

    # Directional references — some are compass bearings, some are contextual
    DIRECTIONS = {
      'north'     => 0,
      'northeast' => 45,
      'east'      => 90,
      'southeast' => 135,
      'south'     => 180,
      'southwest' => 225,
      'west'      => 270,
      'northwest' => 315,

      # Contextual — these require additional context to resolve
      # to a bearing. "down the street" depends on which street
      # and which direction is "down". We represent them as nil
      # and resolve to a fuzzy area instead of a point.
      'down the street'  => nil,
      'up the street'    => nil,
      'across the street'=> nil,
      'around the corner'=> nil,
      'nearby'           => nil,
      'next door'        => nil,
    }

    def initialize(anchor:, distance_m:, direction: nil, precision: Precision::BLOCK)
      @anchor     = anchor    # NamedPlace or SpatialPoint
      @distance   = distance_m
      @direction  = direction # bearing in degrees, or nil for fuzzy
      @precision  = precision
    end

    def resolve(registry: nil)
      base = case @anchor
             when NamedPlace then @anchor.resolve(registry: registry)
             when SpatialPoint then @anchor
             when SpatialRange then @anchor.center
             else raise "Cannot resolve anchor: #{@anchor.class}"
             end

      if @direction
        # Known direction: compute offset point
        point = base.offset(distance_m: @distance, bearing_deg: @direction)
        SpatialRange.from_radius(
          point, [@distance * 0.2, 50].max,  # uncertainty proportional to distance
          precision: @precision,
          label: "#{@distance.round}m #{compass_name(@direction)} of #{base.label || base}"
        )
      else
        # Unknown direction: create a ring/circle at the given distance
        # We know HOW FAR but not WHICH DIRECTION — so the result is
        # a ring around the anchor point
        SpatialRange.from_radius(
          base, @distance,
          precision: @precision,
          label: "~#{@distance.round}m from #{base.label || base}"
        )
      end
    end

    private

    def compass_name(bearing)
      names = %w[N NNE NE ENE E ESE SE SSE S SSW SW WSW W WNW NW NNW]
      index = ((bearing + 11.25) / 22.5).floor % 16
      names[index]
    end
  end


  #############################################
  ## Fuzzy spatial references
  ##
  ## "somewhere in East Texas"
  ## "in the neighborhood"
  ## "within city limits"
  ## "inside the compound"

  module FuzzyRegions
    REGIONS = {
      "east texas" => {
        center: [31.5, -95.0],
        radius_km: 150,
        precision: Precision::REGION
      },
      "west texas" => {
        center: [31.5, -103.0],
        radius_km: 250,
        precision: Precision::REGION
      },
      "the gulf coast" => {
        center: [29.5, -94.5],
        radius_km: 200,
        precision: Precision::REGION
      },
      "the green zone" => {
        center: [33.3, 44.39],
        radius_km: 2,
        precision: Precision::NEIGHBORHOOD
      },
      "the triangle of death" => {
        center: [32.8, 44.0],
        radius_km: 30,
        precision: Precision::COUNTY
      },
    }

    def self.resolve(name)
      spec = REGIONS[name.downcase.strip]
      return nil unless spec

      center = SpatialPoint.new(
        latitude: spec[:center][0],
        longitude: spec[:center][1],
        label: name
      )
      SpatialRange.from_radius(
        center, spec[:radius_km] * 1000,
        precision: spec[:precision],
        label: name
      )
    end
  end


  #############################################
  ## Altitude / Vertical references
  ##
  ## "on the third floor"
  ## "in the basement"
  ## "on the roof"
  ## "underground"
  ## "at ground level"
  ## "at 30,000 feet" (aviation)

  module VerticalRef
    NAMED_LEVELS = {
      'underground'  => { min: -50, max: 0 },
      'basement'     => { min: -10, max: 0 },
      'ground level' => { min: 0,   max: 3 },
      'ground floor' => { min: 0,   max: 3 },
      'street level' => { min: 0,   max: 3 },
      'rooftop'      => nil,  # depends on building height
      'roof'         => nil,
    }

    # Approximate floor-to-meters conversion
    # Standard commercial floor height is ~3.5-4m
    FLOOR_HEIGHT_M = 3.5

    def self.floor_to_altitude(floor_number, ground_altitude: 0)
      ground_altitude + (floor_number - 1) * FLOOR_HEIGHT_M
    end
  end


  #############################################
  ## The Full 4D Event

  class SpaceTimeEvent
    attr_reader :description, :spatial, :temporal, :commitment, :original_text

    def initialize(description, spatial:, temporal:, commitment: :fixed, original_text: nil)
      @description   = description
      @spatial       = spatial   # SpatialPoint, SpatialRange, or RelativePlace
      @temporal      = temporal  # Instant, TemporalRange, Recurrence, etc.
      @commitment    = commitment
      @original_text = original_text
    end

    def to_s
      parts = ["Event: #{@description}"]
      parts << "  When:  #{@temporal}"
      parts << "  Where: #{@spatial}"
      parts << "  Commitment: #{@commitment}"
      parts << "  Spatial precision: #{@spatial.precision}" if @spatial.respond_to?(:precision)
      parts.join("\n")
    end
  end


  #############################################
  ## Examples

  def self.examples
    registry = PlaceRegistry.new.load_defaults!
    registry.register("home", SpatialPoint.new(
      latitude: 32.35, longitude: -95.30, label: "home (Tyler, TX)"
    ))
    registry.register("where I live", SpatialPoint.new(
      latitude: 32.35, longitude: -95.30, label: "home (Tyler, TX)"
    ))
    registry.register("the mosque", SpatialPoint.new(
      latitude: 33.32, longitude: 44.37, label: "the mosque"
    ))

    puts "=" * 70
    puts "4D EVENT MODEL — SPATIAL + TEMPORAL"
    puts "=" * 70
    puts

    # --- Example 1: Relative spatial + absolute temporal ---
    puts '--- "Two blocks down the street from where I live, a man was shot on Dec 24" ---'
    puts

    anchor = NamedPlace.new("where I live")
    relative = RelativePlace.new(
      anchor: anchor.resolve(registry: registry),
      distance_m: 200,    # 2 blocks
      direction: nil,     # "down the street" — direction unknown
      precision: Precision::BLOCK
    )
    resolved_place = relative.resolve(registry: registry)

    event1 = SpaceTimeEvent.new(
      "Man was shot",
      spatial: resolved_place,
      temporal: Time.new(2025, 12, 24),
      commitment: :fixed,
      original_text: "Two blocks down the street from where I live, a man was shot on Dec 24"
    )
    puts event1
    puts

    # --- Example 2: Named place + fuzzy temporal ---
    puts '--- "Expect an attack on the mosque after Ramadan" ---'
    puts

    mosque = NamedPlace.new("the mosque")
    mosque_loc = mosque.resolve(registry: registry)
    # "after Ramadan" — temporal range with known start, open end
    ramadan_end = Time.new(2026, 3, 19)

    event2 = SpaceTimeEvent.new(
      "Expected attack",
      spatial: SpatialRange.from_radius(
        mosque_loc, 500,
        precision: Precision::BLOCK,
        label: "vicinity of the mosque"
      ),
      temporal: "after #{ramadan_end.strftime('%Y-%m-%d')} (open-ended)",
      commitment: :tentative,  # intelligence assessment, not confirmed
      original_text: "Expect an attack on the mosque after Ramadan"
    )
    puts event2
    puts

    # --- Example 3: Fuzzy spatial + specific temporal ---
    puts '--- "IED found on Route Tampa near Fallujah, 0530 local" ---'
    puts

    fallujah = SpatialPoint.new(latitude: 33.35, longitude: 43.78, label: "Fallujah")
    route_tampa_area = SpatialRange.from_radius(
      fallujah, 15_000,
      precision: Precision::COUNTY,
      label: "Route Tampa near Fallujah"
    )

    event3 = SpaceTimeEvent.new(
      "IED found",
      spatial: route_tampa_area,
      temporal: Time.new(2026, 3, 6, 5, 30),
      commitment: :fixed,
      original_text: "IED found on Route Tampa near Fallujah, 0530 local"
    )
    puts event3
    puts

    # --- Example 4: Relative spatial with compass direction ---
    puts '--- "Sniper fire from 300 meters north of the checkpoint" ---'
    puts

    checkpoint = SpatialPoint.new(latitude: 33.30, longitude: 44.40, label: "the checkpoint")
    sniper_pos = RelativePlace.new(
      anchor: checkpoint,
      distance_m: 300,
      direction: 0,   # north
      precision: Precision::BLOCK
    )
    resolved_sniper = sniper_pos.resolve

    event4 = SpaceTimeEvent.new(
      "Sniper fire",
      spatial: resolved_sniper,
      temporal: Time.new(2026, 3, 5, 14, 15),
      commitment: :fixed,
      original_text: "Sniper fire from 300 meters north of the checkpoint"
    )
    puts event4
    puts

    # --- Example 5: Altitude matters ---
    puts '--- "Shots fired from the third floor of the building at the corner of Haifa and 14th" ---'
    puts

    building = SpatialPoint.new(
      latitude: 33.315, longitude: 44.395,
      altitude: VerticalRef.floor_to_altitude(3, ground_altitude: 34),
      label: "building at Haifa & 14th, 3rd floor"
    )

    event5 = SpaceTimeEvent.new(
      "Shots fired",
      spatial: SpatialRange.from_radius(
        building, 20,
        precision: Precision::ADDRESS,
        label: "3rd floor, building at Haifa & 14th"
      ),
      temporal: Time.now,
      commitment: :fixed,
      original_text: "Shots fired from the third floor of the building at the corner of Haifa and 14th"
    )
    puts event5
    puts

    # --- Distance and bearing demo ---
    puts "=" * 70
    puts "SPATIAL COMPUTATIONS"
    puts "=" * 70
    puts

    home = registry.find("home")
    tyler = registry.find("tyler tx")
    baghdad = registry.find("baghdad")
    mecca = registry.find("mecca")

    puts "Home to Tyler:    %.1f km, bearing %.0f°" % [home.distance_to(tyler) / 1000, home.bearing_to(tyler)]
    puts "Baghdad to Mecca: %.1f km, bearing %.0f°" % [baghdad.distance_to(mecca) / 1000, baghdad.bearing_to(mecca)]
    puts "Tyler to Baghdad: %.1f km, bearing %.0f°" % [tyler.distance_to(baghdad) / 1000, tyler.bearing_to(baghdad)]
    puts

    # --- Precision hierarchy ---
    puts "=" * 70
    puts "SPATIAL PRECISION HIERARCHY"
    puts "=" * 70
    puts

    precisions = [
      [Precision::EXACT,        "GPS fix",                      "~1m"],
      [Precision::ADDRESS,      "123 Main St",                  "~10m"],
      [Precision::INTERSECTION, "corner of Main and 5th",       "~20m"],
      [Precision::BLOCK,        "the 400 block of Main St",     "~100m"],
      [Precision::NEIGHBORHOOD, "downtown",                     "~1km"],
      [Precision::CITY,         "in Tyler, TX",                 "~10km"],
      [Precision::COUNTY,       "in Smith County",              "~50km"],
      [Precision::REGION,       "East Texas",                   "~200km"],
      [Precision::STATE,        "in Texas",                     "~800km"],
      [Precision::COUNTRY,      "in Iraq",                      "~1000km"],
      [Precision::UNBOUNDED,    "somewhere",                    "∞"],
    ]

    precisions.each do |level, example, radius|
      puts "  %-14s %-35s %s" % [level, example, radius]
    end
  end
end


if __FILE__ == $0
  SpatialEvent.examples
end
