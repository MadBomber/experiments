# frozen_string_literal: true

class Scene < ApplicationRecord
  STATUSES       = %w[draft ready_for_review released].freeze
  TRANSITIONS    = %w[cut_to dissolve_to fade_out smash_cut match_cut none].freeze
  TIME_OF_DAY    = %w[day night dawn dusk continuous later moments_later].freeze
  INT_EXT        = %w[interior exterior both].freeze

  belongs_to :project
  has_many   :scene_characters,  dependent: :destroy
  has_many   :characters,        through: :scene_characters
  has_many   :scene_runs,        dependent: :destroy
  has_many   :research_materials, dependent: :destroy
  has_many   :beats,             foreign_key: :scene_id, dependent: :nullify
  has_many   :scene_comments,    dependent: :destroy
  belongs_to :releasing_user, class_name: "User",
             foreign_key: :released_by, optional: true

  validates :name,            presence: true
  validates :number,          presence: true, numericality: { only_integer: true }
  validates :status,          inclusion: { in: STATUSES }
  validates :revision_number, numericality: { greater_than: 0 }
  validates :transition_out,  inclusion: { in: TRANSITIONS }, allow_blank: true
  validates :interior_exterior, inclusion: { in: INT_EXT },   allow_blank: true
  validates :scene_heading_time, inclusion: { in: TIME_OF_DAY }, allow_blank: true

  scope :released,     -> { where(status: "released") }
  scope :by_position,  -> { order(position: :asc, number: :asc) }

  def draft?            = status == "draft"
  def ready_for_review? = status == "ready_for_review"
  def released?         = status == "released"
  def may_submit?       = draft?
  def may_release?      = ready_for_review?
  def may_reject?       = ready_for_review?

  def submit!
    new_revision = submitted_at.present? ? revision_number + 1 : revision_number
    update!(status: "ready_for_review", submitted_at: Time.current,
            revision_number: new_revision)
  end

  def release!(by_user: nil)
    update!(status: "released", released_at: Time.current,
            released_by: by_user&.id)
  end

  def reject!(notes: nil)
    update!(status: "draft", rejection_notes: notes)
  end

  def beat_structure_list
    return [] if beat_structure.blank?
    JSON.parse(beat_structure)
  rescue JSON::ParserError
    []
  end
end
