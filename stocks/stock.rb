# experiments/stocks/stock.rb

require           'fin_tech'
require_relative  'datastore/csv'

class Stock
  include FinTech

  attr_accessor :company_name
  attr_accessor :data
  attr_accessor :ticker

  def initialize(ticker, datastore = Datastore::CSV)
    @ticker       = ticker
    @company_name = "Company Name"
    @data         = datastore.new(ticker)
  end
end

__END__

aapl = Stock.new('aapl', Datastore::CSV)
