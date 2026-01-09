# frozen_string_literal: true

module ContextGraph
  module Transformers
    # Transforms results into human-readable text format.
    # Useful for direct LLM consumption or debugging.
    class TextTransformer < Base
      # Transform results to text format
      #
      # @param results [QueryResult] The query results
      # @return [String] Human-readable text
      def transform(results)
        sections = []

        # Entities section
        unless results.entities.empty?
          sections << format_entities_section(results)
        end

        # Facts section
        unless results.facts.empty?
          sections << format_facts_section(results)
        end

        # Memories section
        unless results.memories.empty?
          sections << format_memories_section(results)
        end

        if sections.empty?
          "No results found for query: #{results.query}"
        else
          sections.join("\n\n")
        end
      end

      private

      def format_entities_section(results)
        lines = ["## Entities"]

        results.each_entity do |entity|
          name = get_value(entity, :canonical_name) || get_value(entity, :name)
          entity_type = get_value(entity, :entity_type) || get_value(entity, :type)

          line = "- **#{name}**"
          line += " (#{entity_type})" if entity_type

          aliases = get_value(entity, :aliases)
          line += " - also known as: #{aliases.join(', ')}" if aliases && !aliases.empty?

          lines << line
        end

        lines.join("\n")
      end

      def format_facts_section(results)
        lines = ["## Facts"]

        # Group by status
        facts_by_status = results.facts.group_by { |f| get_value(f, :status) || "unknown" }

        # Show canonical facts first
        if facts_by_status["canonical"]
          lines << "\n### Current Facts"
          facts_by_status["canonical"].each do |fact|
            lines << format_fact(fact, results.entities)
          end
        end

        # Show corroborated facts
        if facts_by_status["corroborated"]
          lines << "\n### Corroborated Facts"
          facts_by_status["corroborated"].each do |fact|
            lines << format_fact(fact, results.entities)
          end
        end

        # Show superseded facts (historical)
        if facts_by_status["superseded"]
          lines << "\n### Historical Facts (Superseded)"
          facts_by_status["superseded"].each do |fact|
            lines << format_fact(fact, results.entities)
          end
        end

        # Show synthesized facts
        if facts_by_status["synthesized"]
          lines << "\n### Synthesized Facts"
          facts_by_status["synthesized"].each do |fact|
            lines << format_fact(fact, results.entities)
          end
        end

        lines.join("\n")
      end

      def format_fact(fact, entities)
        fact_text = get_value(fact, :fact_text)
        valid_at = get_value(fact, :valid_at)
        invalid_at = get_value(fact, :invalid_at)
        confidence = get_value(fact, :confidence)

        line = "- #{fact_text}"

        # Add temporal info
        temporal = []
        temporal << "from #{format_date(valid_at)}" if valid_at
        temporal << "until #{format_date(invalid_at)}" if invalid_at
        line += " (#{temporal.join(' ')})" unless temporal.empty?

        # Add confidence
        line += " [confidence: #{(confidence * 100).round}%]" if confidence

        line
      end

      def format_memories_section(results)
        lines = ["## Memories"]

        # Group by type
        memories_by_type = results.memories.group_by { |m| get_value(m, :type) || get_value(m, :node_type) || "unknown" }

        memories_by_type.each do |type, memories|
          lines << "\n### #{type.to_s.capitalize.gsub('_', ' ')}s"

          memories.each do |memory|
            lines << format_memory(memory)
          end
        end

        lines.join("\n")
      end

      def format_memory(memory)
        content = get_value(memory, :content)
        robot = get_value(memory, :robot_name)
        importance = get_value(memory, :importance)
        created_at = get_value(memory, :created_at)

        line = "- #{content}"

        meta = []
        meta << "by #{robot}" if robot
        meta << "importance: #{importance}" if importance
        meta << "at #{format_date(created_at)}" if created_at

        line += " (#{meta.join(', ')})" unless meta.empty?

        line
      end
    end
  end
end
