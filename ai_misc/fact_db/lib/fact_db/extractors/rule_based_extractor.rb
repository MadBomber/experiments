# frozen_string_literal: true

module FactDb
  module Extractors
    class RuleBasedExtractor < Base
      # Date patterns for temporal extraction
      DATE_PATTERNS = [
        # "on January 10, 2024"
        /(?:on|since|from|as of|starting)\s+(\w+\s+\d{1,2},?\s+\d{4})/i,
        # "on 2024-01-10"
        /(?:on|since|from|as of|starting)\s+(\d{4}-\d{2}-\d{2})/i,
        # "in January 2024"
        /(?:in|during)\s+(\w+\s+\d{4})/i,
        # "in 2024"
        /(?:in|during)\s+(\d{4})\b/i
      ].freeze

      END_DATE_PATTERNS = [
        # "until January 10, 2024"
        /(?:until|through|to|ended|left)\s+(\w+\s+\d{1,2},?\s+\d{4})/i,
        /(?:until|through|to|ended|left)\s+(\d{4}-\d{2}-\d{2})/i
      ].freeze

      # Employment patterns
      EMPLOYMENT_PATTERNS = [
        # "Paula works at Microsoft"
        /(\b[A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)\s+(?:works?|worked|is working)\s+(?:at|for)\s+(\b[A-Z][A-Za-z]+(?:\s+[A-Z][A-Za-z]+)*)/,
        # "Paula joined Microsoft"
        /(\b[A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)\s+(?:joined|started at|was hired by)\s+(\b[A-Z][A-Za-z]+(?:\s+[A-Z][A-Za-z]+)*)/,
        # "Paula left Microsoft"
        /(\b[A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)\s+(?:left|departed|resigned from|was fired from)\s+(\b[A-Z][A-Za-z]+(?:\s+[A-Z][A-Za-z]+)*)/,
        # "Paula is a Principal Engineer at Microsoft"
        /(\b[A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)\s+(?:is|was|became)\s+(?:a\s+)?([A-Z][A-Za-z]+(?:\s+[A-Z][A-Za-z]+)*)\s+at\s+(\b[A-Z][A-Za-z]+(?:\s+[A-Z][A-Za-z]+)*)/
      ].freeze

      # Relationship patterns
      RELATIONSHIP_PATTERNS = [
        # "Paula is married to John"
        /(\b[A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)\s+(?:is|was)\s+(?:married to|engaged to|dating)\s+(\b[A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)/,
        # "Paula is the CEO of Microsoft"
        /(\b[A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)\s+(?:is|was)\s+(?:the\s+)?(\w+(?:\s+\w+)*)\s+of\s+(\b[A-Z][A-Za-z]+(?:\s+[A-Z][A-Za-z]+)*)/
      ].freeze

      # Location patterns
      LOCATION_PATTERNS = [
        # "Paula lives in Seattle"
        /(\b[A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)\s+(?:lives?|lived|is based|was based|relocated)\s+(?:in|to)\s+(\b[A-Z][A-Za-z]+(?:,?\s+[A-Z]{2})?)/,
        # "Microsoft is headquartered in Redmond"
        /(\b[A-Z][A-Za-z]+(?:\s+[A-Z][A-Za-z]+)*)\s+(?:is|was)\s+(?:headquartered|located|based)\s+in\s+(\b[A-Z][A-Za-z]+(?:,?\s+[A-Z]{2})?)/
      ].freeze

      def extract(text, context = {})
        return [] if text.nil? || text.strip.empty?

        facts = []

        # Extract employment facts
        facts.concat(extract_employment_facts(text, context))

        # Extract relationship facts
        facts.concat(extract_relationship_facts(text, context))

        # Extract location facts
        facts.concat(extract_location_facts(text, context))

        facts.uniq { |f| f[:text] }
      end

      def extract_entities(text)
        return [] if text.nil? || text.strip.empty?

        entities = []

        # Extract person names (simple capitalized word sequences)
        text.scan(/\b([A-Z][a-z]+(?:\s+[A-Z][a-z]+)+)\b/).flatten.uniq.each do |name|
          next if common_word?(name)

          entities << build_entity(name: name, type: "person")
        end

        # Extract organization names (from employment patterns)
        EMPLOYMENT_PATTERNS.each do |pattern|
          text.scan(pattern).each do |match|
            org_name = match.last
            entities << build_entity(name: org_name, type: "organization") unless common_word?(org_name)
          end
        end

        # Extract locations
        LOCATION_PATTERNS.each do |pattern|
          text.scan(pattern).each do |match|
            location = match.last
            entities << build_entity(name: location, type: "place") unless common_word?(location)
          end
        end

        entities.uniq { |e| e[:name].downcase }
      end

      private

      def extract_employment_facts(text, context)
        facts = []
        default_date = context[:captured_at] || Time.current

        EMPLOYMENT_PATTERNS.each do |pattern|
          text.scan(pattern).each do |match|
            person, *rest = match
            org = rest.last

            # Determine if this is a "left" pattern
            is_termination = text.match?(/#{Regexp.escape(person)}\s+(?:left|departed|resigned|was fired)/i)

            fact_text = match.join(" ").gsub(/\s+/, " ")
            valid_at = extract_start_date(text) || default_date
            invalid_at = is_termination ? (extract_end_date(text) || default_date) : nil

            mentions = [
              build_mention(name: person, type: "person", role: "subject"),
              build_mention(name: org, type: "organization", role: "object")
            ]

            # Add role if present
            if rest.length > 1
              mentions << build_mention(name: rest[0], type: "concept", role: "instrument")
            end

            facts << build_fact(
              text: fact_text,
              valid_at: valid_at,
              invalid_at: invalid_at,
              mentions: mentions,
              confidence: 0.8
            )
          end
        end

        facts
      end

      def extract_relationship_facts(text, context)
        facts = []
        default_date = context[:captured_at] || Time.current

        RELATIONSHIP_PATTERNS.each do |pattern|
          text.scan(pattern).each do |match|
            fact_text = match.join(" ").gsub(/\s+/, " ")

            mentions = match.map.with_index do |name, i|
              role = i.zero? ? "subject" : "object"
              build_mention(name: name, type: "person", role: role)
            end

            facts << build_fact(
              text: fact_text,
              valid_at: extract_start_date(text) || default_date,
              invalid_at: extract_end_date(text),
              mentions: mentions,
              confidence: 0.75
            )
          end
        end

        facts
      end

      def extract_location_facts(text, context)
        facts = []
        default_date = context[:captured_at] || Time.current

        LOCATION_PATTERNS.each do |pattern|
          text.scan(pattern).each do |match|
            entity_name, location = match
            fact_text = "#{entity_name} is located in #{location}"

            # Determine entity type
            entity_type = text.match?(/#{Regexp.escape(entity_name)}\s+(?:lives?|lived)/i) ? "person" : "organization"

            mentions = [
              build_mention(name: entity_name, type: entity_type, role: "subject"),
              build_mention(name: location, type: "place", role: "location")
            ]

            facts << build_fact(
              text: fact_text,
              valid_at: extract_start_date(text) || default_date,
              invalid_at: nil,
              mentions: mentions,
              confidence: 0.7
            )
          end
        end

        facts
      end

      def extract_start_date(text)
        DATE_PATTERNS.each do |pattern|
          if (match = text.match(pattern))
            return parse_date(match[1])
          end
        end
        nil
      end

      def extract_end_date(text)
        END_DATE_PATTERNS.each do |pattern|
          if (match = text.match(pattern))
            return parse_date(match[1])
          end
        end
        nil
      end

      def common_word?(word)
        common_words = %w[
          The A An And Or But Is Was Were Are Been
          Has Have Had Will Would Could Should
          This That These Those
          January February March April May June July August September October November December
          Monday Tuesday Wednesday Thursday Friday Saturday Sunday
          Inc Corp Ltd LLC Company Corporation
        ]
        common_words.any? { |w| w.casecmp?(word) }
      end
    end
  end
end
