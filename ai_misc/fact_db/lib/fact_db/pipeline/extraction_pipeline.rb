# frozen_string_literal: true

require "simple_flow"

module FactDb
  module Pipeline
    # Pipeline for extracting facts from content using SimpleFlow
    # Supports parallel processing of multiple content items
    #
    # @example Sequential extraction
    #   pipeline = ExtractionPipeline.new(config)
    #   results = pipeline.process([content1, content2], extractor: :llm)
    #
    # @example Parallel extraction
    #   pipeline = ExtractionPipeline.new(config)
    #   results = pipeline.process_parallel([content1, content2, content3], extractor: :llm)
    #
    class ExtractionPipeline
      attr_reader :config

      def initialize(config = FactDb.config)
        @config = config
      end

      # Process multiple content items sequentially
      #
      # @param contents [Array<Models::Content>] Content records to process
      # @param extractor [Symbol] Extractor type (:manual, :llm, :rule_based)
      # @return [Array<Hash>] Results with extracted facts per content
      def process(contents, extractor: config.default_extractor)
        pipeline = build_extraction_pipeline(extractor)

        contents.map do |content|
          result = pipeline.call(SimpleFlow::Result.new(content))
          {
            content_id: content.id,
            facts: result.success? ? result.value : [],
            error: result.halted? ? result.error : nil
          }
        end
      end

      # Process multiple content items in parallel
      # Uses SimpleFlow's parallel execution capabilities
      #
      # @param contents [Array<Models::Content>] Content records to process
      # @param extractor [Symbol] Extractor type (:manual, :llm, :rule_based)
      # @return [Array<Hash>] Results with extracted facts per content
      def process_parallel(contents, extractor: config.default_extractor)
        pipeline = build_parallel_pipeline(contents, extractor)
        initial_result = SimpleFlow::Result.new(contents: contents, results: {})

        final_result = pipeline.call(initial_result)

        contents.map do |content|
          result = final_result.value[:results][content.id]
          {
            content_id: content.id,
            facts: result&.dig(:facts) || [],
            error: result&.dig(:error)
          }
        end
      end

      private

      def build_extraction_pipeline(extractor)
        extractor_instance = get_extractor(extractor)

        SimpleFlow::Pipeline.new do
          # Step 1: Validate content
          step ->(result) {
            content = result.value
            if content.nil? || content.raw_text.blank?
              result.halt("Content is empty or missing")
            else
              result.continue(content)
            end
          }

          # Step 2: Extract facts
          step ->(result) {
            content = result.value
            begin
              facts = extractor_instance.extract(content)
              result.continue(facts)
            rescue StandardError => e
              result.halt("Extraction failed: #{e.message}")
            end
          }

          # Step 3: Validate extracted facts
          step ->(result) {
            facts = result.value
            valid_facts = facts.select { |f| f.valid? }
            result.continue(valid_facts)
          }
        end
      end

      def build_parallel_pipeline(contents, extractor)
        extractor_instance = get_extractor(extractor)

        SimpleFlow::Pipeline.new do
          # Create a step for each content item
          contents.each do |content|
            step "extract_#{content.id}", depends_on: [] do |result|
              begin
                facts = extractor_instance.extract(content)
                valid_facts = facts.select { |f| f.valid? }

                new_results = result.value[:results].merge(
                  content.id => { facts: valid_facts, error: nil }
                )
                result.continue(result.value.merge(results: new_results))
              rescue StandardError => e
                new_results = result.value[:results].merge(
                  content.id => { facts: [], error: e.message }
                )
                result.continue(result.value.merge(results: new_results))
              end
            end
          end

          # Aggregate results
          step "aggregate", depends_on: contents.map { |c| "extract_#{c.id}" } do |result|
            result.continue(result.value)
          end
        end
      end

      def get_extractor(extractor)
        case extractor.to_sym
        when :manual
          Extractors::ManualExtractor.new(config)
        when :llm
          Extractors::LLMExtractor.new(config)
        when :rule_based
          Extractors::RuleBasedExtractor.new(config)
        else
          raise ConfigurationError, "Unknown extractor: #{extractor}"
        end
      end
    end
  end
end
