module Battleships
  class Player
    attr_accessor :board, :opponent, :name

    def place_ship ship, coordinates, orientation = :horizontally
      board.place_ship ship, coordinates, orientation
    end

    def receive_shot coordinates
      fail 'Player has no board' unless board
      board.receive_shot coordinates
    end

    def shoot coordinates
      fail 'Player has no opponent' unless opponent
      opponent.receive_shot coordinates
    end

    def winner?
      fail 'Player has no opponent' unless opponent
      opponent.all_ships_sunk?
    end

    def all_ships_sunk?
      fail 'Player has no board' unless board
      board.all_ships_sunk?
    end
  end
end