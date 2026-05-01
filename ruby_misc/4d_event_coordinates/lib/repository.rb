module EventCoordinates
  class Repository
    def initialize(database)
      @db = database.db
    end

    # --- Save ---

    def save_event(event)
      if event.id
        @db.execute(
          "UPDATE events SET description = ?, updated_at = datetime('now') WHERE id = ?",
          [event.description, event.id]
        )
        event
      else
        @db.execute("INSERT INTO events (description) VALUES (?)", [event.description])
        id = @db.last_insert_row_id
        saved = Event.new(description: event.description, id: id, coordinates: [])

        event.coordinates.each do |coord|
          saved_coord = save_coordinate(coord, id)
          saved.coordinates << saved_coord
        end

        saved
      end
    end

    def save_coordinate(coordinate, event_id)
      @db.execute(
        "INSERT INTO coordinates (event_id, type, confidence) VALUES (?, ?, ?)",
        [event_id, coordinate.type, coordinate.confidence]
      )
      coord_id = @db.last_insert_row_id

      case coordinate.type
      when 'temporal'
        save_temporal(coordinate.data, coord_id)
      when 'geospatial'
        save_geospatial(coordinate.data, coord_id)
      end

      coordinate.references.each do |ref|
        save_reference(coord_id, ref[:event_id], ref[:role])
      end

      Coordinate.new(
        id: coord_id, event_id: event_id,
        type: coordinate.type, confidence: coordinate.confidence,
        data: coordinate.data, references: coordinate.references
      )
    end

    def add_coordinate(event, coordinate)
      save_coordinate(coordinate, event.id).tap do |saved|
        event.coordinates << saved
      end
    end

    # --- Find ---

    def find_event(id)
      row = @db.get_first_row("SELECT * FROM events WHERE id = ?", [id])
      return nil unless row
      build_event(row)
    end

    def all_events
      @db.execute("SELECT * FROM events ORDER BY created_at").map { |row| build_event(row) }
    end

    def find_events_by_description(query)
      @db.execute(
        "SELECT * FROM events WHERE description LIKE ? ORDER BY created_at",
        ["%#{query}%"]
      ).map { |row| build_event(row) }
    end

    # Find events within a time range
    def find_events_in_timerange(start_at, end_at)
      rows = @db.execute(<<~SQL, [end_at.iso8601, start_at.iso8601])
        SELECT DISTINCT e.*
        FROM events e
        JOIN coordinates c ON c.event_id = e.id
        JOIN temporal_data t ON t.coordinate_id = c.id
        WHERE c.type = 'temporal'
          AND t.start_at <= ?
          AND (t.end_at IS NULL OR t.end_at >= ?)
        ORDER BY t.start_at
      SQL
      rows.map { |row| build_event(row) }
    end

    # Find events near a point (within radius_m meters)
    def find_events_near(latitude, longitude, radius_m)
      # Rough bounding box filter first (SQLite can't do Haversine natively)
      # 1 degree latitude ≈ 111,000 meters
      deg_offset = radius_m / 111_000.0

      params = [latitude - deg_offset, latitude + deg_offset,
                longitude - deg_offset, longitude + deg_offset]
      rows = @db.execute(<<~SQL, params)
        SELECT DISTINCT e.*
        FROM events e
        JOIN coordinates c ON c.event_id = e.id
        JOIN geospatial_data g ON g.coordinate_id = c.id
        WHERE c.type = 'geospatial'
          AND g.latitude BETWEEN ? AND ?
          AND g.longitude BETWEEN ? AND ?
        ORDER BY e.created_at
      SQL

      # Refine with actual Haversine distance
      rows.map { |row| build_event(row) }.select do |event|
        event.geospatial_coordinates.any? do |coord|
          coord.data.distance_to(
            Geospatial.new(latitude: latitude, longitude: longitude)
          ) <= radius_m
        end
      end
    end

    # Find events that reference a given event
    def find_referencing_events(event_id)
      rows = @db.execute(<<~SQL, [event_id])
        SELECT DISTINCT e.*
        FROM events e
        JOIN coordinates c ON c.event_id = e.id
        JOIN coordinate_references cr ON cr.coordinate_id = c.id
        WHERE cr.referenced_event_id = ?
        ORDER BY e.created_at
      SQL
      rows.map { |row| build_event(row) }
    end

    # --- Delete ---

    def delete_event(id)
      @db.execute("DELETE FROM events WHERE id = ?", [id])
    end

    def delete_coordinate(id)
      @db.execute("DELETE FROM coordinates WHERE id = ?", [id])
    end

    # --- Counts ---

    def event_count
      @db.get_first_value("SELECT COUNT(*) FROM events")
    end

    def coordinate_count
      @db.get_first_value("SELECT COUNT(*) FROM coordinates")
    end

    private

    def build_event(row)
      coords = load_coordinates(row['id'])
      Event.new(id: row['id'], description: row['description'], coordinates: coords)
    end

    def load_coordinates(event_id)
      @db.execute(
        "SELECT * FROM coordinates WHERE event_id = ? ORDER BY id", [event_id]
      ).map do |row|
        data = case row['type']
               when 'temporal'   then load_temporal(row['id'])
               when 'geospatial' then load_geospatial(row['id'])
               end

        refs = load_references(row['id'])

        Coordinate.new(
          id: row['id'], event_id: event_id,
          type: row['type'], confidence: row['confidence'],
          data: data, references: refs
        )
      end
    end

    def load_temporal(coordinate_id)
      row = @db.get_first_row(
        "SELECT * FROM temporal_data WHERE coordinate_id = ?", [coordinate_id]
      )
      return nil unless row
      Temporal.new(
        start_at: row['start_at'], end_at: row['end_at'],
        id: row['coordinate_id'], coordinate_id: coordinate_id
      )
    end

    def load_geospatial(coordinate_id)
      row = @db.get_first_row(
        "SELECT * FROM geospatial_data WHERE coordinate_id = ?", [coordinate_id]
      )
      return nil unless row
      Geospatial.new(
        latitude: row['latitude'], longitude: row['longitude'],
        description: row['description'],
        altitude: row['altitude'], radius_m: row['radius_m'],
        floor_alt: row['floor_alt'], ceiling_alt: row['ceiling_alt'],
        shape: row['shape'], id: row['coordinate_id'], coordinate_id: coordinate_id
      )
    end

    def load_references(coordinate_id)
      @db.execute(
        "SELECT * FROM coordinate_references WHERE coordinate_id = ?", [coordinate_id]
      ).map do |row|
        { event_id: row['referenced_event_id'], role: row['role'] }
      end
    end

    def save_temporal(temporal, coordinate_id)
      @db.execute(
        "INSERT INTO temporal_data (coordinate_id, start_at, end_at) VALUES (?, ?, ?)",
        [coordinate_id, temporal.start_at.iso8601, temporal.end_at&.iso8601]
      )
    end

    def save_geospatial(geo, coordinate_id)
      @db.execute(
        "INSERT INTO geospatial_data (coordinate_id, description, shape, latitude, longitude, altitude, radius_m, floor_alt, ceiling_alt) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
        [coordinate_id, geo.description, geo.shape, geo.latitude, geo.longitude, geo.altitude, geo.radius_m, geo.floor_alt, geo.ceiling_alt]
      )
    end

    def save_reference(coordinate_id, referenced_event_id, role)
      @db.execute(
        "INSERT INTO coordinate_references (coordinate_id, referenced_event_id, role) VALUES (?, ?, ?)",
        [coordinate_id, referenced_event_id, role]
      )
    end
  end
end
