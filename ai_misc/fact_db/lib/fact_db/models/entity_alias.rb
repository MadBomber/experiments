# frozen_string_literal: true

module FactDb
  module Models
    class EntityAlias < ActiveRecord::Base
      self.table_name = "fact_db_entity_aliases"

      belongs_to :entity, class_name: "FactDb::Models::Entity"

      validates :alias_text, presence: true
      validates :alias_text, uniqueness: { scope: :entity_id }

      # Alias types
      TYPES = %w[name nickname email handle abbreviation title].freeze

      validates :alias_type, inclusion: { in: TYPES }, allow_nil: true

      scope :by_type, ->(type) { where(alias_type: type) }
      scope :high_confidence, -> { where("confidence >= ?", 0.9) }

      def self.find_entity_by_alias(text)
        find_by(["LOWER(alias_text) = ?", text.downcase])&.entity
      end
    end
  end
end
