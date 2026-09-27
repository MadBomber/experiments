module Finn
  module Tools
    class CashFlow < RubyLLM::Tool
      include YahooFinance

      description "Get annual cash flow statement history for a stock: operating, investing, " \
                  "and financing cash flows, capital expenditures, and free cash flow for the last 4 years."

      param :symbol, desc: "The stock ticker symbol (e.g. AAPL, MSFT, GOOGL)"

      def execute(symbol:)
        symbol     = symbol.upcase.strip
        data       = quote_summary(symbol, ["cashflowStatementHistory"])
        statements = data.dig("cashflowStatementHistory", "cashflowStatements") || []

        rows = statements.map do |s|
          capex    = raw_value(s, "capitalExpenditures")&.to_f
          op_cf    = raw_value(s, "totalCashFromOperatingActivities")&.to_f
          free_cf  = (op_cf && capex) ? op_cf + capex : nil  # capex is negative in Yahoo data

          {
            period:                        epoch_to_date(raw_value(s, "endDate")),
            operating_cash_flow:           format_large_number(op_cf),
            investing_cash_flow:           format_large_number(raw_value(s, "totalCashflowsFromInvestingActivities")),
            financing_cash_flow:           format_large_number(raw_value(s, "totalCashFromFinancingActivities")),
            capital_expenditures:          format_large_number(capex),
            free_cash_flow:                format_large_number(free_cf),
            depreciation_amortization:     format_large_number(raw_value(s, "depreciation")),
            change_in_cash:                format_large_number(raw_value(s, "changeInCash")),
            dividends_paid:                format_large_number(raw_value(s, "dividendsPaid")),
            stock_repurchases:             format_large_number(raw_value(s, "repurchaseOfStock")),
          }.compact
        end

        JSON.generate({ symbol: symbol, cash_flow_statements: rows })
      rescue => e
        "Error fetching cash flow for #{symbol}: #{e.message}"
      end
    end
  end
end
