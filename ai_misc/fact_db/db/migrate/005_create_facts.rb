# frozen_string_literal: true

class CreateFacts < ActiveRecord::Migration[7.0]
  def change
    create_table :fact_db_facts do |t|
      # The assertion
      t.text :fact_text, null: false
      t.string :fact_hash, null: false, limit: 64

      # Temporal validity (the Event Clock core concept)
      t.timestamptz :valid_at, null: false
      t.timestamptz :invalid_at  # NULL = still valid

      # Fact status
      t.string :status, null: false, default: "canonical", limit: 20

      # Resolution relationships
      t.bigint :superseded_by_id
      t.bigint :derived_from_ids, array: true, default: []
      t.bigint :corroborated_by_ids, array: true, default: []

      # Confidence and metadata
      t.float :confidence, default: 1.0
      t.string :extraction_method, limit: 50
      t.jsonb :metadata, null: false, default: {}

      # Vector embedding for semantic search
      t.vector :embedding, limit: 1536

      t.timestamps
    end

    add_index :fact_db_facts, :fact_hash
    add_index :fact_db_facts, :valid_at
    add_index :fact_db_facts, :invalid_at
    add_index :fact_db_facts, :status
    add_index :fact_db_facts, :metadata, using: :gin
    add_foreign_key :fact_db_facts, :fact_db_facts,
                    column: :superseded_by_id, on_delete: :nullify

    # Compound index for temporal queries (the key Event Clock query pattern)
    execute <<-SQL
      CREATE INDEX idx_facts_temporal_validity ON fact_db_facts(valid_at, invalid_at)
      WHERE status = 'canonical';
    SQL

    # Partial index for currently valid facts
    execute <<-SQL
      CREATE INDEX idx_facts_currently_valid ON fact_db_facts(id)
      WHERE invalid_at IS NULL AND status = 'canonical';
    SQL

    # Full-text search index
    execute <<-SQL
      CREATE INDEX idx_facts_fulltext ON fact_db_facts
      USING gin(to_tsvector('english', fact_text));
    SQL

    # HNSW index for vector similarity search
    execute <<-SQL
      CREATE INDEX idx_facts_embedding ON fact_db_facts
      USING hnsw (embedding vector_cosine_ops);
    SQL
  end
end
