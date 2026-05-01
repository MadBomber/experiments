#!/usr/bin/env ruby
require 'minitest/autorun'
require_relative 'lib/event_coordinates'

class TemporalTest < Minitest::Test
  include EventCoordinates

  def test_instant
    t = Temporal.new(start_at: Time.new(2026, 3, 15, 14, 30))
    assert t.instant?
    refute t.range?
    assert_equal 0, t.duration_seconds
  end

  def test_range
    t = Temporal.new(
      start_at: Time.new(2026, 3, 15, 9, 0),
      end_at:   Time.new(2026, 3, 15, 11, 0)
    )
    refute t.instant?
    assert t.range?
    assert_equal 7200, t.duration_seconds
  end

  def test_contains_instant
    t = Temporal.new(start_at: Time.new(2026, 3, 15, 14, 30))
    assert t.contains?(Time.new(2026, 3, 15, 14, 30))
    refute t.contains?(Time.new(2026, 3, 15, 14, 31))
  end

  def test_contains_range
    t = Temporal.new(
      start_at: Time.new(2026, 3, 15, 9, 0),
      end_at:   Time.new(2026, 3, 15, 17, 0)
    )
    assert t.contains?(Time.new(2026, 3, 15, 12, 0))
    refute t.contains?(Time.new(2026, 3, 15, 18, 0))
    assert t.contains?(Time.new(2026, 3, 15, 9, 0))   # start boundary
    assert t.contains?(Time.new(2026, 3, 15, 17, 0))   # end boundary
  end

  def test_overlaps_ranges
    a = Temporal.new(start_at: Time.new(2026, 3, 15, 9, 0), end_at: Time.new(2026, 3, 15, 12, 0))
    b = Temporal.new(start_at: Time.new(2026, 3, 15, 11, 0), end_at: Time.new(2026, 3, 15, 14, 0))
    assert a.overlaps?(b)
    assert b.overlaps?(a)
  end

  def test_no_overlap
    a = Temporal.new(start_at: Time.new(2026, 3, 15, 9, 0), end_at: Time.new(2026, 3, 15, 10, 0))
    b = Temporal.new(start_at: Time.new(2026, 3, 15, 11, 0), end_at: Time.new(2026, 3, 15, 12, 0))
    refute a.overlaps?(b)
    refute b.overlaps?(a)
  end

  def test_parses_string_dates
    t = Temporal.new(start_at: "2026-03-15T14:30:00", end_at: "2026-03-15T16:00:00")
    assert t.range?
    assert_equal 2026, t.start_at.year
    assert_equal 3, t.start_at.month
  end

  def test_to_s_instant
    t = Temporal.new(start_at: Time.new(2026, 3, 15, 14, 30))
    assert_equal "2026-03-15 14:30", t.to_s
  end

  def test_to_s_range
    t = Temporal.new(start_at: Time.new(2026, 3, 15, 9, 0), end_at: Time.new(2026, 3, 15, 17, 0))
    assert_equal "2026-03-15 09:00..2026-03-15 17:00", t.to_s
  end
end


