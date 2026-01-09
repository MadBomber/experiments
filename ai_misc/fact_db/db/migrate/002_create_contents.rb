# frozen_string_literal: true

class CreateContents < ActiveRecord::Migration[7.0]
  def change
    create_table :fact_db_contents do |t|
      # Content identification
      t.string :content_hash, null: false, limit: 64
      t.string :content_type, null: false, limit: 50

      # The raw content (immutable)
      t.text :raw_text, null: false
      t.string :title, limit: 500

      # Source metadata
      t.text :source_uri
      t.jsonb :source_metadata, null: false, default: {}

      # Vector embedding for semantic search
      t.vector :embedding, limit: 1536

      # Timestamps
      t.timestamptz :captured_at, null: false
      t.timestamps
    end

    add_index :fact_db_contents, :content_hash, unique: true
    add_index :fact_db_contents, :captured_at
    add_index :fact_db_contents, :content_type
    add_index :fact_db_contents, :source_metadata, using: :gin

    # Full-text search index
    execute <<-SQL
      CREATE INDEX idx_contents_fulltext ON fact_db_contents
      USING gin(to_tsvector('english', raw_text));
    SQL

    # HNSW index for vector similarity search (if pgvector supports it)
    # This creates a cosine similarity index for fast nearest neighbor queries
    execute <<-SQL
      CREATE INDEX idx_contents_embedding ON fact_db_contents
      USING hnsw (embedding vector_cosine_ops);
    SQL
  end
end
