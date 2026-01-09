# frozen_string_literal: true

require "active_record"
require "digest"

require_relative "fact_db/version"
require_relative "fact_db/errors"
require_relative "fact_db/config"
require_relative "fact_db/database"

# Models
require_relative "fact_db/models/content"
require_relative "fact_db/models/entity"
require_relative "fact_db/models/entity_alias"
require_relative "fact_db/models/fact"
require_relative "fact_db/models/entity_mention"
require_relative "fact_db/models/fact_source"

# Temporal queries
require_relative "fact_db/temporal/query"
require_relative "fact_db/temporal/timeline"

# Resolution
require_relative "fact_db/resolution/entity_resolver"
require_relative "fact_db/resolution/fact_resolver"

# Extractors
require_relative "fact_db/extractors/base"
require_relative "fact_db/extractors/manual_extractor"
require_relative "fact_db/extractors/llm_extractor"
require_relative "fact_db/extractors/rule_based_extractor"

# LLM Integration
require_relative "fact_db/llm/adapter"

# Pipeline (concurrent processing)
require_relative "fact_db/pipeline/extraction_pipeline"
require_relative "fact_db/pipeline/resolution_pipeline"

# Services
require_relative "fact_db/services/content_service"
require_relative "fact_db/services/entity_service"
require_relative "fact_db/services/fact_service"

module FactDb
  class Clock
    attr_reader :config, :content_service, :entity_service, :fact_service,
                :extraction_pipeline, :resolution_pipeline

    def initialize(config: nil)
      @config = config || FactDb.config
      Database.establish_connection!(@config)

      @content_service = Services::ContentService.new(@config)
      @entity_service = Services::EntityService.new(@config)
      @fact_service = Services::FactService.new(@config)
      @extraction_pipeline = Pipeline::ExtractionPipeline.new(@config)
      @resolution_pipeline = Pipeline::ResolutionPipeline.new(@config)
    end

    # Ingest raw content into the event clock
    def ingest(raw_text, type:, captured_at: Time.current, metadata: {}, title: nil, source_uri: nil)
      @content_service.create(
        raw_text,
        type: type,
        captured_at: captured_at,
        metadata: metadata,
        title: title,
        source_uri: source_uri
      )
    end

    # Extract facts from content
    def extract_facts(content_id, extractor: @config.default_extractor)
      @fact_service.extract_from_content(content_id, extractor: extractor)
    end

    # Query facts with temporal and entity filtering
    def query_facts(topic: nil, at: nil, entity: nil, status: :canonical)
      @fact_service.query(topic: topic, at: at, entity: entity, status: status)
    end

    # Resolve a name to an entity
    def resolve_entity(name, type: nil)
      @entity_service.resolve(name, type: type)
    end

    # Build a timeline for an entity
    def timeline_for(entity_id, from: nil, to: nil)
      @fact_service.timeline(entity_id: entity_id, from: from, to: to)
    end

    # Get currently valid facts about an entity
    def current_facts_for(entity_id)
      query_facts(entity: entity_id, at: nil, status: :canonical)
    end

    # Get facts valid at a specific point in time
    def facts_at(at, entity: nil, topic: nil)
      query_facts(at: at, entity: entity, topic: topic, status: :canonical)
    end

    # Batch extract facts from multiple content items
    #
    # @param content_ids [Array<Integer>] Content IDs to process
    # @param extractor [Symbol] Extractor type (:manual, :llm, :rule_based)
    # @param parallel [Boolean] Whether to use parallel processing
    # @return [Array<Hash>] Results with extracted facts per content
    def batch_extract(content_ids, extractor: @config.default_extractor, parallel: true)
      contents = Models::Content.where(id: content_ids).to_a
      if parallel
        @extraction_pipeline.process_parallel(contents, extractor: extractor)
      else
        @extraction_pipeline.process(contents, extractor: extractor)
      end
    end

    # Batch resolve entity names
    #
    # @param names [Array<String>] Entity names to resolve
    # @param type [Symbol, nil] Entity type filter
    # @return [Array<Hash>] Resolution results
    def batch_resolve_entities(names, type: nil)
      @resolution_pipeline.resolve_entities(names, type: type)
    end

    # Detect fact conflicts for multiple entities
    #
    # @param entity_ids [Array<Integer>] Entity IDs to check
    # @return [Array<Hash>] Conflict detection results
    def detect_fact_conflicts(entity_ids)
      @resolution_pipeline.detect_conflicts(entity_ids)
    end
  end

  class << self
    def new(**options)
      Clock.new(**options)
    end
  end
end
