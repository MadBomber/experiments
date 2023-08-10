# experiments/stocks/datastore/csv.rb

require 'csv'
require 'forwardable'
require 'json'
require 'pathname'
require 'previous_dow'

module Datastore
  class CSV
    extend Forwardable
    def_delegators :@data, :first, :last, :size, :empty?, :[], :map, :select, :reject

    SOURCE_DOMAIN = "https://query1.finance.yahoo.com/v7/finance/download/"

    attr_accessor :ticker
    attr_accessor :data

    def initialize(ticker)
      @ticker     = ticker
      @data_path  = Pathname.pwd + "#{ticker.downcase}.csv"
      @data       = read_csv_data
    end


    #######################################################################
    # Read the CSV file associated with the give ticker symbol
    #
    def read_csv_data
      download_historical_prices unless @data_path.exist?

      csv_data = []

      ::CSV.foreach(@data_path, headers: true) do |row|
        csv_data << row.to_h
      end

      csv_data
    end

    #######################################################################
    # download a CSV file from https://query1.finance.yahoo.com
    # given a stock ticker symbol as a String
    # start and end dates
    #
    # For ticker "aapl" the downloaded file will be named "aapl.csv"
    # That filename will be renamed to "aapl_YYYYmmdd.csv" where the
    # date suffix is the end_date of the historical data.
    #
    def download_historical_prices(
          start_date: Date.new(2019, 1, 1),
          end_date:   previous_dow(:friday, Date.today)
        )

      start_timestamp = start_date.to_time.to_i
      end_timestamp   = end_date.to_time.to_i

      # TODO: replace curl with Faraday

      `curl -o #{@data_path} "#{SOURCE_DOMAIN}/#{ticker.upcase}?period1=#{start_timestamp}&period2=#{end_timestamp}&interval=1d&events=history&includeAdjustedClose=true"`

      check_csv_file
    end


    def check_csv_file
      f   = File.open(@data_path, 'r')
      c1  = f.read(1)

      if '{' == c1
        error_msg = JSON.parse("#{c1}#{f.read}")
        raise "Not OK: #{error_msg}"
      end
    end
  end
end

__END__

{
    "finance": {
        "error": {
            "code": "Unauthorized",
            "description": "Invalid cookie"
        }
    }
}




