module Finn
  module Tools
    class StockNewsSentiment < RubyLLM::Tool
      include YahooFinance

      description "Fetch recent news headlines for a stock and classify each headline's " \
                  "sentiment as positive, neutral, or negative using AI analysis."

      param :symbol, desc: "The stock ticker symbol (e.g. AAPL, MSFT, GOOGL)"
      param :count,  desc: "Number of headlines to analyze (default: 8, max: 15)", required: false

      def execute(symbol:, count: nil)
        symbol   = symbol.upcase.strip
        n        = [[count.to_i, 1].max, 15].min
        n        = 8 if count.nil?

        articles = search_news(symbol, count: n)
        return "No recent news found for #{symbol}." if articles.empty?

        headlines = articles.map { |a| a["title"] }.compact.first(n)

        classified = classify_sentiment(symbol, headlines)

        overall = sentiment_summary(classified)

        JSON.generate({
          symbol:              symbol,
          headline_count:      classified.size,
          overall_sentiment:   overall,
          news_with_sentiment: classified,
        })
      rescue => e
        "Error fetching news sentiment for #{symbol}: #{e.message}"
      end

      private

      def classify_sentiment(symbol, headlines)
        prompt = <<~PROMPT
          You are a financial news sentiment classifier. Classify each headline below for #{symbol} stock as:
          - "positive": likely good news for investors (earnings beat, product launch, partnership, etc.)
          - "negative": likely bad news for investors (miss, lawsuit, downgrade, etc.)
          - "neutral": informational, mixed, or unclear impact

          Return ONLY a JSON array with no markdown, no explanation. Each element must have exactly two keys: "headline" (string) and "sentiment" (string).

          Headlines:
          #{headlines.each_with_index.map { |h, i| "#{i + 1}. #{h}" }.join("\n")}
        PROMPT

        classifier = RubyLLM.chat(model: "claude-haiku-4-5-20251001")
        response   = classifier.ask(prompt)

        json_text = response.content.match(/\[.*\]/m)&.[](0)
        return headlines.map { |h| { "headline" => h, "sentiment" => "neutral" } } unless json_text

        JSON.parse(json_text)
      rescue
        headlines.map { |h| { "headline" => h, "sentiment" => "neutral" } }
      end

      def sentiment_summary(classified)
        counts = classified.group_by { |r| r["sentiment"] }.transform_values(&:count)
        pos = counts["positive"] || 0
        neg = counts["negative"] || 0
        neu = counts["neutral"]  || 0

        if pos > neg + neu
          "Predominantly positive"
        elsif neg > pos + neu
          "Predominantly negative"
        elsif pos > neg
          "Slightly positive"
        elsif neg > pos
          "Slightly negative"
        else
          "Mixed / neutral"
        end
      end
    end
  end
end
