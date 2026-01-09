# frozen_string_literal: true

module FactDb
  module Services
    class FactService
      attr_reader :config, :resolver, :entity_service

      def initialize(config = FactDb.config)
        @config = config
        @resolver = Resolution::FactResolver.new(config)
        @entity_service = EntityService.new(config)
      end

      def create(text, valid_at:, invalid_at: nil, status: :canonical, source_content_id: nil, mentions: [], extraction_method: :manual, confidence: 1.0, metadata: {})
        embedding = generate_embedding(text)

        fact = Models::Fact.create!(
          fact_text: text,
          valid_at: valid_at,
          invalid_at: invalid_at,
          status: status.to_s,
          extraction_method: extraction_method.to_s,
          confidence: confidence,
          metadata: metadata,
          embedding: embedding
        )

        # Link to source content
        if source_content_id
          content = Models::Content.find(source_content_id)
          fact.add_source(content: content, type: "primary")
        end

        # Add entity mentions
        mentions.each do |mention|
          entity = resolve_or_create_entity(mention)
          fact.add_mention(
            entity: entity,
            text: mention[:text] || mention[:name],
            role: mention[:role],
            confidence: mention[:confidence] || 1.0
          )
        end

        fact
      end

      def find(id)
        Models::Fact.find(id)
      end

      def extract_from_content(content_id, extractor: config.default_extractor)
        content = Models::Content.find(content_id)
        extractor_instance = Extractors::Base.for(extractor, config)

        extracted = extractor_instance.extract(
          content.raw_text,
          { captured_at: content.captured_at }
        )

        extracted.map do |fact_data|
          create(
            fact_data[:text],
            valid_at: fact_data[:valid_at],
            invalid_at: fact_data[:invalid_at],
            source_content_id: content_id,
            mentions: fact_data[:mentions],
            extraction_method: fact_data[:extraction_method] || extractor,
            confidence: fact_data[:confidence] || 1.0,
            metadata: fact_data[:metadata] || {}
          )
        end
      end

      def query(topic: nil, at: nil, entity: nil, status: :canonical, limit: nil)
        Temporal::Query.new.execute(
          topic: topic,
          at: at,
          entity_id: entity,
          status: status,
          limit: limit
        )
      end

      def current_facts(entity: nil, topic: nil, limit: nil)
        query(topic: topic, entity: entity, at: nil, status: :canonical, limit: limit)
      end

      def facts_at(date, entity: nil, topic: nil)
        query(topic: topic, entity: entity, at: date, status: :canonical)
      end

      def timeline(entity_id:, from: nil, to: nil)
        Temporal::Timeline.new.build(entity_id: entity_id, from: from, to: to)
      end

      def supersede(old_fact_id, new_fact_text, valid_at:, mentions: [])
        @resolver.supersede(old_fact_id, new_fact_text, valid_at: valid_at, mentions: mentions)
      end

      def synthesize(source_fact_ids, synthesized_text, valid_at:, invalid_at: nil, mentions: [])
        @resolver.synthesize(source_fact_ids, synthesized_text, valid_at: valid_at, invalid_at: invalid_at, mentions: mentions)
      end

      def invalidate(fact_id, at: Time.current)
        @resolver.invalidate(fact_id, at: at)
      end

      def corroborate(fact_id, corroborating_fact_id)
        @resolver.corroborate(fact_id, corroborating_fact_id)
      end

      def search(query, entity: nil, status: :canonical, limit: 20)
        scope = Models::Fact.search_text(query)
        scope = apply_filters(scope, entity: entity, status: status)
        scope.order(valid_at: :desc).limit(limit)
      end

      def semantic_search(query, entity: nil, at: nil, limit: 20)
        embedding = generate_embedding(query)
        return Models::Fact.none unless embedding

        scope = Models::Fact.canonical.nearest_neighbors(embedding, limit: limit * 2)
        scope = scope.currently_valid if at.nil?
        scope = scope.valid_at(at) if at
        scope = scope.mentioning_entity(entity) if entity
        scope.limit(limit)
      end

      def find_conflicts(entity_id: nil, topic: nil)
        @resolver.find_conflicts(entity_id: entity_id, topic: topic)
      end

      def resolve_conflict(keep_fact_id, supersede_fact_ids, reason: nil)
        @resolver.resolve_conflict(keep_fact_id, supersede_fact_ids, reason: reason)
      end

      def build_timeline_fact(entity_id:, topic: nil)
        @resolver.build_timeline_fact(entity_id: entity_id, topic: topic)
      end

      def recent(limit: 10, status: :canonical)
        scope = Models::Fact.where(status: status.to_s).order(created_at: :desc)
        scope.limit(limit)
      end

      def by_extraction_method(method, limit: nil)
        scope = Models::Fact.extracted_by(method.to_s).order(created_at: :desc)
        scope = scope.limit(limit) if limit
        scope
      end

      def stats
        {
          total_count: Models::Fact.count,
          canonical_count: Models::Fact.canonical.count,
          currently_valid_count: Models::Fact.canonical.currently_valid.count,
          by_status: Models::Fact.group(:status).count,
          by_extraction_method: Models::Fact.group(:extraction_method).count,
          average_confidence: Models::Fact.average(:confidence)&.to_f&.round(3)
        }
      end

      private

      def resolve_or_create_entity(mention)
        name = mention[:name]
        type = mention[:type]&.to_sym || :concept

        @entity_service.resolve_or_create(name, type: type)
      end

      def apply_filters(scope, entity: nil, status: nil)
        scope = scope.mentioning_entity(entity) if entity
        scope = scope.where(status: status.to_s) if status && status != :all
        scope
      end

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
