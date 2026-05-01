class StockGains::StockLookup
  attr_accessor :tickers

  def initialize
    @tickers = []
  end

  def call
    input = "" 
    loop do
      puts "Enter the stock ticker(s) of any stock you would like to view."
      puts "Separate stock tickers with a space.\n\n"
      input = gets.strip.downcase
      break if input == "e" || input == ""
      tickers << input.strip.scan(/\S[a-zA-Z]+/).join("+").upcase
      StockGains::CLI.new.print_stock_info(retrieve_stock_info(tickers))
      tickers.clear
    end
  end

  def retrieve_stock_info(tickers)
    StockGains::Stock.retrieve_stock(tickers).collect do |s|
      StockGains::Stock.new(s[0], s[1], s[2], s[3], s[4], s[5], s[6], s[7], s[8], s[9])
    end
  end
end 