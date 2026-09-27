module Finn
  module Tools
    class StockPrice < RubyLLM::Tool
      include YahooFinance

      description "Get the current stock price and key market metrics for a ticker symbol. " \
                  "Returns price, change, volume, market cap, 52-week range, P/E ratio, beta, and EPS."

      param :symbol, desc: "The stock ticker symbol (e.g. AAPL, MSFT, GOOGL, BRK-B)"

      def execute(symbol:)
        symbol = symbol.upcase.strip
        data   = quote_summary(symbol, %w[price summaryDetail defaultKeyStatistics])

        price  = data["price"]              || {}
        detail = data["summaryDetail"]      || {}
        stats  = data["defaultKeyStatistics"] || {}

        result = {
          symbol:           symbol,
          name:             price["shortName"] || price["longName"],
          currency:         price["currency"],
          exchange:         price["exchangeName"],
          current_price:    raw_value(price, "regularMarketPrice"),
          open:             raw_value(price, "regularMarketOpen"),
          day_high:         raw_value(price, "regularMarketDayHigh"),
          day_low:          raw_value(price, "regularMarketDayLow"),
          previous_close:   raw_value(price, "regularMarketPreviousClose"),
          change:           raw_value(price, "regularMarketChange")&.then { |v| v.round(4) },
          change_percent:   raw_value(price, "regularMarketChangePercent")&.then { |v| "#{(v * 100).round(2)}%" },
          volume:           raw_value(price, "regularMarketVolume"),
          avg_volume_3m:    raw_value(detail, "averageVolume"),
          market_cap:       format_large_number(raw_value(price, "marketCap")),
          pe_ratio_ttm:     raw_value(detail, "trailingPE")&.then { |v| v.round(2) },
          forward_pe:       raw_value(detail, "forwardPE")&.then { |v| v.round(2) },
          eps_ttm:          raw_value(stats,  "trailingEps")&.then { |v| v.round(2) },
          week_52_high:     raw_value(detail, "fiftyTwoWeekHigh"),
          week_52_low:      raw_value(detail, "fiftyTwoWeekLow"),
          beta:             raw_value(detail, "beta")&.then { |v| v.round(2) },
          price_to_book:    raw_value(stats,  "priceToBook")&.then { |v| v.round(2) },
          timestamp:        Time.now.utc.strftime("%Y-%m-%d %H:%M UTC"),
        }.compact

        JSON.generate(result)
      rescue => e
        "Error fetching stock price for #{symbol}: #{e.message}"
      end
    end
  end
end
