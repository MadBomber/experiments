# frozen_string_literal: true

module FactDb
  module Resolution
    class EntityResolver
      attr_reader :config

      def initialize(config = FactDb.config)
        @config = config
        @threshold = config.fuzzy_match_threshold
        @auto_merge_threshold = config.auto_merge_threshold
      end

      # Resolve a name to an entity
      def resolve(name, type: nil)
        return nil if name.nil? || name.empty?

        # 1. Exact alias match
        exact = find_by_exact_alias(name, type: type)
        return ResolvedEntity.new(exact, confidence: 1.0, match_type: :exact_alias) if exact

        # 2. Canonical name match
        canonical = find_by_canonical_name(name, type: type)
        return ResolvedEntity.new(canonical, confidence: 1.0, match_type: :canonical_name) if canonical

        # 3. Fuzzy matching
        fuzzy = find_by_fuzzy_match(name, type: type)
        return fuzzy if fuzzy && fuzzy.confidence >= @threshold

        # 4. No match found
        nil
      end

      # Resolve or create an entity
      def resolve_or_create(name, type:, aliases: [], attributes: {})
        resolved = resolve(name, type: type)
        return resolved.entity if resolved

        create_entity(name, type: type, aliases: aliases, attributes: attributes)
      end

      # Merge two entities, keeping one as canonical
      def merge(keep_id, merge_id)
        keep = Models::Entity.find(keep_id)
        merge_entity = Models::Entity.find(merge_id)

        raise ResolutionError, "Cannot merge entity into itself" if keep_id == merge_id
        raise ResolutionError, "Cannot merge already merged entity" if merge_entity.merged?

        Models::Entity.transaction do
          # Move all aliases to kept entity
          merge_entity.aliases.each do |alias_record|
            keep.aliases.find_or_create_by!(alias_text: alias_record.alias_text) do |a|
              a.alias_type = alias_record.alias_type
              a.confidence = alias_record.confidence
            end
          end

          # Add the merged entity's canonical name as an alias
          keep.aliases.find_or_create_by!(alias_text: merge_entity.canonical_name) do |a|
            a.alias_type = "name"
            a.confidence = 1.0
          end

          # Update all entity mentions to point to kept entity
          Models::EntityMention.where(entity_id: merge_id).update_all(entity_id: keep_id)

          # Mark merged entity
          merge_entity.update!(
            resolution_status: "merged",
            merged_into_id: keep_id
          )
        end

        keep.reload
      end

      # Split an entity into multiple entities
      def split(entity_id, split_configs)
        original = Models::Entity.find(entity_id)

        Models::Entity.transaction do
          new_entities = split_configs.map do |config|
            create_entity(
              config[:name],
              type: config[:type] || original.entity_type,
              aliases: config[:aliases] || [],
              attributes: config[:attributes] || {}
            )
          end

          original.update!(resolution_status: "split")

          new_entities
        end
      end

      # Find potential duplicate entities
      def find_duplicates(threshold: nil)
        threshold ||= @threshold
        duplicates = []

        entities = Models::Entity.resolved.to_a

        entities.each_with_index do |entity, i|
          entities[(i + 1)..].each do |other|
            similarity = calculate_similarity(entity.canonical_name, other.canonical_name)
            if similarity >= threshold
              duplicates << {
                entity1: entity,
                entity2: other,
                similarity: similarity
              }
            end
          end
        end

        duplicates.sort_by { |d| -d[:similarity] }
      end

      # Auto-merge high-confidence duplicates
      def auto_merge_duplicates!
        duplicates = find_duplicates(threshold: @auto_merge_threshold)

        duplicates.each do |dup|
          next if dup[:entity1].merged? || dup[:entity2].merged?

          # Keep the entity with more mentions
          keep, merge_entity = if dup[:entity1].entity_mentions.count >= dup[:entity2].entity_mentions.count
                                 [dup[:entity1], dup[:entity2]]
                               else
                                 [dup[:entity2], dup[:entity1]]
                               end

          merge(keep.id, merge_entity.id)
        end
      end

      private

      def find_by_exact_alias(name, type:)
        scope = Models::EntityAlias.where(["LOWER(alias_text) = ?", name.downcase])
        scope = scope.joins(:entity).where(fact_db_entities: { entity_type: type }) if type
        scope = scope.joins(:entity).where.not(fact_db_entities: { resolution_status: "merged" })
        scope.first&.entity
      end

      def find_by_canonical_name(name, type:)
        scope = Models::Entity.where(["LOWER(canonical_name) = ?", name.downcase])
        scope = scope.where(entity_type: type) if type
        scope.not_merged.first
      end

      def find_by_fuzzy_match(name, type:)
        candidates = Models::Entity.not_merged
        candidates = candidates.where(entity_type: type) if type

        best_match = nil
        best_similarity = 0

        candidates.find_each do |entity|
          # Check canonical name
          similarity = calculate_similarity(name, entity.canonical_name)
          if similarity > best_similarity
            best_similarity = similarity
            best_match = entity
          end

          # Check aliases
          entity.aliases.each do |alias_record|
            alias_similarity = calculate_similarity(name, alias_record.alias_text)
            if alias_similarity > best_similarity
              best_similarity = alias_similarity
              best_match = entity
            end
          end
        end

        return nil if best_match.nil? || best_similarity < @threshold

        ResolvedEntity.new(best_match, confidence: best_similarity, match_type: :fuzzy)
      end

      def create_entity(name, type:, aliases: [], attributes: {})
        entity = Models::Entity.create!(
          canonical_name: name,
          entity_type: type,
          attributes: attributes,
          resolution_status: "resolved"
        )

        aliases.each do |alias_text|
          entity.add_alias(alias_text)
        end

        entity
      end

      def calculate_similarity(a, b)
        return 1.0 if a.downcase == b.downcase

        max_len = [a.length, b.length].max
        return 1.0 if max_len.zero?

        1.0 - (levenshtein_distance(a.downcase, b.downcase).to_f / max_len)
      end

      def levenshtein_distance(a, b)
        m = a.length
        n = b.length
        d = Array.new(m + 1) { |i| i }

        (1..n).each do |j|
          prev = d[0]
          d[0] = j
          (1..m).each do |i|
            temp = d[i]
            d[i] = if a[i - 1] == b[j - 1]
                     prev
                   else
                     [prev + 1, d[i] + 1, d[i - 1] + 1].min
                   end
            prev = temp
          end
        end

        d[m]
      end
    end

    class ResolvedEntity
      attr_reader :entity, :confidence, :match_type

      def initialize(entity, confidence:, match_type:)
        @entity = entity
        @confidence = confidence
        @match_type = match_type
      end

      def exact_match?
        confidence == 1.0
      end

      def fuzzy_match?
        match_type == :fuzzy
      end

      def id
        entity.id
      end

      def canonical_name
        entity.canonical_name
      end
    end
  end
end
