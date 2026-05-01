require 'yahoo_stocks/endpoint/tags'

module YahooStocks
  module Common

    include YahooStocks::Endpoint::Tags

    private

    def get_values(values)
      case values
      when String then [values]
      when Symbol then [values.to_s]
      when Array then values.map(&:to_s)
      end
    end

    def get_format(tags)
      tags.map! do |tag|
        tag = tag.to_sym
        case tag
        when *TAGS.keys then TAGS[tag]
        when *TAGS.values then tag
        else raise "invalid format: #{tag}"
        end
      end

      tags.compact.join

    end
  end
end
