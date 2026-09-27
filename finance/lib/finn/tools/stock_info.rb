module Finn
  module Tools
    class StockInfo < RubyLLM::Tool
      include YahooFinance

      description "Get comprehensive company information for a stock: business description, " \
                  "sector, industry, country, employees, website, and key financial metrics " \
                  "(revenue growth, margins, ROE, debt/equity, current ratio)."

      param :symbol, desc: "The stock ticker symbol (e.g. AAPL, MSFT, GOOGL)"

      def execute(symbol:)
        symbol  = symbol.upcase.strip
        data    = quote_summary(symbol, %w[summaryProfile assetProfile financialData])

        profile    = data["summaryProfile"] || data["assetProfile"] || {}
        financials = data["financialData"]  || {}

        result = {
          symbol:              symbol,
          sector:              profile["sector"],
          industry:            profile["industry"],
          country:             profile["country"],
          city:                profile["city"],
          state:               profile["state"],
          website:             profile["website"],
          full_time_employees: profile["fullTimeEmployees"],
          business_summary:    profile["longBusinessSummary"],
          revenue_growth:      fmt_pct(raw_value(financials, "revenueGrowth")),
          earnings_growth:     fmt_pct(raw_value(financials, "earningsGrowth")),
          gross_margins:       fmt_pct(raw_value(financials, "grossMargins")),
          ebitda_margins:      fmt_pct(raw_value(financials, "ebitdaMargins")),
          operating_margins:   fmt_pct(raw_value(financials, "operatingMargins")),
          profit_margins:      fmt_pct(raw_value(financials, "profitMargins")),
          return_on_assets:    fmt_pct(raw_value(financials, "returnOnAssets")),
          return_on_equity:    fmt_pct(raw_value(financials, "returnOnEquity")),
          debt_to_equity:      raw_value(financials, "debtToEquity")&.round(2),
          current_ratio:       raw_value(financials, "currentRatio")&.round(2),
          quick_ratio:         raw_value(financials, "quickRatio")&.round(2),
          total_cash:          format_large_number(raw_value(financials, "totalCash")),
          total_debt:          format_large_number(raw_value(financials, "totalDebt")),
          free_cashflow:       format_large_number(raw_value(financials, "freeCashflow")),
        }.compact

        JSON.generate(result)
      rescue => e
        "Error fetching company info for #{symbol}: #{e.message}"
      end

      private

      def fmt_pct(val)
        val ? "#{(val.to_f * 100).round(2)}%" : nil
      end
    end
  end
end
