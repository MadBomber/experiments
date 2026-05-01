# frozen_string_literal: true

class SceneRun < ApplicationRecord
  STATUSES = %w[queued running completed failed].freeze

  belongs_to :scene
  has_many   :transcript_lines, dependent: :destroy
  belongs_to :starter, class_name: "User",
             foreign_key: :started_by, optional: true

  validates :status, inclusion: { in: STATUSES }

  def completed? = status == "completed"
  def running?   = status == "running"
  def queued?    = status == "queued"
  def failed?    = status == "failed"
end
