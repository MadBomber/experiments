require 'uri'
require 'yahoo_stocks/common'

module YahooStocks
  module Endpoint

    extend URI::Escape
    extend YahooStocks::Common

    ENDPOINT = 'http://download.finance.yahoo.com/d/quotes.csv?'
    FORMAT = [:symbol, :last_trade_price_only, :change, :previous_close] #

    def self.compose_quotes(symbols, opts = nil)
      format = get_format(opts[:format] || FORMAT)
      symbols = get_values(symbols)
      uri = get_uri(format, s: symbols)
      URI.parse(uri)
    end

    private

    def self.get_uri(format, options={})
      ENDPOINT + joined(options) + "&f=#{format}"
    end

    def self.joined(options)
      out = options.inject('') do |s, el|
        option, values = el
        values = get_values(values)
        s << "#{option}=#{values.map{ |v| escape(v) }.join(',')}&"
      end
      out.chomp!('&')
      out
    end

  end
end

