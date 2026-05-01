# frozen_string_literal: true

class CreateProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :projects do |t|
      t.string  :title,                  null: false
      t.text    :description
      t.string  :genre
      t.string  :tagline
      # narrative
      t.text    :setting
      t.text    :tone
      t.text    :logline
      t.text    :synopsis
      t.text    :story_arc
      t.text    :plot_points
      t.text    :conflicts
      t.text    :core_stakes
      t.text    :conflict_escalation
      # prep
      t.text    :research_notes
      t.text    :world_building_notes
      t.text    :similar_works
      t.text    :visual_references
      t.text    :differentiation_notes
      t.text    :marketing_angle
      t.text    :title_alternatives
      # workflow
      t.string  :prep_status,            null: false, default: "concept"
      t.integer :created_by
      # production planning (from screenplay research)
      t.integer :target_page_count
      t.integer :target_runtime_minutes

      t.timestamps
    end
  end
end
