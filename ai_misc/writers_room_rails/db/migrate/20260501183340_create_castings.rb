# frozen_string_literal: true

class CreateCastings < ActiveRecord::Migration[8.1]
  def change
    create_table :castings do |t|
      t.references :actor,     null: false, foreign_key: true
      t.references :character, null: false, foreign_key: true
      t.references :project,   null: false, foreign_key: true

      t.timestamps
    end

    add_index :castings, [:character_id, :project_id], unique: true
  end
end