class GeospatialTest < Minitest::Test
  include EventCoordinates

  def test_point_2d
    g = Geospatial.new(latitude: 32.35, longitude: -95.30)
    assert g.point?
    refute g.three_d?
  end

  def test_point_3d
    g = Geospatial.new(latitude: 32.35, longitude: -95.30, altitude: 150.0)
    assert g.point?
    assert g.three_d?
  end

  def test_area
    g = Geospatial.new(latitude: 32.35, longitude: -95.30, radius_m: 5000)
    assert g.area?
    refute g.point?
    refute g.volume?
  end

  def test_volume
    g = Geospatial.new(latitude: 33.3, longitude: 44.4, radius_m: 50_000, floor_alt: 0, ceiling_alt: 10_000)
    assert g.volume?
    refute g.area?
    refute g.point?
  end

  def test_distance_to_same_point
    g = Geospatial.new(latitude: 32.35, longitude: -95.30)
    assert_in_delta 0, g.distance_to(g), 0.01
  end

  def test_distance_to_known
    tyler  = Geospatial.new(latitude: 32.35, longitude: -95.30)
    dallas = Geospatial.new(latitude: 32.78, longitude: -96.80)
    dist = tyler.distance_to(dallas)
    # Tyler to Dallas is ~150km
    assert_in_delta 150_000, dist, 20_000
  end

  def test_contains_point_in_area
    area = Geospatial.new(latitude: 32.35, longitude: -95.30, radius_m: 10_000)
    assert area.contains_point?(32.35, -95.30)   # center
    assert area.contains_point?(32.36, -95.30)    # ~1km away
    refute area.contains_point?(33.00, -95.30)    # ~72km away
  end

  def test_contains_point_rejects_for_point_shape
    point = Geospatial.new(latitude: 32.35, longitude: -95.30)
    refute point.contains_point?(32.35, -95.30)
  end

  def test_description
    g = Geospatial.new(latitude: 32.35, longitude: -95.30, description: "Tyler, Texas")
    assert_equal "Tyler, Texas", g.description
  end

  def test_description_nil
    g = Geospatial.new(latitude: 32.35, longitude: -95.30)
    assert_nil g.description
  end

  def test_to_s_with_description
    g = Geospatial.new(latitude: 32.35, longitude: -95.30, description: "Tyler, Texas")
    assert_includes g.to_s, "Tyler, Texas:"
    assert_includes g.to_s, "32.3500"
  end

  def test_to_s_point
    g = Geospatial.new(latitude: 32.35, longitude: -95.30)
    assert_includes g.to_s, "32.3500"
    assert_includes g.to_s, "-95.3000"
  end

  def test_to_s_point_3d
    g = Geospatial.new(latitude: 32.35, longitude: -95.30, altitude: 41.0)
    assert_includes g.to_s, "@ 41m"
  end

  def test_to_s_area
    g = Geospatial.new(latitude: 32.35, longitude: -95.30, radius_m: 5000)
    assert_includes g.to_s, "radius: 5000m"
  end

  def test_to_s_volume
    g = Geospatial.new(latitude: 33.3, longitude: 44.4, radius_m: 50_000, floor_alt: 0, ceiling_alt: 10_000)
    assert_includes g.to_s, "floor: 0m"
    assert_includes g.to_s, "ceiling: 10000m"
  end
end


class CoordinateTest < Minitest::Test
  include EventCoordinates

  def test_temporal_type
    c = Coordinate.new(type: 'temporal', data: Temporal.new(start_at: Time.now))
    assert c.temporal?
    refute c.geospatial?
  end

  def test_geospatial_type
    c = Coordinate.new(type: 'geospatial', data: Geospatial.new(latitude: 32.35, longitude: -95.30))
    assert c.geospatial?
    refute c.temporal?
  end

  def test_certain_when_nil
    c = Coordinate.new(type: 'temporal', confidence: nil, data: Temporal.new(start_at: Time.now))
    assert c.certain?
    refute c.tentative?
  end

  def test_certain_when_high
    c = Coordinate.new(type: 'temporal', confidence: 0.95, data: Temporal.new(start_at: Time.now))
    assert c.certain?
    refute c.tentative?
  end

  def test_tentative_when_low
    c = Coordinate.new(type: 'temporal', confidence: 0.3, data: Temporal.new(start_at: Time.now))
    refute c.certain?
    assert c.tentative?
  end

  def test_boundary_confidence
    c = Coordinate.new(type: 'temporal', confidence: 0.9, data: Temporal.new(start_at: Time.now))
    assert c.certain?
  end

  def test_references
    refs = [{ event_id: 1, role: 'start' }, { event_id: 2, role: 'end' }]
    c = Coordinate.new(type: 'temporal', data: Temporal.new(start_at: Time.now), references: refs)
    assert_equal 2, c.references.length
    assert_equal 'start', c.references[0][:role]
  end
end


