module EventCoordinates
  class Coordinate
    attr_reader :id, :event_id, :type, :confidence, :data, :references

    def initialize(type:, confidence: nil, data: nil, id: nil, event_id: nil, references: [])
      @id         = id
      @event_id   = event_id
      @type       = type.to_s  # 'temporal' or 'geospatial'
      @confidence = confidence
      @data       = data       # Temporal or Geospatial instance
      @references = references # Array of { event_id:, role: }
    end

    def temporal?   = @type == 'temporal'
    def geospatial? = @type == 'geospatial'

    def certain?
      @confidence.nil? || @confidence >= 0.9
    end

    def tentative?
      @confidence && @confidence < 0.9
    end

    def to_s
      conf = @confidence ? " (confidence: %.1f)" % @confidence : ""
      "#{@type}#{conf}: #{@data}"
    end
  end
end
