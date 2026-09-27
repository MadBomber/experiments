module Finn
  module Tools
    class StockRecommendations < RubyLLM::Tool
      include YahooFinance

      description "Get analyst recommendations for a stock: consensus rating (Strong Buy to Strong Sell " \
                  "counts per period) and the 10 most recent analyst upgrades/downgrades."

      param :symbol, desc: "The stock ticker symbol (e.g. AAPL, MSFT, GOOGL)"

      def execute(symbol:)
        symbol = symbol.upcase.strip
        data   = quote_summary(symbol, %w[recommendationTrend upgradeDowngradeHistory financialData])

        trend   = data.dig("recommendationTrend", "trend") || []
        history = data.dig("upgradeDowngradeHistory", "history") || []
        fdata   = data["financialData"] || {}

        consensus_rows = trend.map do |t|
          {
            period:      t["period"],
            strong_buy:  t["strongBuy"],
            buy:         t["buy"],
            hold:        t["hold"],
            sell:        t["sell"],
            strong_sell: t["strongSell"],
            total:       [t["strongBuy"], t["buy"], t["hold"], t["sell"], t["strongSell"]].compact.sum,
          }.compact
        end

        recent_actions = history.first(10).map do |h|
          {
            date:         epoch_to_date(h["epochGradeDate"]),
            firm:         h["firm"],
            from_grade:   h["fromGrade"],
            to_grade:     h["toGrade"],
            action:       h["action"],
          }.compact
        end

        result = {
          symbol:                   symbol,
          analyst_recommendation:   fdata["recommendationKey"],
          average_analyst_score:    raw_value(fdata, "recommendationMean")&.round(2),
          number_of_analysts:       raw_value(fdata, "numberOfAnalystOpinions"),
          target_price_high:        raw_value(fdata, "targetHighPrice"),
          target_price_low:         raw_value(fdata, "targetLowPrice"),
          target_price_mean:        raw_value(fdata, "targetMeanPrice"),
          target_price_median:      raw_value(fdata, "targetMedianPrice"),
          consensus_by_period:      consensus_rows,
          recent_analyst_actions:   recent_actions,
        }.compact

        JSON.generate(result)
      rescue => e
        "Error fetching recommendations for #{symbol}: #{e.message}"
      end
    end
  end
end
