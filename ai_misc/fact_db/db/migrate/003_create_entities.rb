# frozen_string_literal: true

class CreateEntities < ActiveRecord::Migration[7.0]
  def change
    create_table :fact_db_entities do |t|
      # Identity
      t.string :canonical_name, null: false, limit: 500
      t.string :entity_type, null: false, limit: 50

      # Resolution metadata
      t.string :resolution_status, null: false, default: "unresolved", limit: 20
      t.bigint :merged_into_id

      # Descriptive metadata
      t.text :description
      t.jsonb :metadata, null: false, default: {}

      # Vector embedding for semantic matching
      t.vector :embedding, limit: 1536

      t.timestamps
    end

    add_index :fact_db_entities, :canonical_name
    add_index :fact_db_entities, :entity_type
    add_index :fact_db_entities, :resolution_status
    add_foreign_key :fact_db_entities, :fact_db_entities,
                    column: :merged_into_id, on_delete: :nullify

    # HNSW index for vector similarity search
    execute <<-SQL
      CREATE INDEX idx_entities_embedding ON fact_db_entities
      USING hnsw (embedding vector_cosine_ops);
    SQL
  end
end
