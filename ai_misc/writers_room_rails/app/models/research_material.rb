# frozen_string_literal: true

class ResearchMaterial < ApplicationRecord
  CATEGORIES = %w[world_building character_study historical visual other].freeze

  belongs_to :project
  belongs_to :character, optional: true
  belongs_to :scene,     optional: true

  validates :subject,  presence: true
  validates :category, inclusion: { in: CATEGORIES }

  def sources_list
    return [] if sources.blank?
    JSON.parse(sources)
  rescue JSON::ParserError
    []
  end
end
