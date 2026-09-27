module Finn
  module Tools
    class IncomeStatement < RubyLLM::Tool
      include YahooFinance

      description "Get annual income statement history for a stock: revenue, gross profit, " \
                  "operating income, net income, EBITDA, and R&D expenses for the last 4 years."

      param :symbol, desc: "The stock ticker symbol (e.g. AAPL, MSFT, GOOGL)"

      def execute(symbol:)
        symbol     = symbol.upcase.strip
        data       = quote_summary(symbol, ["incomeStatementHistory"])
        statements = data.dig("incomeStatementHistory", "incomeStatementHistory") || []

        rows = statements.map do |s|
          {
            period:               epoch_to_date(raw_value(s, "endDate")),
            total_revenue:        format_large_number(raw_value(s, "totalRevenue")),
            cost_of_revenue:      format_large_number(raw_value(s, "costOfRevenue")),
            gross_profit:         format_large_number(raw_value(s, "grossProfit")),
            research_development: format_large_number(raw_value(s, "researchDevelopment")),
            selling_general_admin:format_large_number(raw_value(s, "sellingGeneralAdministrative")),
            operating_income:     format_large_number(raw_value(s, "operatingIncome")),
            ebitda:               format_large_number(raw_value(s, "ebitda")),
            net_income:           format_large_number(raw_value(s, "netIncome")),
            eps_basic:            raw_value(s, "basicEps")&.round(2),
            eps_diluted:          raw_value(s, "dilutedEps")&.round(2),
          }.compact
        end

        JSON.generate({ symbol: symbol, income_statements: rows })
      rescue => e
        "Error fetching income statement for #{symbol}: #{e.message}"
      end
    end
  end
end
