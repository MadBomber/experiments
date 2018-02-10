require_relative 'cell'
require_relative 'coordinate_handler'

module Battleships
  class Board
    SIZE = 10

    attr_accessor :width

    def initialize
      @grid = {}
      @coord_handler = CoordinateHandler.new
      @ships = []
      initialize_grid
    end

    def place_ship ship_type, coordinate, orientation = :horizontally
      ship = Ship.new ship_type

      coords = all_ship_coords ship, coordinate, orientation

      coords.each { |coord| grid[coord].content = ship }
      @ships << ship
    end

    def width
      SIZE
    end

    def height
      SIZE
    end

    def ships
      # note we do not pass the source array here as it would enable
      # callers to modify the board's ships, which would break encapsulation.
      # Instead we return a duplicate.
      @ships.dup
    end

    def receive_shot coordinate
      coord_handler.validate coordinate

      validate_coord_not_shot coordinate

      cell = grid[coordinate]
      cell.receive_shot

      if cell.content
        cell.content.sunk? ? :sunk : :hit
      else
        :miss
      end
    end

    def [] coordinate
      coord_handler.validate coordinate
      grid[coordinate]
    end

    def all_ships_sunk?
      return false if ships.empty?
      ships.all?(&:sunk?)
    end

    def inspect
      to_s
    end

    private

    attr_reader :grid, :coord_handler

    def initialize_grid
      coord_handler.each do |coord|
        grid[coord] = Cell.new
      end
    end

    def all_ship_coords ship, coord, orientation
      coord_handler.validate coord

      all_coords = coord_handler.from coord, ship.size, orientation

      validate_all_ship_coords all_coords, ship.size
    end

    def validate_all_ship_coords coords, size
      #ship is out of bounds if the ship is larger than the available coords
      fail 'Out of bounds' if size > coords.length

      validate_all_coords_available coords
    end

    def validate_all_coords_available coords
      coords.each do |coord|
        fail 'Coordinate already occupied' unless grid[coord].empty?
      end
    end

    def validate_coord_not_shot coord
      fail 'Coordinate has been shot already' if grid[coord].shot?
    end
  end
end