# frozen_string_literal: true

class SceneCharacter < ApplicationRecord
  belongs_to :scene
  belongs_to :character

  validates :character_id, uniqueness: { scope: :scene_id }
end
