# frozen_string_literal: true

class SceneComment < ApplicationRecord
  belongs_to :scene
  belongs_to :user
  belongs_to :resolver, class_name: "User",
             foreign_key: :resolved_by_id, optional: true

  validates :body, presence: true
end
