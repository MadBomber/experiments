module Battleships
  class Ship
    SIZES = {
      submarine: 1,
      destroyer: 2,
      cruiser: 3,
      battleship: 4,
      aircraft_carrier: 5
    }

    attr_reader :type, :size

    def initialize type
      @type = type.to_sym
      @size = SIZES[@type]
      @hits = 0
    end

    def hit
      @hits += 1
    end

    def sunk?
      @hits >= size
    end

    def self.submarine
      Ship.new(:submarine)
    end

    def self.destroyer
      Ship.new(:destroyer)
    end

    def self.cruiser
      Ship.new(:cruiser)
    end

    def self.battleship
      Ship.new(:battleship)
    end

    def self.aircraft_carrier
      Ship.new(:aircraft_carrier)
    end
  end
end