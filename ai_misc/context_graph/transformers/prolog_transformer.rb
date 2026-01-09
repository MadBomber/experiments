# frozen_string_literal: true

module ContextGraph
  module Transformers
    # Transforms results into Prolog facts and rules.
    # This format enables logical inference over the knowledge graph.
    #
    # @example Output format
    #   % Entities
    #   entity(paula_chen, person).
    #   alias(paula_chen, 'Paula').
    #   alias(paula_chen, 'P. Chen').
    #
    #   % Facts
    #   works_at(paula_chen, microsoft).
    #   valid_from(works_at(paula_chen, microsoft), date(2024, 1, 10)).
    #
    #   % Rules (optional inference)
    #   colleague(X, Y) :- works_at(X, Org), works_at(Y, Org), X \= Y.
    class PrologTransformer < Base
      # Standard inference rules to include
      STANDARD_RULES = [
        "% Inference Rules",
        "colleague(X, Y) :- works_at(X, Org), works_at(Y, Org), X \\= Y.",
        "manages(X, Y) :- reports_to(Y, X).",
        "manages(X, Y) :- reports_to(Y, Z), manages(X, Z).",
        "same_team(X, Y) :- reports_to(X, M), reports_to(Y, M), X \\= Y.",
        "current_fact(Fact) :- fact(Fact, ValidAt, InvalidAt), InvalidAt = null.",
        "historical_fact(Fact) :- fact(Fact, ValidAt, InvalidAt), InvalidAt \\= null."
      ].freeze

      def initialize(include_rules: true)
        super()
        @include_rules = include_rules
      end

      # Transform results to Prolog format
      #
      # @param results [QueryResult] The query results
      # @return [String] Prolog facts and rules
      def transform(results)
        lines = ["% Context Graph - Prolog Knowledge Base", "% Generated at #{Time.now}", ""]

        # Entity facts
        lines << "% Entities"
        results.each_entity do |entity|
          lines += entity_to_prolog(entity)
        end
        lines << ""

        # Fact assertions
        lines << "% Facts"
        results.each_fact do |fact|
          lines += fact_to_prolog(fact, results.entities)
        end
        lines << ""

        # Memory assertions
        lines << "% Memories"
        results.each_memory do |memory|
          lines += memory_to_prolog(memory)
        end
        lines << ""

        # Standard inference rules
        if @include_rules
          lines += STANDARD_RULES
          lines << ""
        end

        lines.join("\n")
      end

      private

      def entity_to_prolog(entity)
        lines = []

        name = get_value(entity, :canonical_name) || get_value(entity, :name)
        return lines unless name

        atom = to_atom(name)
        entity_type = get_value(entity, :entity_type) || get_value(entity, :type) || "entity"

        # Entity type
        lines << "entity(#{atom}, #{to_atom(entity_type)})."

        # Aliases
        aliases = get_value(entity, :aliases) || []
        aliases.each do |aka|
          lines << "alias(#{atom}, '#{escape_prolog(aka)}')."
        end

        lines
      end

      def fact_to_prolog(fact, entities)
        lines = []

        fact_text = get_value(fact, :fact_text)
        return lines unless fact_text

        # Get subject
        mentions = get_value(fact, :entity_mentions) || []
        subject_mention = mentions.find { |m| get_value(m, :role) == "subject" }

        if subject_mention
          entity_id = get_value(subject_mention, :entity_id)
          entity = entities[entity_id]
          subject = entity ? (get_value(entity, :canonical_name) || get_value(entity, :name)) : "entity_#{entity_id}"
        else
          subject = extract_subject(fact_text)
        end

        subject_atom = to_atom(subject)

        # Extract predicate and object
        predicate, object = extract_predicate_object(fact_text, subject)
        predicate_atom = to_atom(predicate)

        # Check if object is an entity
        object_mention = mentions.find { |m| get_value(m, :role) != "subject" }
        if object_mention
          entity_id = get_value(object_mention, :entity_id)
          entity = entities[entity_id]
          object_value = entity ? to_atom(get_value(entity, :canonical_name) || get_value(entity, :name)) : "entity_#{entity_id}"
        else
          object_value = "'#{escape_prolog(object)}'"
        end

        # Main fact
        lines << "#{predicate_atom}(#{subject_atom}, #{object_value})."

        # Temporal metadata
        valid_at = get_value(fact, :valid_at)
        if valid_at
          date_term = date_to_prolog(valid_at)
          lines << "valid_from(#{predicate_atom}(#{subject_atom}, #{object_value}), #{date_term})."
        end

        invalid_at = get_value(fact, :invalid_at)
        if invalid_at
          date_term = date_to_prolog(invalid_at)
          lines << "valid_until(#{predicate_atom}(#{subject_atom}, #{object_value}), #{date_term})."
        else
          lines << "valid_until(#{predicate_atom}(#{subject_atom}, #{object_value}), null)."
        end

        # Status
        status = get_value(fact, :status)
        lines << "status(#{predicate_atom}(#{subject_atom}, #{object_value}), #{to_atom(status)})." if status

        # Confidence
        confidence = get_value(fact, :confidence)
        lines << "confidence(#{predicate_atom}(#{subject_atom}, #{object_value}), #{confidence})." if confidence

        lines
      end

      def memory_to_prolog(memory)
        lines = []

        content = get_value(memory, :content)
        return lines unless content

        robot = get_value(memory, :robot_name) || "robot"
        robot_atom = to_atom(robot)
        memory_type = get_value(memory, :type) || get_value(memory, :node_type) || "memory"
        memory_id = get_value(memory, :id) || content.hash.abs

        # Memory fact
        lines << "memory(#{memory_id}, #{robot_atom}, #{to_atom(memory_type)}, '#{escape_prolog(truncate(content, 200))}')."

        # Importance
        importance = get_value(memory, :importance)
        lines << "importance(#{memory_id}, #{importance})." if importance

        lines
      end

      def to_atom(str)
        # Convert string to Prolog atom (lowercase, underscores)
        str.to_s
           .downcase
           .gsub(/[^a-z0-9]+/, "_")
           .gsub(/^_|_$/, "")
           .then { |s| s.match?(/^[a-z]/) ? s : "x_#{s}" }
      end

      def escape_prolog(str)
        str.to_s.gsub("'", "\\'").gsub("\n", "\\n")
      end

      def date_to_prolog(date)
        if date.respond_to?(:year)
          "date(#{date.year}, #{date.month}, #{date.day})"
        else
          begin
            d = Date.parse(date.to_s)
            "date(#{d.year}, #{d.month}, #{d.day})"
          rescue ArgumentError
            "'#{date}'"
          end
        end
      end

      def extract_subject(fact_text)
        words = fact_text.split(/\s+/)
        words.take_while { |w| !w.match?(/^(is|are|was|were|has|have|works|worked)$/i) }.join(" ")
      end

      def extract_predicate_object(fact_text, subject)
        remainder = fact_text.sub(/^#{Regexp.escape(subject)}\s*/i, "")

        if match = remainder.match(/^(is|are|was|were|has|have|works?|worked)\s+(at|for|to|a|an|the)?\s*(.+)/i)
          verb = match[1].downcase
          prep = match[2]&.downcase
          object = match[3]

          predicate = case verb
                      when "works", "worked"
                        prep == "at" || prep == "for" ? "works_at" : "works"
                      when "is", "are", "was", "were"
                        "is"
                      when "has", "have"
                        "has"
                      else
                        verb
                      end

          [predicate, object]
        else
          ["asserts", remainder]
        end
      end

      def truncate(str, length)
        return str if str.to_s.length <= length

        "#{str.to_s[0, length - 3]}..."
      end
    end
  end
end
