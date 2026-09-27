require "httparty"
require "uri"

module Finn
  module Tools
    class WebSearch < RubyLLM::Tool
      description "Search the web via DuckDuckGo for quick factual lookups, company descriptions, " \
                  "definitions, and brief answers. Works best for direct factual queries. " \
                  "For company financials use StockInfo/StockPrice; for news use StockNewsSentiment; " \
                  "for background context use Wikipedia."

      param :query, desc: "A factual search query (e.g. 'what is EBITDA', 'Apple Inc description', 'Warren Buffett')"

      HEADERS = {
        "User-Agent"      => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
        "Accept"          => "application/json",
        "Accept-Language" => "en-US,en;q=0.9",
      }.freeze

      def execute(query:)
        response = HTTParty.get(
          "https://api.duckduckgo.com/",
          query: {
            q:             query,
            format:        "json",
            no_redirect:   1,
            no_html:       1,
            skip_disambig: 1,
          },
          headers: HEADERS,
          timeout: 10
        )

        raise "HTTP #{response.code}" unless response.success?

        data   = JSON.parse(response.body)
        result = extract_result(query, data)

        return "No direct answer found for '#{query}'. " \
               "For financial data use StockInfo or StockPrice. " \
               "For background, use Wikipedia." if result.nil?

        JSON.generate(result)
      rescue => e
        "Web search error for '#{query}': #{e.message}"
      end

      private

      def extract_result(query, data)
        result = { query: query }

        abstract = data["Abstract"].to_s.strip
        answer   = data["Answer"].to_s.strip
        defn     = data["Definition"].to_s.strip
        source   = data["AbstractSource"].to_s.strip

        result[:answer]   = answer   unless answer.empty?
        result[:abstract] = abstract unless abstract.empty?
        result[:source]   = source   unless source.empty?
        result[:abstract_url] = data["AbstractURL"] unless data["AbstractURL"].to_s.empty?
        result[:definition] = defn   unless defn.empty?

        topics = (data["RelatedTopics"] || [])
          .select { |t| t.is_a?(Hash) && t["Text"].to_s.length > 20 }
          .first(5)
          .map { |t| { text: t["Text"], url: t["FirstURL"] }.compact }

        result[:related_topics] = topics unless topics.empty?

        (result.keys - [:query]).empty? ? nil : result
      end
    end
  end
end
