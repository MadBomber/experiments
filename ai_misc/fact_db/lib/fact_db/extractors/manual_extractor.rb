# frozen_string_literal: true

module FactDb
  module Extractors
    class ManualExtractor < Base
      # Manual extraction passes through the text as a single fact
      # This is used for API-driven fact creation where the user
      # provides the fact text and metadata directly
      def extract(text, context = {})
        return [] if text.nil? || text.strip.empty?

        valid_at = context[:valid_at] || context[:captured_at] || Time.current

        [
          build_fact(
            text: text,
            valid_at: valid_at,
            invalid_at: context[:invalid_at],
            mentions: context[:mentions] || [],
            confidence: context[:confidence] || 1.0,
            metadata: context[:metadata] || {}
          )
        ]
      end

      # Manual extraction expects entities to be provided explicitly
      def extract_entities(text)
        []
      end

      # Convenience method for creating a single fact with full control
      def create_fact(text:, valid_at:, invalid_at: nil, mentions: [], confidence: 1.0, metadata: {})
        extract(text, {
          valid_at: valid_at,
          invalid_at: invalid_at,
          mentions: mentions,
          confidence: confidence,
          metadata: metadata
        }).first
      end

      # Convenience method for creating an entity
      def create_entity(name:, type:, aliases: [], attributes: {})
        build_entity(
          name: name,
          type: type,
          aliases: aliases,
          attributes: attributes
        )
      end
    end
  end
end
