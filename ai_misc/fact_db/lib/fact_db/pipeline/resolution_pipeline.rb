# frozen_string_literal: true

require "simple_flow"

module FactDb
  module Pipeline
    # Pipeline for resolving entities and facts using SimpleFlow
    # Supports parallel resolution of multiple items
    #
    # @example Resolve entities in parallel
    #   pipeline = ResolutionPipeline.new(config)
    #   results = pipeline.resolve_entities(["John Smith", "Jane Doe", "Acme Corp"])
    #
    class ResolutionPipeline
      attr_reader :config, :entity_resolver, :fact_resolver

      def initialize(config = FactDb.config)
        @config = config
        @entity_resolver = Resolution::EntityResolver.new(config)
        @fact_resolver = Resolution::FactResolver.new(config)
      end

      # Resolve multiple entity names in parallel
      #
      # @param names [Array<String>] Entity names to resolve
      # @param type [Symbol, nil] Entity type filter
      # @return [Array<Hash>] Resolution results
      def resolve_entities(names, type: nil)
        pipeline = build_entity_resolution_pipeline(names, type)
        initial_result = SimpleFlow::Result.new(names: names, resolved: {})

        final_result = pipeline.call(initial_result)

        names.map do |name|
          resolution = final_result.value[:resolved][name]
          {
            name: name,
            entity: resolution&.dig(:entity),
            status: resolution&.dig(:status) || :failed,
            error: resolution&.dig(:error)
          }
        end
      end

      # Find and resolve conflicts for multiple entities in parallel
      #
      # @param entity_ids [Array<Integer>] Entity IDs to check for conflicts
      # @return [Array<Hash>] Conflict detection results
      def detect_conflicts(entity_ids)
        pipeline = build_conflict_detection_pipeline(entity_ids)
        initial_result = SimpleFlow::Result.new(entity_ids: entity_ids, conflicts: {})

        final_result = pipeline.call(initial_result)

        entity_ids.map do |entity_id|
          conflicts = final_result.value[:conflicts][entity_id]
          {
            entity_id: entity_id,
            conflicts: conflicts || [],
            conflict_count: conflicts&.size || 0
          }
        end
      end

      private

      def build_entity_resolution_pipeline(names, type)
        resolver = @entity_resolver

        SimpleFlow::Pipeline.new do
          # Create parallel resolution steps
          names.each do |name|
            step "resolve_#{name.hash.abs}", depends_on: [] do |result|
              begin
                entity = resolver.resolve(name, type: type)
                status = entity ? :resolved : :not_found

                new_resolved = result.value[:resolved].merge(
                  name => { entity: entity, status: status, error: nil }
                )
                result.continue(result.value.merge(resolved: new_resolved))
              rescue StandardError => e
                new_resolved = result.value[:resolved].merge(
                  name => { entity: nil, status: :error, error: e.message }
                )
                result.continue(result.value.merge(resolved: new_resolved))
              end
            end
          end

          # Aggregate
          step "aggregate", depends_on: names.map { |n| "resolve_#{n.hash.abs}" } do |result|
            result.continue(result.value)
          end
        end
      end

      def build_conflict_detection_pipeline(entity_ids)
        resolver = @fact_resolver

        SimpleFlow::Pipeline.new do
          # Create parallel conflict detection steps
          entity_ids.each do |entity_id|
            step "conflicts_#{entity_id}", depends_on: [] do |result|
              begin
                conflicts = resolver.find_conflicts(entity_id: entity_id)

                new_conflicts = result.value[:conflicts].merge(
                  entity_id => conflicts
                )
                result.continue(result.value.merge(conflicts: new_conflicts))
              rescue StandardError
                new_conflicts = result.value[:conflicts].merge(
                  entity_id => []
                )
                result.continue(result.value.merge(conflicts: new_conflicts))
              end
            end
          end

          # Aggregate
          step "aggregate", depends_on: entity_ids.map { |id| "conflicts_#{id}" } do |result|
            result.continue(result.value)
          end
        end
      end
    end
  end
end
