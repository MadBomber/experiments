require 'time'

module EventCoordinates
  class Temporal
    attr_reader :id, :coordinate_id, :start_at, :end_at

    def initialize(start_at:, end_at: nil, id: nil, coordinate_id: nil)
      @id            = id
      @coordinate_id = coordinate_id
      @start_at      = start_at.is_a?(String) ? Time.parse(start_at) : start_at
      @end_at        = end_at.is_a?(String) ? Time.parse(end_at) : end_at if end_at
    end

    def instant?
      @end_at.nil?
    end

    def range?
      !instant?
    end

    def duration_seconds
      return 0 if instant?
      (@end_at - @start_at).to_i
    end

    def contains?(time)
      time = Time.parse(time) if time.is_a?(String)
      return @start_at == time if instant?
      time >= @start_at && time <= @end_at
    end

    def overlaps?(other)
      return false if instant? && other.instant?

      s1, e1 = @start_at, (@end_at || @start_at)
      s2, e2 = other.start_at, (other.end_at || other.start_at)
      s1 <= e2 && s2 <= e1
    end

    def to_s
      if instant?
        @start_at.strftime('%Y-%m-%d %H:%M')
      else
        "#{@start_at.strftime('%Y-%m-%d %H:%M')}..#{@end_at.strftime('%Y-%m-%d %H:%M')}"
      end
    end
  end
end
