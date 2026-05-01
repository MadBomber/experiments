class CharacterArc < ApplicationRecord
  ROLES = %w[protagonist antagonist mentor ally threshold_guardian
             trickster herald shapeshifter shadow supporting].freeze

  belongs_to :character
  belongs_to :project

  validates :character_id, uniqueness: { scope: :project_id }
  validates :role_in_story, inclusion: { in: ROLES }, allow_blank: true

  def key_turning_points_list
    return [] if key_turning_points.blank?
    JSON.parse(key_turning_points)
  rescue JSON::ParserError
    []
  end
end
