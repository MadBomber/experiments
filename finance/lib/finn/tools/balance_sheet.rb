module Finn
  module Tools
    class BalanceSheet < RubyLLM::Tool
      include YahooFinance

      description "Get annual balance sheet history for a stock: total assets, liabilities, " \
                  "stockholder equity, cash, short/long-term debt, and goodwill for the last 4 years."

      param :symbol, desc: "The stock ticker symbol (e.g. AAPL, MSFT, GOOGL)"

      def execute(symbol:)
        symbol     = symbol.upcase.strip
        data       = quote_summary(symbol, ["balanceSheetHistory"])
        statements = data.dig("balanceSheetHistory", "balanceSheetStatements") || []

        rows = statements.map do |s|
          {
            period:                    epoch_to_date(raw_value(s, "endDate")),
            total_assets:              format_large_number(raw_value(s, "totalAssets")),
            total_liabilities:         format_large_number(raw_value(s, "totalLiab")),
            stockholder_equity:        format_large_number(raw_value(s, "totalStockholderEquity")),
            cash_and_equivalents:      format_large_number(raw_value(s, "cash")),
            short_term_investments:    format_large_number(raw_value(s, "shortTermInvestments")),
            net_receivables:           format_large_number(raw_value(s, "netReceivables")),
            inventory:                 format_large_number(raw_value(s, "inventory")),
            long_term_debt:            format_large_number(raw_value(s, "longTermDebt")),
            short_long_term_debt:      format_large_number(raw_value(s, "shortLongTermDebt")),
            goodwill:                  format_large_number(raw_value(s, "goodWill")),
            intangible_assets:         format_large_number(raw_value(s, "intangibleAssets")),
            retained_earnings:         format_large_number(raw_value(s, "retainedEarnings")),
            book_value_per_share:      raw_value(s, "bookValuePerShare")&.round(2),
          }.compact
        end

        JSON.generate({ symbol: symbol, balance_sheets: rows })
      rescue => e
        "Error fetching balance sheet for #{symbol}: #{e.message}"
      end
    end
  end
end
