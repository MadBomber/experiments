# frozen_string_literal: true

class Story < ApplicationRecord
  ACT_STRUCTURES = %w[three_act five_act hero_journey four_act].freeze
  PLOT_ARCHETYPES = %w[quest romance revenge redemption coming_of_age rags_to_riches
                       tragedy rebirth overcoming_the_monster other].freeze

  belongs_to :project

  validates :act_structure,  inclusion: { in: ACT_STRUCTURES }
  validates :plot_archetype, inclusion: { in: PLOT_ARCHETYPES }, allow_blank: true

  def acts_list
    return [] if acts.blank?
    JSON.parse(acts)
  rescue JSON::ParserError
    []
  end
end
