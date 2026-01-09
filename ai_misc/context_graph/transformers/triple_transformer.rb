# frozen_string_literal: true

module ContextGraph
  module Transformers
    # Transforms results into Subject-Predicate-Object triples.
    # This format encodes semantic structure that LLMs can leverage.
    #
    # @example Output format
    #   [
    #     ["Paula Chen", "type", "Person"],
    #     ["Paula Chen", "works_at", "Microsoft"],
    #     ["Paula Chen", "works_at.valid_from", "2024-01-10"]
    #   ]
    class TripleTransformer < Base
      # Transform results to triples format
      #
      # @param results [QueryResult] The query results
      # @return [Array<Array>] Array of [subject, predicate, object] triples
      def transform(results)
        triples = []

        # Transform entities
        results.each_entity do |entity|
          triples += entity_to_triples(entity)
        end

        # Transform facts
        results.each_fact do |fact|
          triples += fact_to_triples(fact, results.entities)
        end

        # Transform memories
        results.each_memory do |memory|
          triples += memory_to_triples(memory)
        end

        triples
      end

      private

      def entity_to_triples(entity)
        triples = []
        name = get_value(entity, :canonical_name) || get_value(entity, :name)
        return triples unless name

        # Type triple
        entity_type = get_value(entity, :entity_type) || get_value(entity, :type)
        triples << [name, "type", entity_type.to_s.capitalize] if entity_type

        # Aliases
        aliases = get_value(entity, :aliases) || []
        aliases.each do |aka|
          triples << [name, "also_known_as", aka]
        end

        # Status
        status = get_value(entity, :resolution_status)
        triples << [name, "resolution_status", status] if status

        triples
      end

      def fact_to_triples(fact, entities)
        triples = []

        fact_text = get_value(fact, :fact_text)
        return triples unless fact_text

        # Try to extract subject from entity mentions
        mentions = get_value(fact, :entity_mentions) || []
        subject_mention = mentions.find { |m| get_value(m, :role) == "subject" }

        if subject_mention
          entity_id = get_value(subject_mention, :entity_id)
          entity = entities[entity_id]
          subject = entity ? (get_value(entity, :canonical_name) || get_value(entity, :name)) : "Entity_#{entity_id}"
        else
          # Fall back to extracting from fact text
          subject = extract_subject(fact_text)
        end

        # Main fact assertion
        predicate, object = extract_predicate_object(fact_text, subject)
        triples << [subject, predicate, object]

        # Temporal metadata
        valid_at = get_value(fact, :valid_at)
        triples << [subject, "#{predicate}.valid_from", format_date(valid_at)] if valid_at

        invalid_at = get_value(fact, :invalid_at)
        triples << [subject, "#{predicate}.valid_until", format_date(invalid_at)] if invalid_at

        # Status
        status = get_value(fact, :status)
        triples << [subject, "#{predicate}.status", status] if status

        # Confidence
        confidence = get_value(fact, :confidence)
        triples << [subject, "#{predicate}.confidence", confidence.to_s] if confidence

        # Add other entity mentions as relationships
        mentions.each do |mention|
          role = get_value(mention, :role)
          next if role == "subject"

          entity_id = get_value(mention, :entity_id)
          entity = entities[entity_id]
          entity_name = entity ? (get_value(entity, :canonical_name) || get_value(entity, :name)) : "Entity_#{entity_id}"

          triples << [subject, role, entity_name]
        end

        triples
      end

      def memory_to_triples(memory)
        triples = []

        content = get_value(memory, :content)
        return triples unless content

        robot = get_value(memory, :robot_name) || "Robot"
        memory_type = get_value(memory, :type) || get_value(memory, :node_type) || "memory"

        # Robot remembered this
        triples << [robot, "remembered", truncate(content, 100)]
        triples << [truncate(content, 100), "type", memory_type.to_s]

        # Importance
        importance = get_value(memory, :importance)
        triples << [truncate(content, 100), "importance", importance.to_s] if importance

        # Timestamp
        created_at = get_value(memory, :created_at)
        triples << [truncate(content, 100), "created_at", format_date(created_at)] if created_at

        triples
      end

      def extract_subject(fact_text)
        # Simple heuristic: first noun phrase before a verb
        # In production, you'd use NLP or entity extraction
        words = fact_text.split(/\s+/)
        words.take_while { |w| !w.match?(/^(is|are|was|were|has|have|works|worked)$/i) }.join(" ")
      end

      def extract_predicate_object(fact_text, subject)
        # Remove subject from fact text to get predicate + object
        remainder = fact_text.sub(/^#{Regexp.escape(subject)}\s*/i, "")

        # Simple verb extraction
        if match = remainder.match(/^(is|are|was|were|has|have|works?|worked)\s+(.+)/i)
          verb = match[1].downcase
          object = match[2]

          # Convert to predicate form
          predicate = case verb
                      when "is", "are", "was", "were" then "is"
                      when "has", "have" then "has"
                      when "works", "worked" then "works_at"
                      else verb
                      end

          [predicate, object]
        else
          # Fall back to generic predicate
          ["asserts", remainder]
        end
      end

      def truncate(str, length)
        return str if str.length <= length

        "#{str[0, length - 3]}..."
      end
    end
  end
end
