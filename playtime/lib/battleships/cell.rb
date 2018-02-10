module Battleships
  class Cell
    attr_accessor :content

    def receive_shot
      @shot = true
      content.hit unless empty?
    end

    def shot?
      @shot
    end

    def empty?
      !content
    end

    def status
      if shot?
        return empty? ? :miss : :hit
      end
      :none
    end
  end
end