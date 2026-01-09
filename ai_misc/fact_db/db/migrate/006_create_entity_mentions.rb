# frozen_string_literal: true

class CreateEntityMentions < ActiveRecord::Migration[7.0]
  def change
    create_table :fact_db_entity_mentions do |t|
      t.references :fact, null: false, foreign_key: { to_table: :fact_db_facts, on_delete: :cascade }
      t.references :entity, null: false, foreign_key: { to_table: :fact_db_entities, on_delete: :cascade }
      t.string :mention_text, null: false, limit: 500
      t.string :mention_role, limit: 50  # subject, object, location, etc.
      t.float :confidence, default: 1.0

      t.timestamps
    end

    add_index :fact_db_entity_mentions, [:fact_id, :entity_id, :mention_text],
              unique: true, name: "idx_unique_fact_entity_mention"
  end
end
