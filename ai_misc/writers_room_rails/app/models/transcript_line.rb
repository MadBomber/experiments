# frozen_string_literal: true

class TranscriptLine < ApplicationRecord
  ELEMENT_TYPES    = %w[action character parenthetical dialogue transition scene_heading].freeze
  VOICE_QUALIFIERS = %w[none os vo cont].freeze

  belongs_to :scene_run
  belongs_to :character, optional: true

  validates :content,        presence: true
  validates :position,       presence: true, numericality: { only_integer: true }
  validates :element_type,   inclusion: { in: ELEMENT_TYPES }
  validates :voice_qualifier, inclusion: { in: VOICE_QUALIFIERS }, allow_blank: true
  validates :character_id, presence: true, if: -> { %w[dialogue parenthetical character].include?(element_type) }

  default_scope { order(:position) }
end
