# battleships/game.rb

module Battleships
  class Game

    BOARD_MARKERS = {
      miss: '-',
      hit: '*',
      none: ' '
    }.freeze

    BOARD_TEMPLATE = <<TEMPLATE
   ABCDEFGHIJ
  ------------
 1|<1>|1
 2|<2>|2
 3|<3>|3
 4|<4>|4
 5|<5>|5
 6|<6>|6
 7|<7>|7
 8|<8>|8
 9|<9>|9
10|<10>|10
  ------------
   ABCDEFGHIJ
TEMPLATE

    BOARD_TEMPLATE.freeze


    def initialize(playerClass, boardClass)
      @players =  [
                    initialize_player(playerClass, boardClass),
                    initialize_player(playerClass, boardClass)
                  ]

      player_1.opponent = player_2
      player_2.opponent = player_1
    end

    def player_1
      @players.first
    end

    def player_2
      @players.last
    end

    def initialize_player(playerClass, boardClass)
      player = playerClass.new
      player.board = boardClass.new
      player
    end

    def has_winner?
      players.any?(&:winner?)
    end

    def winner
      players.find(&:winner?)
    end

    def own_board_view player_number
      player = @players[player_number-1]
      create_print player.board do |cell|
        if cell.empty?
          BOARD_MARKERS[cell.status]
        else
          cell.shot? ? BOARD_MARKERS[:hit] : cell.content.type.to_s.upcase[0]
        end
      end
    end

    def opponent_board_view player_number
      player = @players[player_number-1]
      create_print player.opponent.board do |cell|
        BOARD_MARKERS[cell.status]
      end
    end

    #################################################################
    ## Delegation methods for use under dRb

    def place_ship player_number, ship_type, coordinates, orientation = :horizontally
      @players[player_number-1].place_ship ship_type, coordinates, orientation
    end

    #################################################################
    ## Private Don't Look

    private

    def players
      @players
    end


    def create_print board
      coord_handler = CoordinateHandler.new

      output = BOARD_TEMPLATE

      coord_handler.each_row do |row, number|
        print_row = row.map do |coord|
          yield board[coord]
        end.join('')

        output = output.sub("<#{number}>", print_row)
      end
      output
    end # def create_print board


  end # class Game
end # module Battleships