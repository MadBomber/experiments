# frozen_string_literal: true

class CreateFactSources < ActiveRecord::Migration[7.0]
  def change
    create_table :fact_db_fact_sources do |t|
      t.references :fact, null: false, foreign_key: { to_table: :fact_db_facts, on_delete: :cascade }
      t.references :content, null: false, foreign_key: { to_table: :fact_db_contents, on_delete: :cascade }
      t.string :source_type, default: "primary", limit: 50  # primary, supporting, corroborating
      t.text :excerpt  # The specific portion that supports the fact
      t.float :confidence, default: 1.0

      t.timestamps
    end

    add_index :fact_db_fact_sources, [:fact_id, :content_id], unique: true,
              name: "idx_unique_fact_content"
  end
end
