# frozen_string_literal: true

module ContextGraph
  # A scoped query builder for temporal queries.
  # Allows chaining: layer.at("2023-06-15").query("Paula's role")
  class TemporalQuery
    def initialize(layer, date)
      @layer = layer
      @date = date
    end

    # Execute a query at this point in time
    #
    # @param query_text [String] The query
    # @param format [Symbol] Output format
    # @return [QueryResult] Results at this point in time
    def query(query_text, format: :triples, **options)
      @layer.query(query_text, format: format, at: @date, **options)
    end

    # Get all facts valid at this date
    def facts(**options)
      @layer.query("*", format: :json, at: @date, strategy: :temporal, **options)
    end

    # Get facts for a specific entity at this date
    def facts_for(entity, **options)
      @layer.query(entity.to_s, format: :json, at: @date, strategy: :temporal, **options)
    end

    # Compare this date to another
    def compare_to(other_date)
      @layer.diff("*", from: @date, to: other_date)
    end

    # The date this query is scoped to
    attr_reader :date
  end
end
