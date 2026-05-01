# frozen_string_literal: true

class CreateSceneRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :scene_runs do |t|
      t.references :scene,      null: false, foreign_key: true
      t.string     :status,     null: false, default: "queued"
      t.datetime   :started_at
      t.datetime   :completed_at
      t.integer    :started_by

      t.timestamps
    end

    add_index :scene_runs, :status
  end
end
