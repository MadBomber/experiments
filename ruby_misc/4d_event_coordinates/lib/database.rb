require 'sqlite3'
require 'json'

module EventCoordinates
  class Database
    attr_reader :db

    def initialize(path = ':memory:')
      @db = SQLite3::Database.new(path)
      @db.results_as_hash = true
      @db.execute("PRAGMA foreign_keys = ON")
      create_tables
    end

    def close
      @db.close
    end

    private

    def create_tables
      @db.execute_batch(<<~SQL)
        CREATE TABLE IF NOT EXISTS events (
          id          INTEGER PRIMARY KEY AUTOINCREMENT,
          description TEXT NOT NULL,
          created_at  TEXT DEFAULT (datetime('now')),
          updated_at  TEXT DEFAULT (datetime('now'))
        );

        CREATE TABLE IF NOT EXISTS coordinates (
          id          INTEGER PRIMARY KEY AUTOINCREMENT,
          event_id    INTEGER NOT NULL,
          type        TEXT NOT NULL CHECK(type IN ('temporal', 'geospatial')),
          confidence  REAL CHECK(confidence IS NULL OR (confidence >= 0.0 AND confidence <= 1.0)),
          created_at  TEXT DEFAULT (datetime('now')),
          FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS temporal_data (
          coordinate_id INTEGER PRIMARY KEY,
          start_at      TEXT NOT NULL,
          end_at        TEXT,
          FOREIGN KEY (coordinate_id) REFERENCES coordinates(id) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS geospatial_data (
          coordinate_id INTEGER PRIMARY KEY,
          description   TEXT,
          shape         TEXT NOT NULL CHECK(shape IN ('point', 'area', 'volume')),
          latitude      REAL NOT NULL,
          longitude     REAL NOT NULL,
          altitude      REAL,
          radius_m      REAL,
          floor_alt     REAL,
          ceiling_alt   REAL,
          FOREIGN KEY (coordinate_id) REFERENCES coordinates(id) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS coordinate_references (
          id                  INTEGER PRIMARY KEY AUTOINCREMENT,
          coordinate_id       INTEGER NOT NULL,
          referenced_event_id INTEGER NOT NULL,
          role                TEXT NOT NULL CHECK(role IN ('start', 'end', 'anchor')),
          FOREIGN KEY (coordinate_id) REFERENCES coordinates(id) ON DELETE CASCADE,
          FOREIGN KEY (referenced_event_id) REFERENCES events(id) ON DELETE CASCADE
        );

        CREATE INDEX IF NOT EXISTS idx_coordinates_event_id ON coordinates(event_id);
        CREATE INDEX IF NOT EXISTS idx_coordinates_type ON coordinates(type);
        CREATE INDEX IF NOT EXISTS idx_coordinate_references_event ON coordinate_references(referenced_event_id);
      SQL
    end
  end
end
