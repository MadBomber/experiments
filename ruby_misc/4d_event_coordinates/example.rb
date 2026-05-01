#!/usr/bin/env ruby
# example.rb — Demonstrates the Event Coordinates domain model with SQLite persistence

require_relative 'lib/event_coordinates'

include EventCoordinates

# Use in-memory DB for demo; pass a file path for persistence
# e.g., Database.new('events.db')
database = Database.new
repo     = Repository.new(database)

puts "=" * 60
puts "EVENT COORDINATES — Domain Model Demo"
puts "=" * 60
puts

# --- 1. Simple event: point in time, point in space ---

dentist = repo.save_event(Event.new(
  description: "Dentist appointment",
  coordinates: [
    Coordinate.new(
      type: 'temporal',
      confidence: 1.0,
      data: Temporal.new(start_at: Time.new(2026, 3, 15, 14, 30))
    ),
    Coordinate.new(
      type: 'geospatial',
      confidence: 1.0,
      data: Geospatial.new(latitude: 32.3513, longitude: -95.3011)
    ),
  ]
))

puts "1. #{dentist}"
puts

# --- 2. Named anchor events (for referencing) ---

christmas = repo.save_event(Event.new(
  description: "Christmas",
  coordinates: [
    Coordinate.new(
      type: 'temporal',
      confidence: 1.0,
      data: Temporal.new(start_at: Time.new(2026, 12, 25))
    ),
  ]
))

new_years = repo.save_event(Event.new(
  description: "New Years Day",
  coordinates: [
    Coordinate.new(
      type: 'temporal',
      confidence: 1.0,
      data: Temporal.new(start_at: Time.new(2027, 1, 1))
    ),
  ]
))

# --- 3. Event with coordinates referencing other events ---

vacation = repo.save_event(Event.new(
  description: "Family vacation",
  coordinates: [
    Coordinate.new(
      type: 'temporal',
      confidence: 1.0,
      data: Temporal.new(
        start_at: Time.new(2026, 12, 26),  # day after Christmas
        end_at:   Time.new(2027, 1, 5)     # first Monday after New Years
      ),
      references: [
        { event_id: christmas.id, role: 'start' },
        { event_id: new_years.id, role: 'end' },
      ]
    ),
    Coordinate.new(
      type: 'geospatial',
      confidence: 0.3,
      data: Geospatial.new(latitude: 42.5, longitude: 12.5, radius_m: 500_000),
      # Europe, somewhere — low confidence
    ),
  ]
))

puts "2. #{vacation}"
puts

# --- 4. Fuzzy event: uncertain time and place ---

attack_intel = repo.save_event(Event.new(
  description: "Expected insurgent attack",
  coordinates: [
    Coordinate.new(
      type: 'temporal',
      confidence: 0.4,
      data: Temporal.new(
        start_at: Time.new(2026, 3, 19),  # after Ramadan ends
        end_at:   Time.new(2026, 12, 31)  # open-ended (capped at year)
      ),
    ),
    Coordinate.new(
      type: 'geospatial',
      confidence: 0.3,
      data: Geospatial.new(latitude: 33.4, longitude: 43.3, radius_m: 150_000),
    ),
  ]
))

puts "3. #{attack_intel}"
puts "   Min confidence: #{attack_intel.min_confidence}"
puts

# --- 5. 3D point: specific floor of a building ---

shooting = repo.save_event(Event.new(
  description: "Shots fired, 3rd floor",
  coordinates: [
    Coordinate.new(
      type: 'temporal',
      confidence: 1.0,
      data: Temporal.new(start_at: Time.new(2026, 3, 5, 14, 15))
    ),
    Coordinate.new(
      type: 'geospatial',
      confidence: 0.9,
      data: Geospatial.new(latitude: 33.315, longitude: 44.395, altitude: 41.0),
    ),
  ]
))

puts "4. #{shooting}"
puts

# --- 6. Volume: restricted airspace ---

airspace = repo.save_event(Event.new(
  description: "Restricted airspace",
  coordinates: [
    Coordinate.new(
      type: 'temporal',
      confidence: 1.0,
      data: Temporal.new(
        start_at: Time.new(2026, 3, 10, 6, 0),
        end_at:   Time.new(2026, 3, 10, 18, 0)
      )
    ),
    Coordinate.new(
      type: 'geospatial',
      confidence: 1.0,
      data: Geospatial.new(
        latitude: 33.3, longitude: 44.4,
        radius_m: 50_000,
        floor_alt: 0, ceiling_alt: 10_000
      ),
    ),
  ]
))

puts "5. #{airspace}"
puts

# --- 7. Multiple geospatial coords: road trip ---

road_trip = repo.save_event(Event.new(
  description: "Road trip Tyler to Houston",
  coordinates: [
    Coordinate.new(
      type: 'temporal',
      confidence: 0.7,
      data: Temporal.new(
        start_at: Time.new(2026, 7, 10),
        end_at:   Time.new(2026, 7, 10, 14, 0)
      )
    ),
    Coordinate.new(
      type: 'geospatial',
      confidence: 1.0,
      data: Geospatial.new(latitude: 32.35, longitude: -95.30),
    ),
    Coordinate.new(
      type: 'geospatial',
      confidence: 1.0,
      data: Geospatial.new(latitude: 29.76, longitude: -95.37),
    ),
  ]
))

puts "6. #{road_trip}"
puts

# --- Queries ---

puts "=" * 60
puts "QUERIES"
puts "=" * 60
puts

puts "Total events: #{repo.event_count}"
puts "Total coordinates: #{repo.coordinate_count}"
puts

# Find events near Tyler, TX (within 50km)
puts "Events near Tyler, TX (50km):"
repo.find_events_near(32.35, -95.30, 50_000).each do |e|
  puts "  #{e.description}"
end
puts

# Find events in March 2026
puts "Events in March 2026:"
repo.find_events_in_timerange(
  Time.new(2026, 3, 1), Time.new(2026, 3, 31)
).each do |e|
  puts "  #{e.description}"
end
puts

# Find events referencing Christmas
puts "Events referencing Christmas:"
repo.find_referencing_events(christmas.id).each do |e|
  puts "  #{e.description}"
end
puts

# Search by description
puts "Events matching 'attack':"
repo.find_events_by_description('attack').each do |e|
  puts "  #{e.description} (min confidence: #{e.min_confidence})"
end
puts

# --- Persistence demo ---

puts "=" * 60
puts "PERSISTENCE"
puts "=" * 60
puts

# Save to file, reopen, verify
file_db = Database.new('/tmp/event_coordinates_demo.db')
file_repo = Repository.new(file_db)

file_repo.save_event(Event.new(
  description: "Persisted event",
  coordinates: [
    Coordinate.new(
      type: 'temporal',
      confidence: 0.8,
      data: Temporal.new(start_at: Time.new(2026, 6, 15, 9, 0))
    ),
    Coordinate.new(
      type: 'geospatial',
      confidence: 1.0,
      data: Geospatial.new(latitude: 32.35, longitude: -95.30)
    ),
  ]
))
file_db.close

# Reopen and read back
file_db2 = Database.new('/tmp/event_coordinates_demo.db')
file_repo2 = Repository.new(file_db2)

puts "Reopened database:"
file_repo2.all_events.each do |e|
  puts "  #{e}"
end
file_db2.close

# Cleanup
File.delete('/tmp/event_coordinates_demo.db')
puts
puts "Done."
