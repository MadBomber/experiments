# frozen_string_literal: true

class CreateSceneCharacters < ActiveRecord::Migration[8.1]
  def change
    create_table :scene_characters do |t|
      t.references :scene,     null: false, foreign_key: true
      t.references :character, null: false, foreign_key: true
      t.text       :scene_objectives
      t.text       :arc_advancement

      t.timestamps
    end

    add_index :scene_characters, [:scene_id, :character_id], unique: true
  end
end
