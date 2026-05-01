require 'csv'
require 'json'

module EventCoordinates
  class Event
    attr_reader :id, :description, :coordinates

    CSV_HEADERS = %w[
      id description confidence
      start_at end_at
      location_description latitude longitude altitude radius_m floor_alt ceiling_alt shape
    ].freeze

    def initialize(description:, id: nil, coordinates: [])
      @id          = id
      @description = description
      @coordinates = coordinates
    end

    def temporal_coordinates
      @coordinates.select(&:temporal?)
    end

    def geospatial_coordinates
      @coordinates.select(&:geospatial?)
    end

    def min_confidence
      confs = @coordinates.map(&:confidence).compact
      confs.empty? ? nil : confs.min
    end

    def to_s
      lines = ["EVENT: #{@description}"]
      @coordinates.each { |c| lines << "  #{c}" }
      lines.join("\n")
    end

    def to_csv
      temporal = temporal_coordinates.first&.data
      rows = []

      if geospatial_coordinates.any?
        geospatial_coordinates.each do |coord|
          geo = coord.data
          rows << [
            @id, @description, coord.confidence,
            temporal&.start_at&.iso8601, temporal&.end_at&.iso8601,
            geo.description,
            geo.latitude, geo.longitude, geo.altitude,
            geo.radius_m, geo.floor_alt, geo.ceiling_alt, geo.shape
          ]
        end
      else
        rows << [
          @id, @description, temporal_coordinates.first&.confidence,
          temporal&.start_at&.iso8601, temporal&.end_at&.iso8601,
          nil, nil, nil, nil, nil, nil, nil, nil
        ]
      end

      rows
    end

    def to_geojson
      features = geospatial_coordinates.map do |coord|
        geo = coord.data
        properties = {
          id:          @id,
          description: @description,
          confidence:  coord.confidence
        }.merge(geo.to_geojson_properties)

        temporal = temporal_coordinates.first&.data
        if temporal
          properties[:start_at] = temporal.start_at.iso8601
          properties[:end_at]   = temporal.end_at&.iso8601
        end

        coord.references.each_with_index do |ref, i|
          properties[:"ref_#{i}_event_id"] = ref[:event_id]
          properties[:"ref_#{i}_role"]     = ref[:role]
        end

        {
          type:       "Feature",
          geometry:   geo.to_geojson_geometry,
          properties: properties
        }
      end

      return features.first if features.size == 1

      { type: "FeatureCollection", features: features }
    end

    def self.csv_header
      CSV_HEADERS.to_csv
    end

    def self.collection_to_csv(events)
      CSV.generate do |csv|
        csv << CSV_HEADERS
        events.each { |event| event.to_csv.each { |row| csv << row } }
      end
    end

    def self.collection_to_geojson(events)
      features = events.flat_map do |event|
        result = event.to_geojson
        next [] if result.nil?

        if result[:type] == "FeatureCollection"
          result[:features]
        else
          [result]
        end
      end

      { type: "FeatureCollection", features: features }
    end

    def self.from_csv(csv_string)
      rows = CSV.parse(csv_string, headers: true)
      grouped = rows.group_by { |row| [row['id'], row['description']] }

      grouped.map do |(id, description), group|
        coordinates = []

        first = group.first
        if first['start_at'] && !first['start_at'].empty?
          coordinates << Coordinate.new(
            type: 'temporal',
            confidence: first['confidence']&.to_f,
            data: Temporal.new(
              start_at: first['start_at'],
              end_at:   (first['end_at'] && !first['end_at'].empty?) ? first['end_at'] : nil
            )
          )
        end

        group.each do |row|
          next unless row['latitude'] && !row['latitude'].empty?

          coordinates << Coordinate.new(
            type: 'geospatial',
            confidence: row['confidence']&.to_f,
            data: Geospatial.new(
              latitude:    row['latitude'],
              longitude:   row['longitude'],
              description: row['location_description']&.empty? ? nil : row['location_description'],
              altitude:    row['altitude']&.empty? ? nil : row['altitude'],
              radius_m:    row['radius_m']&.empty? ? nil : row['radius_m'],
              floor_alt:   row['floor_alt']&.empty? ? nil : row['floor_alt'],
              ceiling_alt: row['ceiling_alt']&.empty? ? nil : row['ceiling_alt'],
              shape:       row['shape']&.empty? ? nil : row['shape']
            )
          )
        end

        Event.new(
          id:          id&.empty? ? nil : id&.to_i,
          description: description,
          coordinates: coordinates
        )
      end
    end

    def self.from_geojson(geojson)
      geojson = JSON.parse(geojson, symbolize_names: true) if geojson.is_a?(String)

      features = if geojson[:type] == "FeatureCollection"
                   geojson[:features]
                 else
                   [geojson]
                 end

      grouped = features.group_by { |f| f[:properties][:description] }

      grouped.map do |description, feature_group|
        coordinates = []

        first_props = feature_group.first[:properties]
        if first_props[:start_at]
          coordinates << Coordinate.new(
            type: 'temporal',
            confidence: first_props[:confidence],
            data: Temporal.new(
              start_at: first_props[:start_at],
              end_at:   first_props[:end_at]
            )
          )
        end

        feature_group.each do |feature|
          coords = feature[:geometry][:coordinates]
          props  = feature[:properties]

          coordinates << Coordinate.new(
            type: 'geospatial',
            confidence: props[:confidence],
            data: Geospatial.new(
              longitude:   coords[0],
              latitude:    coords[1],
              altitude:    coords[2],
              description: props[:location_description],
              radius_m:    props[:radius_m],
              floor_alt:   props[:floor_alt],
              ceiling_alt: props[:ceiling_alt],
              shape:       props[:shape]
            )
          )
        end

        Event.new(
          id:          first_props[:id],
          description: description,
          coordinates: coordinates
        )
      end
    end
  end
end
