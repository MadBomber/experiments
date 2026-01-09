# frozen_string_literal: true

module FactDb
  module Services
    class EntityService
      attr_reader :config, :resolver

      def initialize(config = FactDb.config)
        @config = config
        @resolver = Resolution::EntityResolver.new(config)
      end

      def create(name, type:, aliases: [], attributes: {}, description: nil)
        embedding = generate_embedding(name)

        entity = Models::Entity.create!(
          canonical_name: name,
          entity_type: type.to_s,
          description: description,
          attributes: attributes,
          resolution_status: "resolved",
          embedding: embedding
        )

        aliases.each do |alias_text|
          entity.add_alias(alias_text)
        end

        entity
      end

      def find(id)
        Models::Entity.find(id)
      end

      def find_by_name(name, type: nil)
        scope = Models::Entity.where(["LOWER(canonical_name) = ?", name.downcase])
        scope = scope.where(entity_type: type) if type
        scope.not_merged.first
      end

      def resolve(name, type: nil)
        @resolver.resolve(name, type: type)
      end

      def resolve_or_create(name, type:, aliases: [], attributes: {})
        resolved = @resolver.resolve(name, type: type)
        return resolved.entity if resolved

        create(name, type: type, aliases: aliases, attributes: attributes)
      end

      def merge(keep_id, merge_id)
        @resolver.merge(keep_id, merge_id)
      end

      def add_alias(entity_id, alias_text, type: nil, confidence: 1.0)
        entity = Models::Entity.find(entity_id)
        entity.add_alias(alias_text, type: type, confidence: confidence)
      end

      def search(query, type: nil, limit: 20)
        scope = Models::Entity.not_merged

        # Search canonical names and aliases
        scope = scope.left_joins(:aliases).where(
          "LOWER(fact_db_entities.canonical_name) LIKE ? OR LOWER(fact_db_entity_aliases.alias_text) LIKE ?",
          "%#{query.downcase}%",
          "%#{query.downcase}%"
        ).distinct

        scope = scope.where(entity_type: type) if type
        scope.limit(limit)
      end

      def semantic_search(query, type: nil, limit: 20)
        embedding = generate_embedding(query)
        return Models::Entity.none unless embedding

        scope = Models::Entity.not_merged.nearest_neighbors(embedding, limit: limit)
        scope = scope.where(entity_type: type) if type
        scope
      end

      def by_type(type)
        Models::Entity.by_type(type).not_merged.order(:canonical_name)
      end

      def people(limit: nil)
        scope = Models::Entity.people.not_merged.order(:canonical_name)
        scope = scope.limit(limit) if limit
        scope
      end

      def organizations(limit: nil)
        scope = Models::Entity.organizations.not_merged.order(:canonical_name)
        scope = scope.limit(limit) if limit
        scope
      end

      def places(limit: nil)
        scope = Models::Entity.places.not_merged.order(:canonical_name)
        scope = scope.limit(limit) if limit
        scope
      end

      def facts_about(entity_id, at: nil, status: :canonical)
        Temporal::Query.new.execute(
          entity_id: entity_id,
          at: at,
          status: status
        )
      end

      def timeline_for(entity_id, from: nil, to: nil)
        Temporal::Timeline.new.build(entity_id: entity_id, from: from, to: to)
      end

      def find_duplicates(threshold: nil)
        @resolver.find_duplicates(threshold: threshold)
      end

      def auto_merge_duplicates!
        @resolver.auto_merge_duplicates!
      end

      def stats
        {
          total_count: Models::Entity.not_merged.count,
          by_type: Models::Entity.not_merged.group(:entity_type).count,
          merged_count: Models::Entity.where(resolution_status: "merged").count,
          with_facts: Models::Entity.joins(:entity_mentions).distinct.count
        }
      end

      private

      def generate_embedding(text)
        return nil unless config.embedding_generator

        config.embedding_generator.call(text)
      rescue StandardError => e
        config.logger&.warn("Failed to generate embedding: #{e.message}")
        nil
      end
    end
  end
end
