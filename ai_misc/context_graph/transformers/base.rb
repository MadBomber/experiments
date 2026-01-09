# frozen_string_literal: true

module ContextGraph
  module Transformers
    # Base transformer class - returns results as-is (JSON format)
    class Base
      # Transform query results to the target format
      #
      # @param results [QueryResult] The query results
      # @return [QueryResult] Transformed results (may modify in place)
      def transform(results)
        results
      end

      protected

      # Helper to safely get a value from hash or object
      def get_value(obj, key)
        if obj.is_a?(Hash)
          obj[key] || obj[key.to_s]
        elsif obj.respond_to?(key)
          obj.send(key)
        end
      end

      # Helper to format dates consistently
      def format_date(date)
        return nil if date.nil?

        if date.respond_to?(:strftime)
          date.strftime("%Y-%m-%d")
        else
          date.to_s
        end
      end

      # Helper to escape strings for output
      def escape_string(str)
        str.to_s.gsub('"', '\\"').gsub("\n", "\\n")
      end

      # Helper to create a variable name from a string
      def to_variable(str)
        str.to_s
           .downcase
           .gsub(/[^a-z0-9]+/, "_")
           .gsub(/^_|_$/, "")
           .slice(0, 30)
      end
    end
  end
end
