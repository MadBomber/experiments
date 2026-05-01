# frozen_string_literal: true

class Project < ApplicationRecord
  PREP_STATUSES = %w[concept seed_growing visualization research references identity ready].freeze

  has_many :castings,           dependent: :destroy
  has_many :characters,         through: :castings
  has_many :actors,             through: :castings
  has_many :scenes,             dependent: :destroy
  has_many :stories,            dependent: :destroy
  has_many :character_arcs,     dependent: :destroy
  has_many :research_materials, dependent: :destroy
  has_many :beats,              dependent: :destroy
  belongs_to :creator, class_name: "User", foreign_key: :created_by, optional: true

  validates :title,       presence: true
  validates :prep_status, inclusion: { in: PREP_STATUSES }

  def ready? = prep_status == "ready"
end
