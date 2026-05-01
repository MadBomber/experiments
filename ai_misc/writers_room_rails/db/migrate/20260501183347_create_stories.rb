# frozen_string_literal: true

class CreateStories < ActiveRecord::Migration[8.1]
  def change
    create_table :stories do |t|
      t.references :project,      null: false, foreign_key: true
      t.string     :title
      t.string     :act_structure, null: false, default: "three_act"
      t.text       :narrative_arc
      t.text       :acts
      t.text       :plot_points
      t.text       :conflict_escalation
      t.text       :resolution
      # production planning (from screenplay research)
      t.integer    :target_page_count

      t.timestamps
    end
  end
end
