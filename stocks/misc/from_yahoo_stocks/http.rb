require 'net/http'

module YahooStocks
  module Http

    def http_get(uri)
      Net::HTTP.get_response(uri)
    end

  end
end
