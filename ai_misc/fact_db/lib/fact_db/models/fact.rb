# frozen_string_literal: true

module FactDb
  module Models
    class Fact < ActiveRecord::Base
      self.table_name = "fact_db_facts"

      has_many :entity_mentions, class_name: "FactDb::Models::EntityMention",
               foreign_key: :fact_id, dependent: :destroy
      has_many :entities, through: :entity_mentions

      has_many :fact_sources, class_name: "FactDb::Models::FactSource",
               foreign_key: :fact_id, dependent: :destroy
      has_many :source_contents, through: :fact_sources, source: :content

      belongs_to :superseded_by, class_name: "FactDb::Models::Fact",
                 foreign_key: :superseded_by_id, optional: true
      has_many :supersedes, class_name: "FactDb::Models::Fact",
               foreign_key: :superseded_by_id

      validates :fact_text, presence: true
      validates :fact_hash, presence: true
      validates :valid_at, presence: true
      validates :status, presence: true

      before_validation :generate_fact_hash, on: :create

      # Fact statuses
      STATUSES = %w[canonical superseded corroborated synthesized].freeze
      EXTRACTION_METHODS = %w[manual llm rule_based].freeze

      validates :status, inclusion: { in: STATUSES }
      validates :extraction_method, inclusion: { in: EXTRACTION_METHODS }, allow_nil: true

      # Core scopes
      scope :canonical, -> { where(status: "canonical") }
      scope :superseded, -> { where(status: "superseded") }
      scope :synthesized, -> { where(status: "synthesized") }

      # Temporal scopes - the heart of the Event Clock
      scope :currently_valid, -> { where(invalid_at: nil) }
      scope :historical, -> { where.not(invalid_at: nil) }

      scope :valid_at, lambda { |date|
        where("valid_at <= ?", date)
          .where("invalid_at > ? OR invalid_at IS NULL", date)
      }

      scope :valid_between, lambda { |from, to|
        where("valid_at <= ? AND (invalid_at > ? OR invalid_at IS NULL)", to, from)
      }

      scope :became_valid_between, lambda { |from, to|
        where(valid_at: from..to)
      }

      scope :became_invalid_between, lambda { |from, to|
        where(invalid_at: from..to)
      }

      # Entity filtering
      scope :mentioning_entity, lambda { |entity_id|
        joins(:entity_mentions).where(fact_db_entity_mentions: { entity_id: entity_id })
      }

      scope :with_role, lambda { |entity_id, role|
        joins(:entity_mentions).where(
          fact_db_entity_mentions: { entity_id: entity_id, mention_role: role }
        )
      }

      # Full-text search
      scope :search_text, lambda { |query|
        where("to_tsvector('english', fact_text) @@ plainto_tsquery('english', ?)", query)
      }

      # Extraction method
      scope :extracted_by, ->(method) { where(extraction_method: method) }

      # Confidence filtering
      scope :high_confidence, -> { where("confidence >= ?", 0.9) }
      scope :low_confidence, -> { where("confidence < ?", 0.5) }

      def currently_valid?
        invalid_at.nil?
      end

      def valid_at?(date)
        valid_at <= date && (invalid_at.nil? || invalid_at > date)
      end

      def duration
        return nil if invalid_at.nil?

        invalid_at - valid_at
      end

      def duration_days
        return nil if invalid_at.nil?

        (invalid_at.to_date - valid_at.to_date).to_i
      end

      def superseded?
        status == "superseded"
      end

      def synthesized?
        status == "synthesized"
      end

      def invalidate!(at: Time.current)
        update!(invalid_at: at)
      end

      def supersede_with!(new_fact_text, valid_at:)
        transaction do
          new_fact = self.class.create!(
            fact_text: new_fact_text,
            valid_at: valid_at,
            status: "canonical",
            extraction_method: extraction_method
          )

          update!(
            status: "superseded",
            superseded_by_id: new_fact.id,
            invalid_at: valid_at
          )

          new_fact
        end
      end

      def add_mention(entity:, text:, role: nil, confidence: 1.0)
        entity_mentions.find_or_create_by!(entity: entity, mention_text: text) do |m|
          m.mention_role = role
          m.confidence = confidence
        end
      end

      def add_source(content:, type: "primary", excerpt: nil, confidence: 1.0)
        fact_sources.find_or_create_by!(content: content) do |s|
          s.source_type = type
          s.excerpt = excerpt
          s.confidence = confidence
        end
      end

      # Get source facts for synthesized facts
      def source_facts
        return Fact.none unless derived_from_ids.any?

        Fact.where(id: derived_from_ids)
      end

      # Get facts that corroborate this one
      def corroborating_facts
        return Fact.none unless corroborated_by_ids.any?

        Fact.where(id: corroborated_by_ids)
      end

      # Evidence chain - trace back to original content
      def evidence_chain
        sources = source_contents.to_a

        if synthesized? && derived_from_ids.any?
          source_facts.each do |source_fact|
            sources.concat(source_fact.evidence_chain)
          end
        end

        sources.uniq
      end

      # Vector similarity search
      def self.nearest_neighbors(embedding, limit: 10)
        return none unless embedding

        order(Arel.sql("embedding <=> '#{embedding}'")).limit(limit)
      end

      private

      def generate_fact_hash
        self.fact_hash = Digest::SHA256.hexdigest(fact_text) if fact_text.present?
      end
    end
  end
end
