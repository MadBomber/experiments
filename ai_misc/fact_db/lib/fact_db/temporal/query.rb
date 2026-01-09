# frozen_string_literal: true

module FactDb
  module Temporal
    class Query
      attr_reader :scope

      def initialize(scope = Models::Fact.all)
        @scope = scope
      end

      def execute(topic: nil, at: nil, entity_id: nil, status: :canonical, limit: nil)
        result = @scope

        # Status filtering
        result = apply_status_filter(result, status)

        # Temporal filtering
        result = apply_temporal_filter(result, at)

        # Entity filtering
        result = apply_entity_filter(result, entity_id)

        # Topic search
        result = apply_topic_search(result, topic)

        # Ordering - most recently valid first
        result = result.order(valid_at: :desc)

        # Limit results
        result = result.limit(limit) if limit

        result
      end

      # Currently valid facts about an entity
      def current_facts(entity_id:)
        execute(entity_id: entity_id, at: nil, status: :canonical)
      end

      # Facts valid at a specific point in time
      def facts_at(date, entity_id: nil)
        execute(at: date, entity_id: entity_id, status: :canonical)
      end

      # Facts that became valid in a date range
      def facts_created_between(from:, to:, entity_id: nil)
        result = @scope.canonical.became_valid_between(from, to)
        result = result.mentioning_entity(entity_id) if entity_id
        result.order(valid_at: :asc)
      end

      # Facts that became invalid in a date range
      def facts_invalidated_between(from:, to:, entity_id: nil)
        result = @scope.became_invalid_between(from, to)
        result = result.mentioning_entity(entity_id) if entity_id
        result.order(invalid_at: :asc)
      end

      # Semantic search with temporal filtering
      def semantic_search(query:, at: nil, entity_id: nil, limit: 20)
        result = @scope.canonical.search_text(query)
        result = apply_temporal_filter(result, at)
        result = result.mentioning_entity(entity_id) if entity_id
        result.limit(limit)
      end

      # Find facts where entity has a specific role
      def facts_with_entity_role(entity_id:, role:, at: nil)
        result = @scope.canonical.with_role(entity_id, role)
        result = apply_temporal_filter(result, at)
        result.order(valid_at: :desc)
      end

      # Compare facts at two points in time
      def diff(entity_id:, from_date:, to_date:)
        facts_at_from = facts_at(from_date, entity_id: entity_id).to_a
        facts_at_to = facts_at(to_date, entity_id: entity_id).to_a

        {
          added: facts_at_to - facts_at_from,
          removed: facts_at_from - facts_at_to,
          unchanged: facts_at_from & facts_at_to
        }
      end

      private

      def apply_status_filter(scope, status)
        case status.to_sym
        when :canonical
          scope.canonical
        when :superseded
          scope.superseded
        when :synthesized
          scope.synthesized
        when :all
          scope
        else
          scope.where(status: status.to_s)
        end
      end

      def apply_temporal_filter(scope, at)
        if at.nil?
          scope.currently_valid
        else
          scope.valid_at(at)
        end
      end

      def apply_entity_filter(scope, entity_id)
        return scope if entity_id.nil?

        scope.mentioning_entity(entity_id)
      end

      def apply_topic_search(scope, topic)
        return scope if topic.nil? || topic.empty?

        scope.search_text(topic)
      end
    end
  end
end
