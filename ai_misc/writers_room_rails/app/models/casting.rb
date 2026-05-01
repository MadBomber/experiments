class Casting < ApplicationRecord
  belongs_to :actor
  belongs_to :character
  belongs_to :project

  validates :character_id, uniqueness: { scope: :project_id,
    message: "already has a casting in this project" }
end
