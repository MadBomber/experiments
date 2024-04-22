module StockGains 
  class StockGains::CLI

    def call
      begin
        StockGains::Portfolio.new.call
        start
      rescue
        puts "\n\nTo upload your portfolio to Stock Gains, see installation at:"
        puts "https://github.com/frankNowinski/stock-gains\n\n"
        stock_lookup
      end 
      puts "\nGoodbye!"
    end

    def start
      input = ""
      begin
        puts "\nTo view more stock information, enter the number associated with"
        puts "the stock name in your portfolio or enter 'all' to display all."
        puts "Separate digits with a space to view multiple stocks."
        puts "(Enter 'e' at anytime throughout the program to exit)\n\n"
        input = gets.strip.downcase.scan(/\w+/)
      end until valid_input?(input) || input.first == "e"
      
      if input.first != "e" 
        input.first == "all" ? find_all : find(input)
        stock_lookup
      end
    end

    def valid_input?(input)
      input.first == "all" || input.map(&:to_i).all?{ |n| n.between?(1, StockGains::Stock.all.count)}
    end

    def find_all
      print_stock_info(StockGains::Stock.all)
    end

    def find(input)
      print_stock_info(input.map(&:to_i).collect{ |s| StockGains::Stock.all[s-1] })
    end

    def print_stock_info(stocks)
      puts "\n"
      stocks.each do |s|
        puts "#{s.name}".center(67)
        puts " " + "-" * 68
        puts " Asking Price:     $#{s.cur_price}".ljust(37, " ") + "Day's Range:    $#{s.d_range}"
        puts " Previous Close:   $#{s.prev_close}".ljust(37, " ") + "52 Week Range:  $#{s.y_range}"
        puts " Open:             $#{s.open}".ljust(37, " ") + "1 Year Target:  $#{s.year_trgt}"
        puts " P/E Ratio:        $#{s.pe}".ljust(37, " ") + "EPS:            $#{s.eps}"
        puts " Day's +/-:        $#{s.days_value}".ljust(37, " ") + "Shares:        #{s.shares}"
        puts "\n\n"
      end
    end

    def stock_lookup
      StockGains::StockLookup.new.call
    end
  end
end