# frozen_string_literal: true

module ContextGraph
  module Transformers
    # Transforms results into Cypher-like graph notation.
    # This format is readable by both humans and LLMs, and encodes
    # nodes, relationships, and properties explicitly.
    #
    # @example Output format
    #   (paula:Person {name: "Paula Chen"})
    #   (microsoft:Organization {name: "Microsoft"})
    #   (paula)-[:WORKS_AT {since: "2024-01-10", role: "Principal Engineer"}]->(microsoft)
    class CypherTransformer < Base
      # Transform results to Cypher format
      #
      # @param results [QueryResult] The query results
      # @return [String] Cypher-like graph notation
      def transform(results)
        lines = []
        defined_nodes = Set.new

        # Define entity nodes
        results.each_entity do |entity|
          node_def = entity_to_cypher(entity)
          if node_def && !defined_nodes.include?(node_def)
            lines << node_def
            defined_nodes << node_def
          end
        end

        # Define relationships from facts
        results.each_fact do |fact|
          relationship = fact_to_cypher(fact, results.entities, defined_nodes, lines)
          lines << relationship if relationship
        end

        # Add memories as robot nodes with relationships
        results.each_memory do |memory|
          memory_lines = memory_to_cypher(memory, defined_nodes)
          lines += memory_lines
        end

        lines.join("\n")
      end

      private

      def entity_to_cypher(entity)
        name = get_value(entity, :canonical_name) || get_value(entity, :name)
        return nil unless name

        var = to_variable(name)
        entity_type = get_value(entity, :entity_type) || get_value(entity, :type) || "Entity"
        label = entity_type.to_s.capitalize

        props = { name: name }

        # Add aliases if present
        aliases = get_value(entity, :aliases)
        props[:aliases] = aliases if aliases && !aliases.empty?

        "(#{var}:#{label} #{format_props(props)})"
      end

      def fact_to_cypher(fact, entities, defined_nodes, lines)
        mentions = get_value(fact, :entity_mentions) || []
        return nil if mentions.empty?

        # Find subject and object
        subject_mention = mentions.find { |m| get_value(m, :role) == "subject" }
        object_mention = mentions.find { |m| get_value(m, :role) != "subject" }

        return nil unless subject_mention

        # Get subject entity
        subject_id = get_value(subject_mention, :entity_id)
        subject_entity = entities[subject_id]
        subject_name = subject_entity ? (get_value(subject_entity, :canonical_name) || get_value(subject_entity, :name)) : "Entity_#{subject_id}"
        subject_var = to_variable(subject_name)

        # Ensure subject node is defined
        unless defined_nodes.any? { |n| n.include?("(#{subject_var}:") }
          node_def = "(#{subject_var}:Entity {name: \"#{escape_string(subject_name)}\"})"
          lines << node_def
          defined_nodes << node_def
        end

        # Build relationship properties
        rel_props = {}

        valid_at = get_value(fact, :valid_at)
        rel_props[:since] = format_date(valid_at) if valid_at

        invalid_at = get_value(fact, :invalid_at)
        rel_props[:until] = format_date(invalid_at) if invalid_at

        status = get_value(fact, :status)
        rel_props[:status] = status if status

        confidence = get_value(fact, :confidence)
        rel_props[:confidence] = confidence if confidence

        # Extract relationship type from fact text
        fact_text = get_value(fact, :fact_text) || ""
        rel_type = extract_relationship_type(fact_text)

        if object_mention
          # Relationship to another entity
          object_id = get_value(object_mention, :entity_id)
          object_entity = entities[object_id]
          object_name = object_entity ? (get_value(object_entity, :canonical_name) || get_value(object_entity, :name)) : "Entity_#{object_id}"
          object_var = to_variable(object_name)

          # Ensure object node is defined
          unless defined_nodes.any? { |n| n.include?("(#{object_var}:") }
            node_def = "(#{object_var}:Entity {name: \"#{escape_string(object_name)}\"})"
            lines << node_def
            defined_nodes << node_def
          end

          props_str = rel_props.empty? ? "" : " #{format_props(rel_props)}"
          "(#{subject_var})-[:#{rel_type}#{props_str}]->(#{object_var})"
        else
          # Relationship to a literal value
          object_value = extract_object_value(fact_text, subject_name)
          props_str = rel_props.empty? ? "" : " #{format_props(rel_props)}"
          "(#{subject_var})-[:#{rel_type}#{props_str}]->(\"#{escape_string(object_value)}\")"
        end
      end

      def memory_to_cypher(memory, defined_nodes)
        lines = []

        robot = get_value(memory, :robot_name) || "Robot"
        robot_var = to_variable(robot)
        content = get_value(memory, :content) || ""
        memory_type = get_value(memory, :type) || get_value(memory, :node_type) || "Memory"

        # Define robot node if not already defined
        robot_def = "(#{robot_var}:Robot {name: \"#{escape_string(robot)}\"})"
        unless defined_nodes.include?(robot_def)
          lines << robot_def
          defined_nodes << robot_def
        end

        # Create memory node
        memory_id = get_value(memory, :id) || content.hash.abs
        memory_var = "memory_#{memory_id}"
        memory_props = {
          content: truncate(content, 100),
          type: memory_type.to_s
        }

        importance = get_value(memory, :importance)
        memory_props[:importance] = importance if importance

        lines << "(#{memory_var}:Memory #{format_props(memory_props)})"

        # Create relationship
        lines << "(#{robot_var})-[:REMEMBERED]->(#{memory_var})"

        lines
      end

      def extract_relationship_type(fact_text)
        # Extract verb/relationship from fact text
        if fact_text.match?(/\bworks?\s+(at|for)\b/i)
          "WORKS_AT"
        elsif fact_text.match?(/\bworked\s+(at|for)\b/i)
          "WORKED_AT"
        elsif fact_text.match?(/\breports?\s+to\b/i)
          "REPORTS_TO"
        elsif fact_text.match?(/\bis\s+(a|an|the)\b/i)
          "IS_A"
        elsif fact_text.match?(/\bhas\b/i)
          "HAS"
        elsif fact_text.match?(/\bdecided\b/i)
          "DECIDED"
        elsif fact_text.match?(/\bjoined\b/i)
          "JOINED"
        elsif fact_text.match?(/\bleft\b/i)
          "LEFT"
        else
          "RELATES_TO"
        end
      end

      def extract_object_value(fact_text, subject)
        # Remove subject and extract remainder
        remainder = fact_text.sub(/^#{Regexp.escape(subject)}\s*/i, "")
        remainder.sub(/^(is|are|was|were|has|have|works?|worked)\s+(at|for|to|a|an|the)?\s*/i, "")
      end

      def format_props(props)
        return "{}" if props.empty?

        pairs = props.map do |k, v|
          value = case v
                  when String then "\"#{escape_string(v)}\""
                  when Array then "[#{v.map { |e| "\"#{escape_string(e)}\"" }.join(", ")}]"
                  when nil then "null"
                  else v.to_s
                  end
          "#{k}: #{value}"
        end

        "{#{pairs.join(", ")}}"
      end

      def truncate(str, length)
        return str if str.to_s.length <= length

        "#{str.to_s[0, length - 3]}..."
      end
    end
  end
end
