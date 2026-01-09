# frozen_string_literal: true

module FactDb
  module Temporal
    class Timeline
      attr_reader :events

      def initialize
        @events = []
      end

      def build(entity_id:, from: nil, to: nil)
        facts = fetch_facts(entity_id, from, to)
        @events = facts.map { |fact| TimelineEvent.new(fact) }
        self
      end

      def to_a
        @events.sort_by(&:valid_at)
      end

      def to_hash
        to_a.map(&:to_hash)
      end

      # Group events by year
      def by_year
        to_a.group_by { |event| event.valid_at.year }
      end

      # Group events by month
      def by_month
        to_a.group_by { |event| event.valid_at.strftime("%Y-%m") }
      end

      # Get events in a specific date range
      def between(from, to)
        to_a.select { |event| event.valid_at >= from && event.valid_at <= to }
      end

      # Get currently active events
      def active
        to_a.select(&:currently_valid?)
      end

      # Get historical (no longer valid) events
      def historical
        to_a.reject(&:currently_valid?)
      end

      # Find overlapping events
      def overlapping
        result = []
        sorted = to_a

        sorted.each_with_index do |event, i|
          sorted[(i + 1)..].each do |other|
            result << [event, other] if events_overlap?(event, other)
          end
        end

        result
      end

      # Get the state at a specific point in time
      def state_at(date)
        to_a.select { |event| event.valid_at?(date) }
      end

      # Generate a summary of changes
      def changes_summary
        sorted = to_a

        sorted.each_cons(2).map do |prev_event, next_event|
          {
            from: prev_event,
            to: next_event,
            gap_days: (next_event.valid_at.to_date - (prev_event.invalid_at || prev_event.valid_at).to_date).to_i
          }
        end
      end

      private

      def fetch_facts(entity_id, from, to)
        scope = Models::Fact.mentioning_entity(entity_id).order(valid_at: :asc)
        scope = scope.where("valid_at >= ?", from) if from
        scope = scope.where("valid_at <= ?", to) if to
        scope
      end

      def events_overlap?(event1, event2)
        return false if event1.invalid_at && event1.invalid_at <= event2.valid_at
        return false if event2.invalid_at && event2.invalid_at <= event1.valid_at

        true
      end
    end

    class TimelineEvent
      attr_reader :fact

      delegate :id, :fact_text, :valid_at, :invalid_at, :status,
               :currently_valid?, :valid_at?, :duration, :duration_days,
               :entities, :source_contents, to: :fact

      def initialize(fact)
        @fact = fact
      end

      def to_hash
        {
          id: id,
          fact: fact_text,
          valid_at: valid_at,
          invalid_at: invalid_at,
          status: status,
          duration_days: duration_days,
          entities: entities.map(&:canonical_name)
        }
      end

      def <=>(other)
        valid_at <=> other.valid_at
      end
    end
  end
end
