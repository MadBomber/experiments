module Battleships
  class CoordinateHandler
    include Enumerable

    HORIZONTAL_COORDS = ('A'..'J').to_a
    VERTICAL_COORDS = (1..10).to_a
    COORD_REGEX = /^([A-J])([1-9]|10)$/

    def each
      VERTICAL_COORDS.each do |y|
        HORIZONTAL_COORDS.each do |x|
          yield coordinate x, y
        end
      end
    end

    def each_row
      VERTICAL_COORDS.each do |y|
        row = HORIZONTAL_COORDS.map do |x|
          coordinate x, y
        end
        yield row, y
      end
    end

    def validate coord
      fail 'Invalid coordinate' unless valid? coord
    end

    def valid? coord
      COORD_REGEX.match coord.to_s
    end

    def from start, size, orientation = :horizontally
      match = COORD_REGEX.match start

      x = match.captures.first
      y = match.captures.last

      if orientation.to_sym == :horizontally
        horizontal_coords_for x, y, size
      else
        vertical_coords_for x, y, size
      end
    end

    private

    def horizontal_coords_for x, y, size
      x_coords(x, size).map { |x| coordinate x, y }
    end

    def x_coords x, size
      start = HORIZONTAL_COORDS.index x
      HORIZONTAL_COORDS.slice start, size
    end

    def vertical_coords_for x, y, size
      y_coords(y, size).map { |y| coordinate x, y }
    end

    def y_coords y, size
      start = VERTICAL_COORDS.index Integer(y)
      VERTICAL_COORDS.slice start, size
    end

    def coordinate x, y
      "#{x}#{y}".to_sym
    end
  end
end