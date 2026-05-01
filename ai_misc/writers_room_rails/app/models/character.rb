class Character < ApplicationRecord
  has_many :castings,          dependent: :destroy
  has_many :actors,            through: :castings
  has_many :projects,          through: :castings
  has_many :character_arcs,    dependent: :destroy
  has_many :scene_characters,  dependent: :destroy
  has_many :scenes,            through: :scene_characters
  has_many :transcript_lines,  dependent: :nullify
  has_many :research_materials, dependent: :nullify

  validates :name,          presence: true
  validates :input_tokens,  numericality: { greater_than_or_equal_to: 0 }
  validates :output_tokens, numericality: { greater_than_or_equal_to: 0 }
  validates :total_tokens,  numericality: { greater_than_or_equal_to: 0 }
end
