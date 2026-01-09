# frozen_string_literal: true

class CreateEntityAliases < ActiveRecord::Migration[7.0]
  def change
    create_table :fact_db_entity_aliases do |t|
      t.references :entity, null: false, foreign_key: { to_table: :fact_db_entities, on_delete: :cascade }
      t.string :alias_text, null: false, limit: 500
      t.string :alias_type, limit: 50  # name, nickname, email, handle, abbreviation
      t.float :confidence, default: 1.0

      t.timestamps
    end

    add_index :fact_db_entity_aliases, :alias_text
    add_index :fact_db_entity_aliases, [:entity_id, :alias_text], unique: true,
              name: "idx_unique_entity_alias"
  end
end
