#!/usr/bin/env ruby
# dimensional_attributes.rb — Event attributes as coordinate dimensions
#
# Beyond space (3D) and time (1D), events have attributes that behave
# like coordinates in additional dimensions:
#
#   - Electromagnetic spectrum (frequency, wavelength, band)
#   - Acoustic spectrum (frequency, amplitude)
#   - Network/cyber space (IP address, port, protocol)
#   - Chemical composition (substance, concentration)
#   - Financial (amount, currency, account)
#
# Each follows the same patterns as spatial and temporal coordinates:
#   - Points or ranges
#   - Named references ("X-band", "channel 5", "port 443")
#   - Relative references ("adjacent channel", "harmonic")
#   - Precision/resolution
#   - Knowledge states
#
# SIGINT example:
#   "Frequencies 2.5 GHz and 3 GHz became active between 4am and 4:30am
#    yesterday. These signals were observed by listening station Bravo at
#    a bearing of 32.5 degrees and station Zed at a bearing of 12.6 degrees."
#
# This encodes:
#   Spectral:  [2.5 GHz, 3.0 GHz] — two points in EM spectrum
#   Temporal:  4:00am-4:30am yesterday — range
#   Spatial:   triangulated from two bearing observations
#   State:     "became active" — transition from inactive to active
#   Observers: Station Bravo and Station Zed (known positions)
#
# Status: SKETCH / EXPLORATION

require 'date'
require 'time'

