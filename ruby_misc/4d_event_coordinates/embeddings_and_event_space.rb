#!/usr/bin/env ruby
# embeddings_and_event_space.rb — Where vector embeddings meet event coordinates
#
# Insight: An N-dimensional event (spatial, temporal, spectral, etc.) IS a vector.
# A semantic embedding IS a vector. They operate in the same mathematical space
# and support the same operations: distance, similarity, clustering, search.
#
# The difference:
#   Event coordinates: each dimension is INTERPRETABLE (lat, lon, time, freq)
#   Embeddings:        each dimension is LEARNED (opaque, but captures meaning)
#
# They complement each other:
#   Event coordinates tell you WHERE/WHEN/WHAT with precision
#   Embeddings tell you what it MEANS and what it's SIMILAR TO
#
# Combined, they enable:
#   1. "Find events similar to this one" (embedding similarity)
#   2. "...within 50km and the last 30 days" (coordinate filtering)
#   3. "What usually happens after events like this?" (pattern + prediction)
#   4. Natural language queries against an event database (RAG)
#
# Status: SKETCH / EXPLORATION

module EventEmbeddings

  #############################################
  ## The Conceptual Bridge
  ##
  ## Consider these two representations of the same event:
  ##
  ## Structured (interpretable coordinates):
  ##   { lat: 33.3, lon: 44.4, time: 2026-03-05T04:00,
  ##     freq: 2.5e9, type: :signal_activation }
  ##
  ## Embedding (learned vector):
  ##   [0.234, -0.891, 0.445, ..., 0.112]  # 1536 dimensions
  ##
  ## The structured form lets you do:
  ##   - Exact spatial queries ("within 10km of point X")
  ##   - Temporal range queries ("last 48 hours")
  ##   - Spectral matching ("same frequency band")
  ##
  ## The embedding lets you do:
  ##   - Semantic similarity ("events like this one")
  ##   - Cross-domain correlation ("this SIGINT pattern resembles...")
  ##   - Natural language search ("S-band activations near mosques before Friday prayers")
  ##   - Anomaly detection ("this doesn't match any known pattern")


  #############################################
  ## Hybrid Event Vector
  ##
  ## An event can be represented as BOTH:
  ##   - A structured coordinate tuple (interpretable, queryable)
  ##   - A semantic embedding (similarity, meaning)
  ##
  ## The hybrid vector concatenates or interleaves them.

  class HybridEventVector
    attr_reader :event_id, :coordinates, :embedding, :metadata

    def initialize(event_id:, coordinates:, embedding: nil, metadata: {})
      @event_id    = event_id
      @coordinates = coordinates  # Hash of interpretable dimensions
      @embedding   = embedding    # Array of floats (from LLM/encoder)
      @metadata    = metadata     # description, source, etc.
    end

    # Structured coordinate distance (interpretable)
    # Each dimension has its own distance metric and normalization
    def coordinate_distance(other, weights: {})
      total = 0.0
      count = 0

      @coordinates.each do |dim, value|
        next unless other.coordinates[dim]
        w = weights[dim] || 1.0
        d = dimension_distance(dim, value, other.coordinates[dim])
        next unless d
        total += (d * w) ** 2
        count += 1
      end

      return nil if count == 0
      Math.sqrt(total / count)
    end

    # Semantic similarity (learned, opaque)
    def semantic_similarity(other)
      return nil unless @embedding && other.embedding
      cosine_similarity(@embedding, other.embedding)
    end

    # Hybrid score — combines structured distance with semantic similarity
    # alpha: 0.0 = pure coordinate, 1.0 = pure semantic
    def hybrid_similarity(other, alpha: 0.5, weights: {})
      coord_dist = coordinate_distance(other, weights: weights)
      sem_sim    = semantic_similarity(other)

      if coord_dist && sem_sim
        coord_sim = 1.0 / (1.0 + coord_dist)  # convert distance to similarity
        (1 - alpha) * coord_sim + alpha * sem_sim
      elsif coord_dist
        1.0 / (1.0 + coord_dist)
      elsif sem_sim
        sem_sim
      else
        nil
      end
    end

    private

    def dimension_distance(dim, a, b)
      case dim
      when :latitude, :longitude
        # Degrees, normalized to ~km scale
        (a - b).abs * 111.0  # rough km per degree
      when :time
        # Seconds between times
        (a.to_f - b.to_f).abs / 3600.0  # normalize to hours
      when :frequency_hz
        # Log-scale distance (octaves)
        (Math.log2(a) - Math.log2(b)).abs rescue nil
      when :altitude_m
        (a - b).abs / 1000.0  # normalize to km
      when :bearing_deg
        diff = (a - b).abs % 360
        [diff, 360 - diff].min / 180.0  # normalize to 0-1
      else
        # Generic numeric distance
        (a.to_f - b.to_f).abs rescue nil
      end
    end

    def cosine_similarity(a, b)
      dot = a.zip(b).sum { |x, y| x * y }
      mag_a = Math.sqrt(a.sum { |x| x * x })
      mag_b = Math.sqrt(b.sum { |x| x * x })
      return 0.0 if mag_a == 0 || mag_b == 0
      dot / (mag_a * mag_b)
    end
  end


  #############################################
  ## Use Cases for the Hybrid Approach

  module UseCases
    DESCRIPTIONS = {
      event_similarity: {
        title: "Event Similarity Search",
        description: "Find me events similar to this one",
        how: <<~TEXT,
          Encode each event as a hybrid vector. Query by:
            1. Semantic embedding: "events like this SIGINT intercept"
            2. Coordinate filter: "within 50km and last 30 days"
            3. Ranked by hybrid_similarity score

          Example: Given an IED event, find similar events.
          Two IED attacks at similar locations, similar times of day,
          similar methods cluster together in both coordinate space
          AND embedding space — but embedding also captures patterns
          like "preceded by unusual cell phone activity" that
          coordinates alone can't express.
        TEXT
      },

      natural_language_query: {
        title: "Natural Language Event Queries (RAG)",
        description: "Search an event database using plain English",
        how: <<~TEXT,
          User: "S-band radar activations near mosques before Friday prayers"

          1. Embed the query → query vector
          2. Find semantically similar events in vector DB
          3. Filter by structured coordinates:
             - spectral: S-band (2-4 GHz)
             - spatial: within radius of known mosque locations
             - temporal: Thursday evening / Friday morning
          4. Return ranked results with coordinate details

          The embedding handles the SEMANTIC intent ("before Friday prayers"
          → Thursday night / Friday early morning in Islamic context).
          The coordinates handle the PRECISE filtering (frequency range,
          distance calculation).
        TEXT
      },

      pattern_prediction: {
        title: "Temporal Pattern Prediction",
        description: "What usually happens after events like this?",
        how: <<~TEXT,
          Given a sequence of events, find historical sequences that
          started similarly and see how they ended:

          Current:  Signal activation → troop movement → supply cache found
          Similar:  Signal activation → troop movement → ambush (2019-04-12)
          Similar:  Signal activation → troop movement → IED (2019-06-03)
          Similar:  Signal activation → troop movement → nothing (2019-07-21)

          Prediction: 66% chance of hostile contact following this pattern.

          This is sequence embedding — each event is a vector, and a
          SEQUENCE of events is a trajectory through the vector space.
          Similar trajectories suggest similar outcomes.
        TEXT
      },

      anomaly_detection: {
        title: "Anomaly Detection",
        description: "This doesn't match any known pattern",
        how: <<~TEXT,
          If an event's embedding is far from all known event clusters,
          it's anomalous. If its coordinates are normal but its semantic
          content is unusual (or vice versa), that's a different kind
          of anomaly.

          Types of anomaly:
          - Coordinate anomaly: right type of event, wrong place/time
            "Fire control radar at a location with no known SAM sites"
          - Semantic anomaly: right place/time, wrong type of event
            "Civilian radio traffic using military protocols"
          - Combined anomaly: nothing about this fits
            "Unknown signal type at unusual frequency in empty desert"

          The hybrid vector catches all three.
        TEXT
      },

      cross_domain_correlation: {
        title: "Cross-Domain Correlation",
        description: "Connect events across different collection domains",
        how: <<~TEXT,
          A SIGINT event, a HUMINT report, and a satellite image may all
          describe the same real-world activity. In coordinate space, they
          share spatial and temporal proximity. In embedding space, their
          semantic content aligns despite different source formats.

          SIGINT:  "S-band activation at grid 33.4N 44.3E, 0400 local"
          HUMINT:  "Source reports unusual military vehicle at the mosque"
          IMINT:   "Satellite shows new antenna installation at compound"

          Coordinate overlap: all within 2km, all within 48 hours
          Semantic overlap: all relate to military communications capability

          Neither coordinate matching nor semantic similarity alone would
          confidently link these. Together, they provide high-confidence
          correlation — this is the JISR fusion problem.
        TEXT
      },

      natural_language_to_coordinates: {
        title: "NL → Event Coordinates (replacing the parser)",
        description: "Use embeddings to map English to coordinate vectors",
        how: <<~TEXT,
          Instead of parsing "after Ramadan" with regex or EBNF, use an
          embedding model trained on temporal expressions:

          "after Ramadan"                    → temporal vector near Ramadan end
          "following the end of the holy month" → same temporal vector
          "post-fasting period"              → same temporal vector

          All three map to similar positions in the temporal embedding
          space, even though they're lexically different. This solves
          the parsing problem for free — you don't need to enumerate
          every possible phrasing.

          The embedding captures MEANING, then you extract COORDINATES
          from the embedding's nearest neighbors in your known-event
          database. This is the hybrid approach:
          1. Embed the natural language
          2. Find nearest known temporal references
          3. Extract their structured coordinates
          4. Apply those coordinates to the new event
        TEXT
      },

      plume_and_propagation: {
        title: "Propagation Modeling via Vector Fields",
        description: "How effects spread through dimensional space over time",
        how: <<~TEXT,
          A chemical plume, a radio signal, a disease outbreak, or a rumor
          all propagate through space over time. The propagation is a
          trajectory through the N-dimensional event space:

          Chemical: spatial spread = f(wind vector, time, terrain)
          Radio:    signal strength = f(distance, frequency, obstacles)
          Disease:  infection = f(proximity, time, population density)
          Rumor:    spread = f(social network topology, time, credibility)

          Each can be modeled as a vector field in the event space —
          at each point, a vector indicates the direction and rate of
          propagation. This connects to the impact radius concept:
          the impact isn't a static circle, it's a dynamic surface
          evolving through the dimensional space.
        TEXT
      },
    }

    def self.display
      DESCRIPTIONS.each do |key, info|
        puts "=" * 70
        puts "USE CASE: #{info[:title]}"
        puts "  #{info[:description]}"
        puts "=" * 70
        puts info[:how]
        puts
      end
    end
  end


  #############################################
  ## Example: Similarity search on event vectors

  def self.examples
    puts
    puts "#" * 70
    puts "# EMBEDDINGS MEET EVENT COORDINATES"
    puts "#" * 70
    puts

    # Simulate events with coordinates (no real embeddings — illustrative)
    # In production, embeddings would come from an LLM encoder
    events = [
      HybridEventVector.new(
        event_id: "EVT-001",
        coordinates: {
          latitude: 33.30, longitude: 44.40,
          time: Time.new(2026, 3, 5, 4, 0),
          frequency_hz: 2.5e9,
        },
        embedding: [0.23, -0.89, 0.44, 0.12, 0.67, -0.34, 0.91, -0.55],
        metadata: { description: "S-band signal activation near mosque, 0400" }
      ),
      HybridEventVector.new(
        event_id: "EVT-002",
        coordinates: {
          latitude: 33.32, longitude: 44.38,
          time: Time.new(2026, 3, 5, 4, 15),
          frequency_hz: 2.8e9,
        },
        embedding: [0.21, -0.87, 0.48, 0.15, 0.64, -0.31, 0.88, -0.52],
        metadata: { description: "S-band signal, slightly different freq, 15 min later, 2km away" }
      ),
      HybridEventVector.new(
        event_id: "EVT-003",
        coordinates: {
          latitude: 33.50, longitude: 44.80,
          time: Time.new(2026, 3, 1, 14, 0),
          frequency_hz: 9.5e9,
        },
        embedding: [0.72, 0.11, -0.63, 0.44, -0.28, 0.55, -0.19, 0.83],
        metadata: { description: "X-band fire control radar, different location, 4 days earlier" }
      ),
      HybridEventVector.new(
        event_id: "EVT-004",
        coordinates: {
          latitude: 36.20, longitude: 43.10,
          time: Time.new(2026, 3, 5, 4, 10),
          frequency_hz: 2.6e9,
        },
        embedding: [0.19, -0.85, 0.50, 0.10, 0.62, -0.30, 0.85, -0.50],
        metadata: { description: "S-band activation, same time, but 300km away (Mosul)" }
      ),
    ]

    query = events[0]  # "Find events similar to EVT-001"

    puts "QUERY EVENT: #{query.metadata[:description]}"
    puts "  Coords: %.2f°N %.2f°E, %s, %.1f GHz" % [
      query.coordinates[:latitude],
      query.coordinates[:longitude],
      query.coordinates[:time].strftime('%Y-%m-%d %H:%M'),
      query.coordinates[:frequency_hz] / 1e9
    ]
    puts

    puts "%-10s %-55s %s" % ["Event", "Description", "Scores"]
    puts "-" * 90

    events[1..].each do |evt|
      coord_dist = query.coordinate_distance(evt)
      sem_sim    = query.semantic_similarity(evt)
      hybrid     = query.hybrid_similarity(evt, alpha: 0.5)

      puts "%-10s %-55s coord=%.3f sem=%.3f hybrid=%.3f" % [
        evt.event_id,
        evt.metadata[:description][0..54],
        coord_dist || 0,
        sem_sim || 0,
        hybrid || 0,
      ]
    end

    puts
    puts "ANALYSIS:"
    puts "  EVT-002: Close in ALL dimensions — likely same emitter or coordinated"
    puts "  EVT-003: Far in coordinates AND semantics — different type of event entirely"
    puts "  EVT-004: Semantically similar (same type of signal) but spatially distant"
    puts "           → possibly same actor/network, different location"
    puts "           → this is the insight that ONLY the hybrid approach reveals"
    puts

    puts
    UseCases.display
  end
end


if __FILE__ == $0
  EventEmbeddings.examples
end
