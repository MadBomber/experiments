require "httparty"
require "uri"

module Finn
  module Tools
    class Wikipedia < RubyLLM::Tool
      description "Search Wikipedia for a topic and return a summary. Useful for company " \
                  "history, industry background, economic concepts, and general knowledge."

      param :query, desc: "The topic to search for (e.g. 'Apple Inc', 'semiconductor industry', 'P/E ratio')"

      HEADERS = { "User-Agent" => "Finn-Finance-Agent/1.0 (Ruby; contact via GitHub)" }.freeze

      def execute(query:)
        title = search_title(query)
        return "No Wikipedia article found for '#{query}'." unless title

        summary = fetch_summary(title)
        return "Could not retrieve Wikipedia summary for '#{title}'." unless summary

        JSON.generate({
          title:       summary["title"],
          description: summary["description"],
          extract:     summary["extract"],
          url:         summary.dig("content_urls", "desktop", "page"),
        }.compact)
      rescue => e
        "Wikipedia search error for '#{query}': #{e.message}"
      end

      private

      def search_title(query)
        response = HTTParty.get(
          "https://en.wikipedia.org/w/api.php",
          query: {
            action:    "opensearch",
            search:    query,
            limit:     1,
            namespace: 0,
            format:    "json",
          },
          headers: HEADERS,
          timeout: 10
        )
        return nil unless response.success?

        titles = JSON.parse(response.body)[1]
        titles&.first
      end

      def fetch_summary(title)
        # Wikipedia REST API uses underscores for spaces (like canonical wiki URLs)
        encoded  = title.gsub(" ", "_")
        response = HTTParty.get(
          "https://en.wikipedia.org/api/rest_v1/page/summary/#{encoded}",
          headers: HEADERS,
          timeout: 10
        )
        return nil unless response.success?

        JSON.parse(response.body)
      end
    end
  end
end