class EventTest < Minitest::Test
  include EventCoordinates

  def setup
    @event = Event.new(
      description: "Test event",
      coordinates: [
        Coordinate.new(type: 'temporal', confidence: 0.9, data: Temporal.new(start_at: Time.now)),
        Coordinate.new(type: 'geospatial', confidence: 0.5, data: Geospatial.new(latitude: 32.35, longitude: -95.30)),
        Coordinate.new(type: 'geospatial', confidence: 1.0, data: Geospatial.new(latitude: 29.76, longitude: -95.37)),
      ]
    )
  end

  def test_description
    assert_equal "Test event", @event.description
  end

  def test_temporal_coordinates
    assert_equal 1, @event.temporal_coordinates.length
  end

  def test_geospatial_coordinates
    assert_equal 2, @event.geospatial_coordinates.length
  end

  def test_min_confidence
    assert_equal 0.5, @event.min_confidence
  end

  def test_min_confidence_all_nil
    e = Event.new(description: "No confidence", coordinates: [
      Coordinate.new(type: 'temporal', data: Temporal.new(start_at: Time.now)),
    ])
    assert_nil e.min_confidence
  end

  def test_to_s_includes_description
    assert_includes @event.to_s, "Test event"
  end

  def test_to_csv_returns_row_per_geospatial
    rows = @event.to_csv
    assert_equal 2, rows.length
    rows.each do |row|
      assert_equal "Test event", row[1]
    end
  end

  def test_to_csv_includes_temporal_on_each_row
    rows = @event.to_csv
    rows.each do |row|
      refute_nil row[3] # start_at
    end
  end

  def test_to_csv_includes_coordinates
    row = @event.to_csv[0]
    assert_in_delta 32.35, row[6], 0.01   # latitude
    assert_in_delta(-95.30, row[7], 0.01) # longitude
  end

  def test_to_csv_temporal_only_event
    e = Event.new(
      description: "Temporal only",
      coordinates: [
        Coordinate.new(type: 'temporal', confidence: 0.8, data: Temporal.new(start_at: Time.new(2026, 3, 15))),
      ]
    )
    rows = e.to_csv
    assert_equal 1, rows.length
    assert_equal "Temporal only", rows[0][1]
    assert_nil rows[0][5] # no latitude
  end

  def test_to_geojson_single_geospatial
    e = Event.new(
      description: "Single point",
      coordinates: [
        Coordinate.new(type: 'geospatial', confidence: 1.0, data: Geospatial.new(latitude: 32.35, longitude: -95.30)),
      ]
    )
    geojson = e.to_geojson
    assert_equal "Feature", geojson[:type]
    assert_equal "Point", geojson[:geometry][:type]
    assert_in_delta(-95.30, geojson[:geometry][:coordinates][0], 0.01)
    assert_in_delta 32.35, geojson[:geometry][:coordinates][1], 0.01
    assert_equal "Single point", geojson[:properties][:description]
  end

  def test_to_geojson_multiple_geospatial
    geojson = @event.to_geojson
    assert_equal "FeatureCollection", geojson[:type]
    assert_equal 2, geojson[:features].length
  end

  def test_to_geojson_includes_temporal_properties
    e = Event.new(
      description: "With time",
      coordinates: [
        Coordinate.new(type: 'temporal', data: Temporal.new(start_at: Time.new(2026, 3, 15, 14, 30))),
        Coordinate.new(type: 'geospatial', confidence: 0.9, data: Geospatial.new(latitude: 32.35, longitude: -95.30)),
      ]
    )
    geojson = e.to_geojson
    assert geojson[:properties].key?(:start_at)
  end

  def test_to_geojson_includes_area_properties
    e = Event.new(
      description: "Area event",
      coordinates: [
        Coordinate.new(type: 'geospatial', confidence: 0.5,
          data: Geospatial.new(latitude: 33.4, longitude: 43.3, radius_m: 150_000)),
      ]
    )
    geojson = e.to_geojson
    assert_equal 150_000, geojson[:properties][:radius_m]
    assert_equal "area", geojson[:properties][:shape]
  end

  def test_to_geojson_3d_coordinates
    e = Event.new(
      description: "3D point",
      coordinates: [
        Coordinate.new(type: 'geospatial', confidence: 1.0,
          data: Geospatial.new(latitude: 33.3, longitude: 44.4, altitude: 41.0)),
      ]
    )
    geojson = e.to_geojson
    coords = geojson[:geometry][:coordinates]
    assert_equal 3, coords.length
    assert_in_delta 41.0, coords[2], 0.1
  end

  def test_collection_to_csv
    events = [
      Event.new(description: "E1", coordinates: [
        Coordinate.new(type: 'geospatial', confidence: 1.0, data: Geospatial.new(latitude: 32.0, longitude: -95.0)),
      ]),
      Event.new(description: "E2", coordinates: [
        Coordinate.new(type: 'geospatial', confidence: 0.5, data: Geospatial.new(latitude: 33.0, longitude: -96.0)),
      ]),
    ]
    csv_string = Event.collection_to_csv(events)
    lines = csv_string.strip.split("\n")
    assert_equal 3, lines.length # header + 2 rows
    assert_includes lines[0], "description"
    assert_includes lines[1], "E1"
    assert_includes lines[2], "E2"
  end

  def test_collection_to_geojson
    events = [
      Event.new(description: "E1", coordinates: [
        Coordinate.new(type: 'geospatial', confidence: 1.0, data: Geospatial.new(latitude: 32.0, longitude: -95.0)),
      ]),
      Event.new(description: "E2", coordinates: [
        Coordinate.new(type: 'geospatial', confidence: 0.5, data: Geospatial.new(latitude: 33.0, longitude: -96.0)),
      ]),
    ]
    geojson = Event.collection_to_geojson(events)
    assert_equal "FeatureCollection", geojson[:type]
    assert_equal 2, geojson[:features].length
    assert_equal "E1", geojson[:features][0][:properties][:description]
  end

  def test_collection_to_geojson_flattens_multi_geo_events
    events = [@event] # has 2 geospatial coordinates
    geojson = Event.collection_to_geojson(events)
    assert_equal "FeatureCollection", geojson[:type]
    assert_equal 2, geojson[:features].length
  end

  def test_from_csv_round_trip
    original = Event.new(
      id: 1,
      description: "Round trip",
      coordinates: [
        Coordinate.new(type: 'temporal', confidence: 0.8,
          data: Temporal.new(start_at: Time.new(2026, 3, 15, 14, 30))),
        Coordinate.new(type: 'geospatial', confidence: 0.9,
          data: Geospatial.new(latitude: 32.35, longitude: -95.30, altitude: 120.0, description: "Tyler, Texas")),
      ]
    )
    csv_string = Event.collection_to_csv([original])
    restored = Event.from_csv(csv_string)

    assert_equal 1, restored.length
    e = restored.first
    assert_equal "Round trip", e.description
    assert_equal 1, e.temporal_coordinates.length
    assert_equal 1, e.geospatial_coordinates.length

    geo = e.geospatial_coordinates.first.data
    assert_in_delta 32.35, geo.latitude, 0.01
    assert_in_delta(-95.30, geo.longitude, 0.01)
    assert_in_delta 120.0, geo.altitude, 0.1
    assert_equal "Tyler, Texas", geo.description
  end

  def test_from_csv_multiple_geospatial
    original = Event.new(
      id: 2,
      description: "Multi geo",
      coordinates: [
        Coordinate.new(type: 'temporal', confidence: 0.7,
          data: Temporal.new(start_at: Time.new(2026, 7, 10), end_at: Time.new(2026, 7, 10, 14, 0))),
        Coordinate.new(type: 'geospatial', confidence: 1.0,
          data: Geospatial.new(latitude: 32.35, longitude: -95.30)),
        Coordinate.new(type: 'geospatial', confidence: 1.0,
          data: Geospatial.new(latitude: 29.76, longitude: -95.37)),
      ]
    )
    csv_string = Event.collection_to_csv([original])
    restored = Event.from_csv(csv_string)

    assert_equal 1, restored.length
    e = restored.first
    assert_equal 2, e.geospatial_coordinates.length
    assert_equal 1, e.temporal_coordinates.length
  end

  def test_from_csv_temporal_only
    original = Event.new(
      id: 3,
      description: "Temporal only",
      coordinates: [
        Coordinate.new(type: 'temporal', confidence: 0.5,
          data: Temporal.new(start_at: Time.new(2026, 6, 1))),
      ]
    )
    csv_string = Event.collection_to_csv([original])
    restored = Event.from_csv(csv_string)

    assert_equal 1, restored.length
    e = restored.first
    assert_equal 1, e.temporal_coordinates.length
    assert_equal 0, e.geospatial_coordinates.length
  end

  def test_from_geojson_round_trip
    original = Event.new(
      id: 1,
      description: "GeoJSON round trip",
      coordinates: [
        Coordinate.new(type: 'temporal', confidence: 0.9,
          data: Temporal.new(start_at: Time.new(2026, 3, 15, 14, 30))),
        Coordinate.new(type: 'geospatial', confidence: 0.9,
          data: Geospatial.new(latitude: 32.35, longitude: -95.30, altitude: 120.0)),
      ]
    )
    geojson = Event.collection_to_geojson([original])
    json_string = JSON.generate(geojson)
    restored = Event.from_geojson(json_string)

    assert_equal 1, restored.length
    e = restored.first
    assert_equal "GeoJSON round trip", e.description
    assert_equal 1, e.id

    geo = e.geospatial_coordinates.first.data
    assert_in_delta 32.35, geo.latitude, 0.01
    assert_in_delta(-95.30, geo.longitude, 0.01)
    assert_in_delta 120.0, geo.altitude, 0.1

    temporal = e.temporal_coordinates.first.data
    assert_equal 2026, temporal.start_at.year
    assert_equal 3, temporal.start_at.month
  end

  def test_from_geojson_with_area
    original = Event.new(
      description: "Area event",
      coordinates: [
        Coordinate.new(type: 'geospatial', confidence: 0.3,
          data: Geospatial.new(latitude: 33.4, longitude: 43.3, radius_m: 150_000)),
      ]
    )
    geojson = original.to_geojson
    restored = Event.from_geojson(geojson)

    assert_equal 1, restored.length
    geo = restored.first.geospatial_coordinates.first.data
    assert geo.area?
    assert_in_delta 150_000, geo.radius_m, 1
  end

  def test_from_geojson_single_feature
    original = Event.new(
      description: "Single feature",
      coordinates: [
        Coordinate.new(type: 'geospatial', confidence: 1.0,
          data: Geospatial.new(latitude: 32.0, longitude: -95.0)),
      ]
    )
    geojson = original.to_geojson # returns a single Feature, not FeatureCollection
    assert_equal "Feature", geojson[:type]

    restored = Event.from_geojson(geojson)
    assert_equal 1, restored.length
    assert_equal "Single feature", restored.first.description
  end

  def test_from_geojson_multi_geospatial_round_trip
    original = Event.new(
      description: "Road trip",
      coordinates: [
        Coordinate.new(type: 'geospatial', confidence: 1.0,
          data: Geospatial.new(latitude: 32.35, longitude: -95.30)),
        Coordinate.new(type: 'geospatial', confidence: 1.0,
          data: Geospatial.new(latitude: 29.76, longitude: -95.37)),
      ]
    )
    geojson = Event.collection_to_geojson([original])
    restored = Event.from_geojson(geojson)

    assert_equal 1, restored.length
    assert_equal 2, restored.first.geospatial_coordinates.length
  end
