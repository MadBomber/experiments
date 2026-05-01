# frozen_string_literal: true

class Beat < ApplicationRecord
  BEAT_TYPES = %w[inciting_incident plot_point_1 midpoint plot_point_2
                  climax resolution general].freeze

  belongs_to :project
  belongs_to :scene, optional: true

  validates :title,     presence: true
  validates :beat_type, inclusion: { in: BEAT_TYPES }
end
