# frozen_string_literal: true

module FactDb
  module Extractors
    class Base
      attr_reader :config

      def initialize(config = FactDb.config)
        @config = config
      end

      # Extract facts from text
      # @param text [String] Raw text to extract from
      # @param context [Hash] Additional context (captured_at, source_uri, etc.)
      # @return [Array<Hash>] Array of fact data hashes
      def extract(text, context = {})
        raise NotImplementedError, "#{self.class} must implement #extract"
      end

      # Extract entities from text
      # @param text [String] Raw text to extract from
      # @return [Array<Hash>] Array of { name:, type:, aliases: }
      def extract_entities(text)
        raise NotImplementedError, "#{self.class} must implement #extract_entities"
      end

      # Get the extraction method name
      def extraction_method
        self.class.name.split("::").last.sub("Extractor", "").underscore
      end

      class << self
        def for(type, config = FactDb.config)
          case type.to_sym
          when :manual
            ManualExtractor.new(config)
          when :llm
            LLMExtractor.new(config)
          when :rule_based
            RuleBasedExtractor.new(config)
          else
            raise ArgumentError, "Unknown extractor type: #{type}"
          end
        end

        def available_types
          %i[manual llm rule_based]
        end
      end

      protected

      # Parse a date string, returning nil if invalid
      def parse_date(date_str)
        return nil if date_str.nil? || date_str.to_s.empty?

        # Try chronic for natural language dates
        if defined?(Chronic)
          chronic_result = Chronic.parse(date_str)
          return chronic_result.to_date if chronic_result
        end

        Date.parse(date_str.to_s)
      rescue Date::Error, ArgumentError
        nil
      end

      # Parse a timestamp string, returning nil if invalid
      def parse_timestamp(timestamp_str)
        return nil if timestamp_str.nil? || timestamp_str.to_s.empty?

        # Try chronic for natural language dates
        if defined?(Chronic)
          chronic_result = Chronic.parse(timestamp_str)
          return chronic_result if chronic_result
        end

        Time.parse(timestamp_str.to_s)
      rescue ArgumentError
        nil
      end

      # Build a standardized fact hash
      def build_fact(text:, valid_at:, invalid_at: nil, mentions: [], confidence: 1.0, metadata: {})
        {
          text: text.strip,
          valid_at: valid_at,
          invalid_at: invalid_at,
          mentions: mentions,
          confidence: confidence,
          metadata: metadata,
          extraction_method: extraction_method
        }
      end

      # Build a standardized entity hash
      def build_entity(name:, type:, aliases: [], attributes: {})
        {
          name: name.strip,
          type: type.to_s,
          aliases: aliases.map(&:strip),
          attributes: attributes
        }
      end

      # Build a standardized mention hash
      def build_mention(name:, type:, role: nil, confidence: 1.0)
        {
          name: name.strip,
          type: type.to_s,
          role: role&.to_s,
          confidence: confidence
        }
      end
    end
  end
end