end


class DatabaseTest < Minitest::Test
  include EventCoordinates

  def setup
    @database = Database.new  # in-memory
  end

  def teardown
    @database.close
  end

  def test_tables_created
    tables = @database.db.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")
                        .map { |r| r['name'] }
    assert_includes tables, 'events'
    assert_includes tables, 'coordinates'
    assert_includes tables, 'temporal_data'
    assert_includes tables, 'geospatial_data'
    assert_includes tables, 'coordinate_references'
  end

  def test_foreign_keys_enabled
    result = @database.db.get_first_value("PRAGMA foreign_keys")
    assert_equal 1, result
  end
end


class RepositoryTest < Minitest::Test
  include EventCoordinates

  def setup
    @database = Database.new
    @repo = Repository.new(@database)
  end

  def teardown
    @database.close
  end

  def test_save_and_find_event
    event = @repo.save_event(Event.new(
      description: "Test event",
      coordinates: [
        Coordinate.new(type: 'temporal', confidence: 1.0, data: Temporal.new(start_at: Time.new(2026, 3, 15, 14, 30))),
      ]
    ))

    found = @repo.find_event(event.id)
    assert_equal "Test event", found.description
    assert_equal 1, found.coordinates.length
    assert found.coordinates[0].temporal?
    assert_equal 1.0, found.coordinates[0].confidence
  end

  def test_save_preserves_temporal_instant
    event = @repo.save_event(Event.new(
      description: "Instant",
      coordinates: [
        Coordinate.new(type: 'temporal', data: Temporal.new(start_at: Time.new(2026, 6, 15, 9, 0))),
      ]
    ))

    found = @repo.find_event(event.id)
    temporal = found.coordinates[0].data
    assert temporal.instant?
    assert_equal 2026, temporal.start_at.year
    assert_equal 6, temporal.start_at.month
    assert_equal 15, temporal.start_at.day
  end

  def test_save_preserves_temporal_range
    event = @repo.save_event(Event.new(
      description: "Range",
      coordinates: [
        Coordinate.new(type: 'temporal', data: Temporal.new(
          start_at: Time.new(2026, 3, 10, 6, 0),
          end_at:   Time.new(2026, 3, 10, 18, 0)
        )),
      ]
    ))

    found = @repo.find_event(event.id)
    temporal = found.coordinates[0].data
    assert temporal.range?
    assert_equal 6, temporal.start_at.hour
    assert_equal 18, temporal.end_at.hour
  end

  def test_save_preserves_geospatial_point
    event = @repo.save_event(Event.new(
      description: "Point",
      coordinates: [
        Coordinate.new(type: 'geospatial', data: Geospatial.new(latitude: 32.35, longitude: -95.30)),
      ]
    ))

    found = @repo.find_event(event.id)
    geo = found.coordinates[0].data
    assert geo.point?
    assert_in_delta 32.35, geo.latitude, 0.001
    assert_in_delta -95.30, geo.longitude, 0.001
  end

  def test_save_preserves_geospatial_description
    event = @repo.save_event(Event.new(
      description: "Named location",
      coordinates: [
        Coordinate.new(type: 'geospatial', data: Geospatial.new(
          latitude: 32.35, longitude: -95.30, description: "Tyler, Texas"
        )),
      ]
    ))

    found = @repo.find_event(event.id)
    geo = found.coordinates[0].data
    assert_equal "Tyler, Texas", geo.description
  end

  def test_save_preserves_geospatial_nil_description
    event = @repo.save_event(Event.new(
      description: "Unnamed point",
      coordinates: [
        Coordinate.new(type: 'geospatial', data: Geospatial.new(latitude: 32.35, longitude: -95.30)),
      ]
    ))

    found = @repo.find_event(event.id)
    geo = found.coordinates[0].data
    assert_nil geo.description
  end

  def test_save_preserves_geospatial_3d
    event = @repo.save_event(Event.new(
      description: "3D Point",
      coordinates: [
        Coordinate.new(type: 'geospatial', data: Geospatial.new(latitude: 33.3, longitude: 44.4, altitude: 41.0)),
      ]
    ))

    found = @repo.find_event(event.id)
    geo = found.coordinates[0].data
    assert geo.point?
    assert geo.three_d?
    assert_in_delta 41.0, geo.altitude, 0.1
  end

  def test_save_preserves_geospatial_area
    event = @repo.save_event(Event.new(
      description: "Area",
      coordinates: [
        Coordinate.new(type: 'geospatial', data: Geospatial.new(latitude: 33.4, longitude: 43.3, radius_m: 150_000)),
      ]
    ))

    found = @repo.find_event(event.id)
    geo = found.coordinates[0].data
    assert geo.area?
    assert_in_delta 150_000, geo.radius_m, 1
  end

  def test_save_preserves_geospatial_volume
    event = @repo.save_event(Event.new(
      description: "Volume",
      coordinates: [
        Coordinate.new(type: 'geospatial', data: Geospatial.new(
          latitude: 33.3, longitude: 44.4,
          radius_m: 50_000, floor_alt: 0, ceiling_alt: 10_000
        )),
      ]
    ))

    found = @repo.find_event(event.id)
    geo = found.coordinates[0].data
    assert geo.volume?
    assert_in_delta 0, geo.floor_alt, 0.1
    assert_in_delta 10_000, geo.ceiling_alt, 0.1
  end

  def test_save_preserves_confidence_nil
    event = @repo.save_event(Event.new(
      description: "No confidence",
      coordinates: [
        Coordinate.new(type: 'temporal', confidence: nil, data: Temporal.new(start_at: Time.now)),
      ]
    ))

    found = @repo.find_event(event.id)
    assert_nil found.coordinates[0].confidence
  end

  def test_save_preserves_references
    anchor = @repo.save_event(Event.new(
      description: "Christmas",
      coordinates: [
        Coordinate.new(type: 'temporal', data: Temporal.new(start_at: Time.new(2026, 12, 25))),
      ]
    ))

    event = @repo.save_event(Event.new(
      description: "Day after Christmas",
      coordinates: [
        Coordinate.new(
          type: 'temporal',
          data: Temporal.new(start_at: Time.new(2026, 12, 26)),
          references: [{ event_id: anchor.id, role: 'anchor' }]
        ),
      ]
    ))

    found = @repo.find_event(event.id)
    refs = found.coordinates[0].references
    assert_equal 1, refs.length
    assert_equal anchor.id, refs[0][:event_id]
    assert_equal 'anchor', refs[0][:role]
  end

  def test_multiple_coordinates
    event = @repo.save_event(Event.new(
      description: "Road trip",
      coordinates: [
        Coordinate.new(type: 'temporal', confidence: 0.7, data: Temporal.new(
          start_at: Time.new(2026, 7, 10), end_at: Time.new(2026, 7, 10, 14, 0)
        )),
        Coordinate.new(type: 'geospatial', confidence: 1.0, data: Geospatial.new(latitude: 32.35, longitude: -95.30)),
        Coordinate.new(type: 'geospatial', confidence: 1.0, data: Geospatial.new(latitude: 29.76, longitude: -95.37)),
      ]
    ))

    found = @repo.find_event(event.id)
    assert_equal 3, found.coordinates.length
    assert_equal 1, found.temporal_coordinates.length
    assert_equal 2, found.geospatial_coordinates.length
  end

  def test_all_events
    3.times { |i| @repo.save_event(Event.new(description: "Event #{i}", coordinates: [])) }
    assert_equal 3, @repo.all_events.length
  end

  def test_find_events_by_description
    @repo.save_event(Event.new(description: "Dentist appointment", coordinates: []))
    @repo.save_event(Event.new(description: "Doctor appointment", coordinates: []))
    @repo.save_event(Event.new(description: "Lunch", coordinates: []))

    results = @repo.find_events_by_description("appointment")
    assert_equal 2, results.length
  end

  def test_find_events_in_timerange
    @repo.save_event(Event.new(
      description: "March event",
      coordinates: [
        Coordinate.new(type: 'temporal', data: Temporal.new(start_at: Time.new(2026, 3, 15))),
      ]
    ))
    @repo.save_event(Event.new(
      description: "July event",
      coordinates: [
        Coordinate.new(type: 'temporal', data: Temporal.new(start_at: Time.new(2026, 7, 4))),
      ]
    ))

    results = @repo.find_events_in_timerange(Time.new(2026, 3, 1), Time.new(2026, 3, 31))
    assert_equal 1, results.length
    assert_equal "March event", results[0].description
  end

  def test_find_events_in_timerange_includes_overlapping_ranges
    @repo.save_event(Event.new(
      description: "Spanning event",
      coordinates: [
        Coordinate.new(type: 'temporal', data: Temporal.new(
          start_at: Time.new(2026, 2, 15),
          end_at:   Time.new(2026, 4, 15)
        )),
      ]
    ))

    results = @repo.find_events_in_timerange(Time.new(2026, 3, 1), Time.new(2026, 3, 31))
    assert_equal 1, results.length
    assert_equal "Spanning event", results[0].description
  end

  def test_find_events_near
    @repo.save_event(Event.new(
      description: "Tyler event",
      coordinates: [
        Coordinate.new(type: 'geospatial', data: Geospatial.new(latitude: 32.35, longitude: -95.30)),
      ]
    ))
    @repo.save_event(Event.new(
      description: "Houston event",
      coordinates: [
        Coordinate.new(type: 'geospatial', data: Geospatial.new(latitude: 29.76, longitude: -95.37)),
      ]
    ))

    results = @repo.find_events_near(32.35, -95.30, 50_000)
    assert_equal 1, results.length
    assert_equal "Tyler event", results[0].description
  end

  def test_find_referencing_events
    anchor = @repo.save_event(Event.new(
      description: "Thanksgiving",
      coordinates: [
        Coordinate.new(type: 'temporal', data: Temporal.new(start_at: Time.new(2026, 11, 26))),
      ]
    ))

    @repo.save_event(Event.new(
      description: "Black Friday",
      coordinates: [
        Coordinate.new(
          type: 'temporal',
          data: Temporal.new(start_at: Time.new(2026, 11, 27)),
          references: [{ event_id: anchor.id, role: 'anchor' }]
        ),
      ]
    ))

    @repo.save_event(Event.new(description: "Unrelated", coordinates: []))

    results = @repo.find_referencing_events(anchor.id)
    assert_equal 1, results.length
    assert_equal "Black Friday", results[0].description
  end

  def test_delete_event
    event = @repo.save_event(Event.new(description: "To delete", coordinates: []))
    assert_equal 1, @repo.event_count

    @repo.delete_event(event.id)
    assert_equal 0, @repo.event_count
  end

  def test_delete_event_cascades_to_coordinates
    event = @repo.save_event(Event.new(
      description: "Cascade test",
      coordinates: [
        Coordinate.new(type: 'temporal', data: Temporal.new(start_at: Time.now)),
        Coordinate.new(type: 'geospatial', data: Geospatial.new(latitude: 32.35, longitude: -95.30)),
      ]
    ))
    assert_equal 2, @repo.coordinate_count

    @repo.delete_event(event.id)
    assert_equal 0, @repo.coordinate_count
  end

  def test_add_coordinate_to_existing_event
    event = @repo.save_event(Event.new(
      description: "Evolving event",
      coordinates: [
        Coordinate.new(type: 'temporal', data: Temporal.new(start_at: Time.new(2026, 6, 15))),
      ]
    ))
    assert_equal 1, event.coordinates.length

    @repo.add_coordinate(event, Coordinate.new(
      type: 'geospatial',
      confidence: 0.8,
      data: Geospatial.new(latitude: 32.35, longitude: -95.30)
    ))

    found = @repo.find_event(event.id)
    assert_equal 2, found.coordinates.length
  end

  def test_event_count
    assert_equal 0, @repo.event_count
    @repo.save_event(Event.new(description: "One", coordinates: []))
    assert_equal 1, @repo.event_count
  end

  def test_find_nonexistent_event
    assert_nil @repo.find_event(9999)
  end

  def test_persistence_round_trip
    path = '/tmp/test_event_coords.db'
    File.delete(path) if File.exist?(path)

    db1 = Database.new(path)
    repo1 = Repository.new(db1)
    repo1.save_event(Event.new(
      description: "Persisted",
      coordinates: [
        Coordinate.new(type: 'temporal', confidence: 0.8, data: Temporal.new(start_at: Time.new(2026, 1, 1))),
        Coordinate.new(type: 'geospatial', confidence: 1.0, data: Geospatial.new(latitude: 32.35, longitude: -95.30)),
      ]
    ))
    db1.close

    db2 = Database.new(path)
    repo2 = Repository.new(db2)
    events = repo2.all_events
    assert_equal 1, events.length
    assert_equal "Persisted", events[0].description
    assert_equal 2, events[0].coordinates.length
    assert_in_delta 0.8, events[0].coordinates[0].confidence, 0.01
    db2.close

    File.delete(path)
  end
end
