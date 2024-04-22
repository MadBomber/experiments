class StockGains::Portfolio
  attr_accessor :total 

  def initialize
    @total = 0
  end
  
  def call 
    list
    calculate_gains
    print_gains
  end

   def list
    puts "\n"
    puts "Stocks in Your Portfolio".center(68)
    puts "\n"
    puts " Stock Name" + " " * 46 + "Today's +/-"
    puts " " + "-" * 67
    StockGains::Stock.all.each.with_index(1) do |stock, i|
      name = stock.name.ljust(55, " ") 
      puts " #{i}. #{name} $#{stock.days_value}"
    end
    puts 
  end

  def calculate_gains
    StockGains::Stock.all.collect{ |stock|  @total += stock.days_value } 
    @total = @total.round(2).to_f
  end

  def print_gains
    puts "\n"
    puts " " * 20 + ":" + "-" * 29 + ":"  
    puts " " * 20 + "|    TODAY'S #{total > 0 ? "GAIN:" : "LOSS:"} $#{total} #{extra_spaces}|"
    puts " " * 20 + ":" + "-" * 29 + ":"
    puts "\n"
  end

  def extra_spaces
    " " * (9 - total.to_s.each_char.count)
  end
end