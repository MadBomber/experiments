require "httparty"

module Finn
  module Tools
    class CurrencyConverter < RubyLLM::Tool
      description "Convert an amount from one currency to another using live exchange rates. " \
                  "Supports all major world currencies (USD, EUR, GBP, JPY, CHF, CAD, AUD, etc.)."

      param :amount, desc: "The numeric amount to convert (e.g. 100, 1500.50)"
      param :base,   desc: "The source currency code (e.g. USD, EUR, GBP)"
      param :quote,  desc: "The target currency code (e.g. EUR, JPY, GBP)"

      def execute(amount:, base:, quote:)
        base  = base.upcase.strip
        quote = quote.upcase.strip
        amt   = amount.to_f

        raise "Amount must be a positive number" if amt <= 0

        response = HTTParty.get(
          "https://api.frankfurter.app/latest",
          query:   { from: base, to: quote, amount: amt },
          headers: { "Accept" => "application/json" },
          timeout: 10
        )

        raise "HTTP #{response.code} from exchange rate API" unless response.success?

        data      = JSON.parse(response.body)
        error_msg = data["message"]
        raise error_msg if error_msg

        converted = data.dig("rates", quote)
        raise "Currency '#{quote}' not found in response" unless converted

        rate = converted / amt

        JSON.generate({
          amount:           amt,
          from_currency:    base,
          to_currency:      quote,
          converted_amount: converted.round(4),
          exchange_rate:    rate.round(6),
          rate_date:        data["date"],
          formatted:        "#{amt} #{base} = #{converted.round(2)} #{quote}",
        })
      rescue => e
        "Currency conversion error: #{e.message}"
      end
    end
  end
end
