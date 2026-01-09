# frozen_string_literal: true

module FactDb
  module Models
    class EntityMention < ActiveRecord::Base
      self.table_name = "fact_db_entity_mentions"

      belongs_to :fact, class_name: "FactDb::Models::Fact"
      belongs_to :entity, class_name: "FactDb::Models::Entity"

      validates :mention_text, presence: true
      validates :fact_id, uniqueness: { scope: [:entity_id, :mention_text] }

      # Mention roles
      ROLES = %w[subject object location temporal instrument beneficiary].freeze

      validates :mention_role, inclusion: { in: ROLES }, allow_nil: true

      scope :by_role, ->(role) { where(mention_role: role) }
      scope :subjects, -> { by_role("subject") }
      scope :objects, -> { by_role("object") }
      scope :high_confidence, -> { where("confidence >= ?", 0.9) }

      def subject?
        mention_role == "subject"
      end

      def object?
        mention_role == "object"
      end
    end
  end
end
