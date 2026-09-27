module Finn
  module Tools
    class StockDividends < RubyLLM::Tool
      include YahooFinance

      description "Get dividend information for a stock: annual dividend rate, yield, payout ratio, " \
                  "5-year average yield, ex-dividend date, and last dividend amount."

      param :symbol, desc: "The stock ticker symbol (e.g. AAPL, JNJ, KO)"

      def execute(symbol:)
        symbol = symbol.upcase.strip
        data   = quote_summary(symbol, %w[summaryDetail defaultKeyStatistics])

        detail = data["summaryDetail"]        || {}
        stats  = data["defaultKeyStatistics"] || {}

        div_rate  = raw_value(detail, "dividendRate")
        div_yield = raw_value(detail, "dividendYield")
        payout    = raw_value(detail, "payoutRatio")
        avg_yield = raw_value(detail, "fiveYearAvgDividendYield")

        result = {
          symbol:                   symbol,
          pays_dividend:            !div_rate.nil? && div_rate.to_f > 0,
          annual_dividend_rate:     div_rate&.round(4),
          dividend_yield:           div_yield ? "#{(div_yield.to_f * 100).round(2)}%" : nil,
          payout_ratio:             payout ? "#{(payout.to_f * 100).round(2)}%" : nil,
          five_year_avg_yield:      avg_yield ? "#{avg_yield.to_f.round(2)}%" : nil,
          ex_dividend_date:         epoch_to_date(raw_value(detail, "exDividendDate")),
          last_dividend_date:       epoch_to_date(raw_value(stats,  "lastDividendDate")),
          last_dividend_value:      raw_value(stats, "lastDividendValue")&.round(4),
          last_split_date:          epoch_to_date(raw_value(stats, "lastSplitDate")),
          last_split_factor:        stats["lastSplitFactor"],
        }.compact

        unless result[:pays_dividend]
          result[:note] = "This company does not currently pay a dividend."
        end

        JSON.generate(result)
      rescue => e
        "Error fetching dividend info for #{symbol}: #{e.message}"
      end
    end
  end
end
