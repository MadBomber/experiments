module EventCoordinates
  class Geospatial
    attr_reader :id, :coordinate_id, :description, :shape,
                :latitude, :longitude, :altitude,
                :radius_m, :floor_alt, :ceiling_alt

    def initialize(
      latitude:, longitude:,
      description: nil, altitude: nil, radius_m: nil,
      floor_alt: nil, ceiling_alt: nil,
      shape: nil, id: nil, coordinate_id: nil
    )
      @id            = id
      @coordinate_id = coordinate_id
      @description   = description
      @latitude      = latitude.to_f
      @longitude     = longitude.to_f
      @altitude      = altitude&.to_f
      @radius_m      = radius_m&.to_f
      @floor_alt     = floor_alt&.to_f
      @ceiling_alt   = ceiling_alt&.to_f
      @shape         = (shape || infer_shape).to_s
    end

    def point?  = @shape == 'point'
    def area?   = @shape == 'area'
    def volume? = @shape == 'volume'
    def three_d? = !@altitude.nil?

    # Haversine distance in meters to another geospatial
    def distance_to(other)
      r = 6_371_000.0
      lat1 = @latitude * Math::PI / 180
      lat2 = other.latitude * Math::PI / 180
      dlat = (other.latitude - @latitude) * Math::PI / 180
      dlon = (other.longitude - @longitude) * Math::PI / 180

      a = Math.sin(dlat / 2)**2 +
          Math.cos(lat1) * Math.cos(lat2) * Math.sin(dlon / 2)**2
      c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
      r * c
    end

    # Does this geospatial contain a point?
    def contains_point?(lat, lon)
      return false unless area? || volume?
      d = distance_to(Geospatial.new(latitude: lat, longitude: lon))
      d <= (@radius_m || 0)
    end

    def to_s
      prefix = @description ? "#{@description}: " : ""
      case @shape
      when 'point'
        s = "%.4f, %.4f" % [@latitude, @longitude]
        s += " @ %.0fm" % @altitude if @altitude
        "#{prefix}#{s}"
      when 'area'
        "#{prefix}" + "%.4f, %.4f (radius: %.0fm)" % [@latitude, @longitude, @radius_m || 0]
      when 'volume'
        "#{prefix}" + "%.4f, %.4f (radius: %.0fm, floor: %.0fm, ceiling: %.0fm)" % [
          @latitude, @longitude, @radius_m || 0, @floor_alt || 0, @ceiling_alt || 0
        ]
      end
    end

    def to_geojson_geometry
      {
        type: "Point",
        coordinates: [@longitude, @latitude, @altitude].compact
      }
    end

    def to_geojson_properties
      props = { shape: @shape }
      props[:location_description] = @description if @description
      props[:radius_m]    = @radius_m    if @radius_m
      props[:floor_alt]   = @floor_alt   if @floor_alt
      props[:ceiling_alt] = @ceiling_alt if @ceiling_alt
      props
    end

    private

    def infer_shape
      if @floor_alt || @ceiling_alt
        'volume'
      elsif @radius_m
        'area'
      else
        'point'
      end
    end
  end
end
