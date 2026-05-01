# frozen_string_literal: true

class CreateScenes < ActiveRecord::Migration[8.1]
  def change
    create_table :scenes do |t|
      t.references :project,    null: false, foreign_key: true
      t.integer    :number,     null: false
      t.string     :name,       null: false
      t.string     :location
      t.integer    :week
      t.text       :context
      t.text       :beat_structure
      t.text       :atmosphere
      t.text       :key_imagery
      t.string     :status,     null: false, default: "draft"
      t.datetime   :submitted_at
      t.datetime   :released_at
      t.integer    :released_by
      # Research additions
      t.integer    :position                               # drag-reorder ordering
      t.string     :transition_out, default: "cut_to"     # cut_to/dissolve_to/fade_out/smash_cut/match_cut/none
      t.decimal    :estimated_pages, precision: 4, scale: 1
      t.string     :interior_exterior                     # interior/exterior/both
      t.string     :scene_heading_time                    # day/night/dawn/dusk/continuous/later
      t.integer    :revision_number, default: 1, null: false
      t.text       :rejection_notes

      t.timestamps
    end

    add_index :scenes, [:project_id, :number]
    add_index :scenes, [:project_id, :position]
    add_index :scenes, :status
  end
end
