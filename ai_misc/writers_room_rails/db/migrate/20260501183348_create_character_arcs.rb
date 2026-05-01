# frozen_string_literal: true

class CreateCharacterArcs < ActiveRecord::Migration[8.1]
  def change
    create_table :character_arcs do |t|
      t.references :character, null: false, foreign_key: true
      t.references :project,   null: false, foreign_key: true
      t.text       :arc_description
      t.text       :arc_start_state
      t.text       :arc_end_goal
      t.text       :current_position
      t.text       :key_turning_points

      t.timestamps
    end

    add_index :character_arcs, [:character_id, :project_id], unique: true
  end
end
