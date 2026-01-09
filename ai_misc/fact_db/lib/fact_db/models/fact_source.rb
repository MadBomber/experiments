# frozen_string_literal: true

module FactDb
  module Models
    class FactSource < ActiveRecord::Base
      self.table_name = "fact_db_fact_sources"

      belongs_to :fact, class_name: "FactDb::Models::Fact"
      belongs_to :content, class_name: "FactDb::Models::Content"

      validates :fact_id, uniqueness: { scope: :content_id }

      # Source types
      TYPES = %w[primary supporting corroborating].freeze

      validates :source_type, inclusion: { in: TYPES }

      scope :primary, -> { where(source_type: "primary") }
      scope :supporting, -> { where(source_type: "supporting") }
      scope :corroborating, -> { where(source_type: "corroborating") }
      scope :high_confidence, -> { where("confidence >= ?", 0.9) }

      def primary?
        source_type == "primary"
      end

      def excerpt_preview(length: 100)
        return nil if excerpt.nil?
        return excerpt if excerpt.length <= length

        "#{excerpt[0, length]}..."
      end
    end
  end
end
