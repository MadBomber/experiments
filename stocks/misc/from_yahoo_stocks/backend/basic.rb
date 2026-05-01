require 'csv'

module YahooStocks
  module Backend
    class Basic

      def produce(*args)
        raise NotImplementedError, 'backend not implemented'
      end

    end
  end
end