module EventDimensions

  #############################################
  ## Generic Dimensional Coordinate
  ##
  ## The abstract pattern that ALL coordinate types follow.
  ## Space, time, frequency, etc. are all specializations.

  module CoordinatePattern
    # Every coordinate type supports:
    #   - Point:     a single value in the dimension
    #   - Range:     a span between two values
    #   - Named:     a human reference that resolves to a point or range
    #   - Relative:  offset from another coordinate
    #   - Precision: how well do we know the value
    #   - Knowledge: known / partially_known / explicitly_unknown / missing
  end

  module KnowledgeState
    KNOWN              = :known
    PARTIALLY_KNOWN    = :partially_known
    EXPLICITLY_UNKNOWN = :explicitly_unknown
    MISSING            = :missing
  end


  #############################################
  ## Spectral Coordinate — location in the EM spectrum
  ##
  ## A frequency is to the EM spectrum what a latitude is to
  ## the Earth's surface. "2.5 GHz" is an address.

  class SpectralPoint
    attr_reader :frequency_hz, :label

    def initialize(frequency_hz, label: nil)
      @frequency_hz = frequency_hz.to_f
      @label = label
    end

    def frequency_ghz = @frequency_hz / 1e9
    def frequency_mhz = @frequency_hz / 1e6
    def wavelength_m  = 299_792_458.0 / @frequency_hz

    def to_s
      if @frequency_hz >= 1e9
        "%.3f GHz" % frequency_ghz
      elsif @frequency_hz >= 1e6
        "%.3f MHz" % frequency_mhz
      elsif @frequency_hz >= 1e3
        "%.1f kHz" % (@frequency_hz / 1e3)
      else
        "%.1f Hz" % @frequency_hz
      end + (@label ? " (#{@label})" : "")
    end
  end

  class SpectralRange
    attr_reader :low, :high, :label, :precision

    def initialize(low_hz, high_hz, label: nil, precision: :exact)
      @low       = low_hz.to_f
      @high      = high_hz.to_f
      @label     = label
      @precision = precision
    end

    def bandwidth_hz = @high - @low
    def center_hz    = (@low + @high) / 2.0

    def contains?(freq_hz)
      freq_hz >= @low && freq_hz <= @high
    end

    def to_s
      lo = SpectralPoint.new(@low)
      hi = SpectralPoint.new(@high)
      s = "#{lo}..#{hi}"
      s += " (#{@label})" if @label
      s
    end
  end

  # Named spectral references — like NamedAnchor for time
  module SpectralBands
    # IEEE radar band designations
    BANDS = {
      'HF'  => [3e6,    30e6,   "High Frequency"],
      'VHF' => [30e6,   300e6,  "Very High Frequency"],
      'UHF' => [300e6,  1e9,    "Ultra High Frequency"],
      'L'   => [1e9,    2e9,    "L-band"],
      'S'   => [2e9,    4e9,    "S-band"],
      'C'   => [4e9,    8e9,    "C-band"],
      'X'   => [8e9,    12e9,   "X-band"],
      'Ku'  => [12e9,   18e9,   "Ku-band"],
      'K'   => [18e9,   27e9,   "K-band"],
      'Ka'  => [27e9,   40e9,   "Ka-band"],
      'V'   => [40e9,   75e9,   "V-band"],
      'W'   => [75e9,   110e9,  "W-band"],
    }

    # Common system frequencies
    KNOWN_SYSTEMS = {
      'wifi 2.4'    => [2.4e9,   2.4835e9, "WiFi 2.4 GHz"],
      'wifi 5'      => [5.15e9,  5.825e9,  "WiFi 5 GHz"],
      'gps l1'      => [1.57542e9, 1.57542e9, "GPS L1"],
      'gps l2'      => [1.2276e9, 1.2276e9, "GPS L2"],
      'cell lte'    => [700e6,   2.7e9,    "LTE cellular"],
      'fm radio'    => [87.5e6,  108e6,    "FM broadcast"],
      'am radio'    => [535e3,   1.605e6,  "AM broadcast"],
    }

    # Radar threat systems (illustrative, not classified)
    THREAT_SYSTEMS = {
      'early warning radar'   => [200e6,   450e6,  "Early warning / surveillance"],
      'acquisition radar'     => [2e9,     4e9,    "Target acquisition (S-band)"],
      'fire control radar'    => [8e9,     12e9,   "Fire control (X-band)"],
      'missile seeker'        => [12e9,    18e9,   "Missile seeker (Ku-band)"],
      'tracking radar'        => [8e9,     18e9,   "Tracking (X/Ku-band)"],
    }

    def self.resolve(name)
      name = name.downcase.strip
      spec = BANDS[name] || BANDS[name.upcase] || KNOWN_SYSTEMS[name] || THREAT_SYSTEMS[name]
      return nil unless spec
      SpectralRange.new(spec[0], spec[1], label: spec[2])
    end
  end


  #############################################
  ## Bearing Observation — a line from a known point
  ##
  ## A single bearing gives you a LINE (infinite ray from the observer).
  ## Two bearings from different observers give you a POINT (intersection).
  ## The intersection has uncertainty proportional to the angle between
  ## the bearings and distance from the observers.

  class SpatialPoint
    attr_reader :latitude, :longitude, :label

    def initialize(latitude:, longitude:, label: nil)
      @latitude  = latitude
      @longitude = longitude
      @label     = label
    end

    def to_s = @label || "%.4f, %.4f" % [@latitude, @longitude]
  end

  class BearingObservation
    attr_reader :observer, :bearing_deg, :timestamp, :uncertainty_deg

    def initialize(observer:, bearing_deg:, timestamp: nil, uncertainty_deg: 2.0)
      @observer        = observer        # SpatialPoint of the listening station
      @bearing_deg     = bearing_deg     # degrees from true north
      @timestamp       = timestamp
      @uncertainty_deg = uncertainty_deg # angular uncertainty
    end

    # Project a point along this bearing at a given distance
    def point_at_distance(distance_m)
      r = 6_371_000.0
      lat1 = @observer.latitude * Math::PI / 180
      lon1 = @observer.longitude * Math::PI / 180
      brng = @bearing_deg * Math::PI / 180
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
        longitude: lon2 * 180 / Math::PI
      )
    end

    def to_s
      "#{@observer.label || @observer}: bearing #{@bearing_deg}° (±#{@uncertainty_deg}°)"
    end
  end

  # Triangulate from two or more bearing observations
  module Triangulation
    # Two-bearing triangulation using line intersection
    # Returns estimated position and uncertainty radius
    def self.from_bearings(obs_a, obs_b)
      # Convert to radians
      lat_a = obs_a.observer.latitude * Math::PI / 180
      lon_a = obs_a.observer.longitude * Math::PI / 180
      lat_b = obs_b.observer.latitude * Math::PI / 180
      lon_b = obs_b.observer.longitude * Math::PI / 180
      brng_a = obs_a.bearing_deg * Math::PI / 180
      brng_b = obs_b.bearing_deg * Math::PI / 180

      dlat = lat_b - lat_a
      dlon = lon_b - lon_a

      # Angular distance between stations
      dist_12 = 2 * Math.asin(Math.sqrt(
        Math.sin(dlat / 2)**2 +
        Math.cos(lat_a) * Math.cos(lat_b) * Math.sin(dlon / 2)**2
      ))

      return nil if dist_12.abs < 1e-10  # stations too close

      # Initial/final bearings between stations
      theta_a = Math.acos(
        (Math.sin(lat_b) - Math.sin(lat_a) * Math.cos(dist_12)) /
        (Math.sin(dist_12) * Math.cos(lat_a))
      ) rescue 0
      theta_b = Math.acos(
        (Math.sin(lat_a) - Math.sin(lat_b) * Math.cos(dist_12)) /
        (Math.sin(dist_12) * Math.cos(lat_b))
      ) rescue 0

      if Math.sin(lon_b - lon_a) > 0
        theta_12 = theta_a
        theta_21 = 2 * Math::PI - theta_b
      else
        theta_12 = 2 * Math::PI - theta_a
        theta_21 = theta_b
      end

      alpha_1 = brng_a - theta_12
      alpha_2 = theta_21 - brng_b

      sin_sum = Math.sin(alpha_1) + Math.sin(alpha_2)
      return nil if sin_sum.abs < 1e-10  # parallel bearings

      alpha_3 = Math.acos(
        -Math.cos(alpha_1) * Math.cos(alpha_2) +
        Math.sin(alpha_1) * Math.sin(alpha_2) * Math.cos(dist_12)
      )
      dist_13 = Math.atan2(
        Math.sin(dist_12) * Math.sin(alpha_1) * Math.sin(alpha_2),
        Math.cos(alpha_2) + Math.cos(alpha_1) * Math.cos(alpha_3)
      )

      lat_3 = Math.asin(
        Math.sin(lat_a) * Math.cos(dist_13) +
        Math.cos(lat_a) * Math.sin(dist_13) * Math.cos(brng_a)
      )
      lon_3 = lon_a + Math.atan2(
        Math.sin(brng_a) * Math.sin(dist_13) * Math.cos(lat_a),
        Math.cos(dist_13) - Math.sin(lat_a) * Math.sin(lat_3)
      )

      result_point = SpatialPoint.new(
        latitude: lat_3 * 180 / Math::PI,
        longitude: lon_3 * 180 / Math::PI,
        label: "triangulated position"
      )

      # Uncertainty: function of bearing angle intersection and observer uncertainty
      bearing_angle = ((obs_a.bearing_deg - obs_b.bearing_deg).abs % 180)
      bearing_angle = 180 - bearing_angle if bearing_angle > 90

      # Optimal triangulation is at 90°; uncertainty grows as angle decreases
      angle_factor = [1.0 / Math.sin(bearing_angle * Math::PI / 180), 10.0].min
      base_uncertainty = (obs_a.uncertainty_deg + obs_b.uncertainty_deg) / 2.0

      # Distance from observers affects uncertainty
      dist_a = obs_a.observer.latitude  # rough proxy; real impl uses haversine
      uncertainty_m = (base_uncertainty * angle_factor * 1000).round

      {
        position: result_point,
        uncertainty_m: uncertainty_m,
        bearing_angle: bearing_angle,
        quality: bearing_angle > 60 ? :good : bearing_angle > 30 ? :fair : :poor
      }
    end
  end


  #############################################
  ## Signal Event — an observation in spectral + spatial + temporal space

  class SignalEvent
    attr_reader :frequencies, :temporal, :observations,
                :signal_type, :state_change, :description

    def initialize(
      frequencies:,      # Array of SpectralPoint or SpectralRange
      temporal:,          # Hash with :earliest, :latest
      observations: [],   # Array of BearingObservation
      signal_type: nil,   # :radar, :comms, :beacon, :jammer, :unknown
      state_change: nil,  # :activated, :deactivated, :shifted, :modulated
      description: nil
    )
      @frequencies  = Array(frequencies)
      @temporal     = temporal
      @observations = observations
      @signal_type  = signal_type
      @state_change = state_change
      @description  = description
    end

    def triangulated_position
      return nil if @observations.length < 2
      Triangulation.from_bearings(@observations[0], @observations[1])
    end

    def spectral_bands
      @frequencies.map do |f|
        freq = f.is_a?(SpectralPoint) ? f.frequency_hz : f.center_hz
        SpectralBands::BANDS.each do |name, (low, high, _)|
          return name if freq >= low && freq <= high
        end
        "unknown"
      end
    end

    def to_s
      lines = []
      lines << "SIGNAL EVENT: #{@description || 'Unknown signal'}"
      lines << "-" * 60

      lines << "SPECTRAL:"
      @frequencies.each { |f| lines << "  #{f}" }
      bands = @frequencies.map { |f|
        hz = f.is_a?(SpectralPoint) ? f.frequency_hz : f.center_hz
        SpectralBands::BANDS.find { |_, (lo, hi, _)| hz >= lo && hz <= hi }&.first || "?"
      }
      lines << "  Bands: #{bands.join(', ')}"

      lines << "TEMPORAL:"
      lines << "  #{@temporal[:earliest].strftime('%Y-%m-%d %H:%M')} to #{@temporal[:latest].strftime('%Y-%m-%d %H:%M')}"

      if @state_change
        lines << "STATE: #{@state_change}"
      end

      lines << "OBSERVATIONS:"
      @observations.each { |o| lines << "  #{o}" }

      tri = triangulated_position
      if tri
        lines << "TRIANGULATED POSITION:"
        lines << "  #{tri[:position]}"
        lines << "  Uncertainty: ~#{tri[:uncertainty_m]}m"
        lines << "  Bearing intersection angle: #{tri[:bearing_angle].round(1)}°"
        lines << "  Fix quality: #{tri[:quality]}"
      end

      lines.join("\n")
    end
  end


  #############################################
  ## Additional Dimensional Types
  ##
  ## The same coordinate pattern applies to many domains:

  # Cyber/Network space — IP addresses, ports, protocols
  class NetworkCoordinate
    attr_reader :ip_address, :port, :protocol, :label

    def initialize(ip_address: nil, port: nil, protocol: nil, label: nil)
      @ip_address = ip_address   # "192.168.1.1" or CIDR "10.0.0.0/8"
      @port       = port         # integer or range (1024..65535)
      @protocol   = protocol     # :tcp, :udp, :icmp, :http, :dns
      @label      = label
    end

    def to_s
      parts = []
      parts << @protocol.to_s.upcase if @protocol
      parts << @ip_address if @ip_address
      parts << ":#{@port}" if @port
      parts << "(#{@label})" if @label
      parts.join(" ")
    end
  end

  # Acoustic space — sound frequency and amplitude
  class AcousticCoordinate
    attr_reader :frequency_hz, :amplitude_db, :label

    def initialize(frequency_hz: nil, amplitude_db: nil, label: nil)
      @frequency_hz = frequency_hz
      @amplitude_db = amplitude_db
      @label        = label
    end

    def to_s
      parts = []
      parts << "#{@frequency_hz} Hz" if @frequency_hz
      parts << "#{@amplitude_db} dB" if @amplitude_db
      parts << "(#{@label})" if @label
      parts.join(" ")
    end
  end

  # Chemical/Environmental — substance and concentration
  class ChemicalCoordinate
    attr_reader :substance, :concentration, :unit, :label

    def initialize(substance:, concentration: nil, unit: nil, label: nil)
      @substance     = substance      # "sarin", "chlorine", "CO2"
      @concentration = concentration  # numeric value
      @unit          = unit           # "ppm", "mg/m³", "percent"
      @label         = label
    end

    def to_s
      parts = [@substance]
      parts << "#{@concentration} #{@unit}" if @concentration
      parts << "(#{@label})" if @label
      parts.join(" ")
    end
  end


  #############################################
  ## N-Dimensional Event — the general model

  class NDimensionalEvent
    attr_reader :description, :dimensions, :commitment, :knowledge,
                :observers, :original_text

    def initialize(description, dimensions: {}, commitment: :fixed,
                   observers: [], original_text: nil)
      @description   = description
      @dimensions    = dimensions    # { temporal: ..., spatial: ..., spectral: ..., ... }
      @commitment    = commitment
      @observers     = observers
      @original_text = original_text

      @knowledge = dimensions.transform_values { |v| v ? KnowledgeState::KNOWN : KnowledgeState::MISSING }
    end

    def dimension_names = @dimensions.keys
    def has_dimension?(name) = @dimensions.key?(name) && !@dimensions[name].nil?

    def to_s
      lines = []
      lines << "=" * 70
      lines << "N-DIMENSIONAL EVENT: #{@description}"
      lines << "=" * 70

      if @original_text
        lines << ""
        lines << "Source: \"#{@original_text}\""
      end

      lines << ""
      lines << "Commitment: #{@commitment}"
      lines << "Dimensions: #{dimension_names.join(', ')}"
      lines << ""

      @dimensions.each do |name, value|
        lines << "#{name.to_s.upcase}:"
        if value
          value.to_s.split("\n").each { |l| lines << "  #{l}" }
        else
          lines << "  — (missing)"
        end
        lines << ""
      end

      if @observers.any?
        lines << "OBSERVERS:"
        @observers.each { |o| lines << "  #{o}" }
        lines << ""
      end

      lines.join("\n")
    end
  end


  #############################################
  ## Examples

  def self.examples
    puts
    puts "#" * 70
    puts "# N-DIMENSIONAL EVENT COORDINATES"
    puts "#" * 70
    puts

    # --- The SIGINT example ---
    puts '--- SIGINT: "Frequencies 2.5 GHz and 3 GHz became active between'
    puts '    4am and 4:30am yesterday. Observed by station Bravo at 32.5°'
    puts '    and station Zed at 12.6°." ---'
    puts

    yesterday = Date.today - 1

    station_bravo = SpatialPoint.new(
      latitude: 33.50, longitude: 44.20,
      label: "Station Bravo"
    )
    station_zed = SpatialPoint.new(
      latitude: 33.10, longitude: 44.80,
      label: "Station Zed"
    )

    signal = SignalEvent.new(
      frequencies: [
        SpectralPoint.new(2.5e9, label: "Signal Alpha"),
        SpectralPoint.new(3.0e9, label: "Signal Beta"),
      ],
      temporal: {
        earliest: Time.new(yesterday.year, yesterday.month, yesterday.day, 4, 0),
        latest:   Time.new(yesterday.year, yesterday.month, yesterday.day, 4, 30),
      },
      observations: [
        BearingObservation.new(
          observer: station_bravo,
          bearing_deg: 32.5,
          uncertainty_deg: 1.5
        ),
        BearingObservation.new(
          observer: station_zed,
          bearing_deg: 12.6,
          uncertainty_deg: 2.0
        ),
      ],
      signal_type: :unknown,
      state_change: :activated,
      description: "Unidentified S-band signals"
    )
    puts signal
    puts

    # --- Spectral band lookup ---
    puts "--- Named Spectral References ---"
    puts
    ["S", "X", "Ka", "wifi 2.4", "gps l1", "fire control radar"].each do |name|
      band = SpectralBands.resolve(name)
      puts "  %-22s → %s" % [name, band || "not found"]
    end
    puts

    # --- N-Dimensional Event: Full SIGINT report ---
    tri = signal.triangulated_position

    sigint_event = NDimensionalEvent.new(
      "Unidentified S-band emissions",
      dimensions: {
        temporal: "#{signal.temporal[:earliest].strftime('%H:%M')}-#{signal.temporal[:latest].strftime('%H:%M')} #{yesterday}",
        spatial: tri ? "#{tri[:position]} (±#{tri[:uncertainty_m]}m, #{tri[:quality]} fix)" : "bearings only",
        spectral: signal.frequencies.map(&:to_s).join(", "),
        signal_type: signal.signal_type,
        state_change: signal.state_change,
      },
      commitment: :fixed,  # observed fact
      observers: [station_bravo.label, station_zed.label],
      original_text: "Frequencies 2.5 GHz and 3 GHz became active between 4am and " \
                     "4:30am yesterday. Observed by station Bravo at bearing 32.5° " \
                     "and station Zed at bearing 12.6°."
    )
    puts sigint_event
    puts

    # --- Cyber event ---
    puts "--- Cyber Event ---"
    puts
    cyber_event = NDimensionalEvent.new(
      "Suspected exfiltration attempt",
      dimensions: {
        temporal: "2026-03-05 02:15:00 to 02:47:00 UTC",
        spatial: "Server room B, Building 4, Fort Meade",
        network: NetworkCoordinate.new(
          ip_address: "10.45.12.0/24",
          port: 443,
          protocol: :https,
          label: "outbound encrypted traffic"
        ),
        spectral: nil,  # not applicable
        data_volume: "2.3 GB outbound (anomalous for this time window)",
      },
      commitment: :fixed,
      original_text: "Anomalous 2.3GB outbound HTTPS traffic from subnet 10.45.12.0/24 " \
                     "to external IP between 0215-0247 UTC"
    )
    puts cyber_event

    # --- Chemical detection ---
    puts "--- CBRN Event ---"
    puts
    cbrn_event = NDimensionalEvent.new(
      "Chemical agent detection",
      dimensions: {
        temporal: "2026-03-05 14:30 local",
        spatial: "Grid ref 38S MB 456 789, Sector 4 (±50m)",
        chemical: ChemicalCoordinate.new(
          substance: "mustard agent (HD)",
          concentration: 0.5,
          unit: "mg/m³",
          label: "above IDLH threshold"
        ),
        wind: "NNW at 12 knots → plume heading SSE",
        acoustic: AcousticCoordinate.new(
          label: "no detonation heard — possible slow release"
        ),
      },
      commitment: :fixed,
      observers: ["JCAD sensor #4412", "M256 kit confirmation by Sgt. Torres"],
      original_text: "JCAD alarm at grid 38S MB 456 789, confirmed HD at 0.5 mg/m³, " \
                     "wind NNW 12 knots"
    )
    puts cbrn_event

    # --- The dimensional pattern ---
    puts
    puts "=" * 70
    puts "THE DIMENSIONAL PATTERN"
    puts "=" * 70
    puts
    puts "  Every measurable attribute of an event is a coordinate in some"
    puts "  dimension. The same abstractions apply to all of them:"
    puts
    puts "  %-20s %-20s %-20s %-15s" % ["Dimension", "Point", "Range", "Named Ref"]
    puts "  " + "-" * 73
    puts "  %-20s %-20s %-20s %-15s" % ["Spatial",   "33.5°N 44.2°E", "50km radius",    "Baghdad"]
    puts "  %-20s %-20s %-20s %-15s" % ["Temporal",  "14:30 UTC",     "4am-4:30am",     "after Ramadan"]
    puts "  %-20s %-20s %-20s %-15s" % ["Spectral",  "2.5 GHz",       "2-4 GHz",        "S-band"]
    puts "  %-20s %-20s %-20s %-15s" % ["Altitude",  "1200m ASL",     "FL250-FL350",    "ground level"]
    puts "  %-20s %-20s %-20s %-15s" % ["Network",   "10.0.0.1:443",  "10.0.0.0/24",    "the DMZ"]
    puts "  %-20s %-20s %-20s %-15s" % ["Acoustic",  "440 Hz",        "20-20000 Hz",    "gunshot"]
    puts "  %-20s %-20s %-20s %-15s" % ["Chemical",  "0.5 mg/m³ HD",  ">IDLH",          "mustard agent"]
    puts "  %-20s %-20s %-20s %-15s" % ["Financial", "$1,247.50",     "$1000-$5000",    "petty cash"]
    puts "  %-20s %-20s %-20s %-15s" % ["Velocity",  "Mach 2.3",      "subsonic",       "sprint speed"]
    puts
    puts "  Each supports: points, ranges, named references, relative offsets,"
    puts "  precision/resolution tracking, knowledge states, and intersection."
    puts
    puts "  An event is a POINT in this N-dimensional space, where each"
    puts "  dimension may be a point, a range, or unknown."
    puts
  end
end


if __FILE__ == $0
  EventDimensions.examples
end
