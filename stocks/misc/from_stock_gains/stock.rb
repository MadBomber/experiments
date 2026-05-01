class StockGains::Stock
  attr_accessor :name, :cur_price, :prev_close, :open, :year_trgt
  attr_accessor :d_range, :y_range,:days_value, :pe, :eps, :shares

  def initialize(name, cur_price, prev_close, open, year_trgt, d_range, y_range, pe, eps, shares)
    @name = name
    @cur_price = cur_price
    @prev_close = prev_close
    @open = open
    @year_trgt = year_trgt
    @d_range = d_range
    @y_range = y_range
    @pe = pe
    @eps = eps
    @shares = shares
    calculate_days_value
  end

  def self.all 
    @@all ||= create_stock_from_portfolio
  end

  def calculate_days_value
    @days_value = ((cur_price.to_f * shares.to_f) - (prev_close.to_f * shares.to_f)).round(2).to_f 
  end

  def self.create_stock_from_portfolio
    CSV.foreach("portfolio.csv").collect do |stock|
      s = (retrieve_stock(stock) << stock[1]).flatten
      new(s[0], s[1], s[2], s[3], s[4], s[5], s[6], s[7], s[8], s[9])
    end
  end

  def self.retrieve_stock(stock)
    url = "http://finance.yahoo.com/d/quotes.csv?s=#{stock.first}&f=napot8mwre"
    open(url) do |csv|
      CSV.parse(csv).collect{ |row| row }
    end
  end
end