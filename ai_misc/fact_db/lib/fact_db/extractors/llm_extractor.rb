# frozen_string_literal: true

require "json"

module FactDb
  module Extractors
    class LLMExtractor < Base
      FACT_EXTRACTION_PROMPT = <<~PROMPT
        Extract factual assertions from the following text. For each fact:
        1. State the assertion clearly and concisely
        2. Identify when it became true (valid_at) if mentioned
        3. Identify when it stopped being true (invalid_at) if mentioned
        4. Identify entities mentioned (people, organizations, places, products)
        5. Assign a confidence score (0.0 to 1.0) based on how explicitly stated the fact is

        Text:
        %<text>s

        Return as a JSON array with this structure:
        [
          {
            "text": "Paula works at Microsoft as Principal Engineer",
            "valid_at": "2024-01-10",
            "invalid_at": null,
            "confidence": 0.95,
            "mentions": [
              {"name": "Paula", "type": "person", "role": "subject"},
              {"name": "Microsoft", "type": "organization", "role": "object"}
            ]
          }
        ]

        Rules:
        - Extract only factual assertions, not opinions or speculation
        - Use ISO 8601 date format (YYYY-MM-DD) when possible
        - Set invalid_at to null if the fact is still true or unknown
        - Set valid_at to null if the timing is not mentioned
        - Entity types: person, organization, place, product, event, concept
        - Roles: subject, object, location, temporal, instrument, beneficiary

        Return only valid JSON, no additional text.
      PROMPT

      ENTITY_EXTRACTION_PROMPT = <<~PROMPT
        Extract all named entities from the following text.
        For each entity:
        1. Identify the canonical name
        2. Classify the type (person, organization, place, product, event, concept)
        3. List any aliases or alternative names mentioned

        Text:
        %<text>s

        Return as a JSON array:
        [
          {
            "name": "Paula Chen",
            "type": "person",
            "aliases": ["Paula", "P. Chen"]
          }
        ]

        Return only valid JSON, no additional text.
      PROMPT

      def extract(text, context = {})
        return [] if text.nil? || text.strip.empty?

        client = config.llm_client
        raise ConfigurationError, "LLM client not configured" unless client

        prompt = format(FACT_EXTRACTION_PROMPT, text: text)
        response = call_llm(client, prompt)

        parse_fact_response(response, context)
      end

      def extract_entities(text)
        return [] if text.nil? || text.strip.empty?

        client = config.llm_client
        raise ConfigurationError, "LLM client not configured" unless client

        prompt = format(ENTITY_EXTRACTION_PROMPT, text: text)
        response = call_llm(client, prompt)

        parse_entity_response(response)
      end

      private

      def call_llm(client, prompt)
        # Support multiple LLM client interfaces
        if client.respond_to?(:chat)
          # Standard chat interface (most LLM gems)
          client.chat(prompt)
        elsif client.respond_to?(:complete)
          # Completion interface
          client.complete(prompt)
        elsif client.respond_to?(:call)
          # Callable/lambda interface
          client.call(prompt)
        else
          raise ConfigurationError, "LLM client must respond to :chat, :complete, or :call"
        end
      end

      def parse_fact_response(response, context)
        json = extract_json(response)
        parsed = JSON.parse(json)

        parsed.map do |fact_data|
          valid_at = parse_timestamp(fact_data["valid_at"]) ||
                     context[:captured_at] ||
                     Time.current

          build_fact(
            text: fact_data["text"],
            valid_at: valid_at,
            invalid_at: parse_timestamp(fact_data["invalid_at"]),
            mentions: parse_mentions(fact_data["mentions"]),
            confidence: fact_data["confidence"]&.to_f || 0.8,
            metadata: { llm_response: fact_data }
          )
        end
      rescue JSON::ParserError => e
        config.logger&.warn("Failed to parse LLM fact response: #{e.message}")
        []
      end

      def parse_entity_response(response)
        json = extract_json(response)
        parsed = JSON.parse(json)

        parsed.map do |entity_data|
          build_entity(
            name: entity_data["name"],
            type: entity_data["type"] || "concept",
            aliases: entity_data["aliases"] || [],
            attributes: entity_data["attributes"] || {}
          )
        end
      rescue JSON::ParserError => e
        config.logger&.warn("Failed to parse LLM entity response: #{e.message}")
        []
      end

      def parse_mentions(mentions_data)
        return [] unless mentions_data.is_a?(Array)

        mentions_data.map do |mention|
          build_mention(
            name: mention["name"],
            type: mention["type"] || "concept",
            role: mention["role"],
            confidence: mention["confidence"]&.to_f || 1.0
          )
        end
      end

      def extract_json(response)
        # Handle responses that may have markdown code blocks
        text = response.to_s.strip

        # Remove markdown code blocks if present
        if text.start_with?("```")
          text = text.sub(/\A```(?:json)?\n?/, "").sub(/\n?```\z/, "")
        end

        # Find JSON array in response
        if (match = text.match(/\[[\s\S]*\]/))
          match[0]
        else
          text
        end
      end
    end
  end
end
