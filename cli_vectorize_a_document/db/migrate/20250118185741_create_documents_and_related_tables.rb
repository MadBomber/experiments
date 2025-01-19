class CreateDocumentsAndRelatedTables < ActiveRecord::Migration[6.0]
  def change
    # Create the documents table
    create_table :documents do |t|
      t.text :title, null: false
      t.text :filename, null: false

      t.timestamps
    end
    add_index :documents, :filename, unique: true
    # Add comments to the documents table
    reversible do |dir|
      dir.up do
        execute <<-SQL
          COMMENT ON TABLE documents IS 'Stores metadata for each document';
          COMMENT ON COLUMN documents.id IS 'Auto-generated sequential primary key';
          COMMENT ON COLUMN documents.title IS 'Title of the document';
          COMMENT ON COLUMN documents.filename IS 'Filename of the document';
        SQL
      end
    end

    # Create the contents table
    create_table :contents do |t|
      t.integer :document_id, null: false
      t.integer :line_number, null: false
      t.text :text, null: false
      t.tsvector :text_vector, generated_always_as: "to_tsvector('english', text)", stored: true

      t.timestamps
    end
    add_index :contents, [:document_id, :line_number], unique: true, name: "unique_document_line"
    add_index :contents, [:document_id, :line_number], name: "idx_contents_document_id_line_number"
    add_index :contents, :text_vector, using: :gin, name: "idx_contents_text_vector"
    add_foreign_key :contents, :documents, on_delete: :cascade
    # Add comments to the contents table
    reversible do |dir|
      dir.up do
        execute <<-SQL
          COMMENT ON TABLE contents IS 'Stores document content with line numbers, associated with documents';
          COMMENT ON COLUMN contents.id IS 'Auto-generated sequential primary key';
          COMMENT ON COLUMN contents.document_id IS 'Foreign key reference to the documents table';
          COMMENT ON COLUMN contents.line_number IS 'Line number in the document';
          COMMENT ON COLUMN contents.text IS 'The text content of the document line';
          COMMENT ON COLUMN contents.text_vector IS 'tsvector representation of the text for full-text search';
        SQL
      end
    end

    # Create the embeddings table
    create_table :embeddings do |t|
      t.integer :document_id, null: false
      t.int4range :lines, null: false
      t.column :values, :vector, limit: 768  # Adjust vector dimension as needed

      t.timestamps
    end
    add_index :embeddings, :document_id, name: "idx_embeddings_document_id"
    add_index :embeddings, :lines, using: :gist, name: "idx_embeddings_lines"
    add_foreign_key :embeddings, :documents, on_delete: :cascade
    # Add comments to the embeddings table
    reversible do |dir|
      dir.up do
        execute <<-SQL
          COMMENT ON TABLE embeddings IS 'Stores embeddings for document line ranges';
          COMMENT ON COLUMN embeddings.id IS 'Auto-generated sequential primary key';
          COMMENT ON COLUMN embeddings.document_id IS 'Foreign key reference to the documents table';
          COMMENT ON COLUMN embeddings.lines IS 'Integer range representing the lines covered by this embedding';
          COMMENT ON COLUMN embeddings.values IS 'Vector representation of the embedding';
        SQL
      end
    end

    # Create the pages table
    create_table :pages do |t|
      t.integer :document_id, null: false
      t.string :page_number, null: false, limit: 50
      t.int4range :lines, null: false

      t.timestamps
    end
    add_index :pages, :lines, using: :gist, name: "idx_pages_lines"
    add_foreign_key :pages, :documents, on_delete: :cascade
    # Add comments to the pages table
    reversible do |dir|
      dir.up do
        execute <<-SQL
          COMMENT ON TABLE pages IS 'Stores information about pages in documents';
          COMMENT ON COLUMN pages.id IS 'Auto-generated sequential primary key';
          COMMENT ON COLUMN pages.document_id IS 'Foreign key reference to the documents table';
          COMMENT ON COLUMN pages.page_number IS 'Page number of the document';
          COMMENT ON COLUMN pages.lines IS 'Integer range representing the lines covered by this page';
        SQL
      end
    end

    # Create the structures table
    create_table :structures do |t|
      t.integer :document_id, null: false
      t.string :block_name, null: false, limit: 255
      t.int4range :lines, null: false

      t.timestamps
    end
    add_index :structures, :lines, using: :gist, name: "idx_structures_lines"
    add_foreign_key :structures, :documents, on_delete: :cascade
    # Add comments to the structures table
    reversible do |dir|
      dir.up do
        execute <<-SQL
          COMMENT ON TABLE structures IS 'Stores block structures associated with documents';
          COMMENT ON COLUMN structures.id IS 'Auto-generated sequential primary key';
          COMMENT ON COLUMN structures.document_id IS 'Foreign key reference to the documents table';
          COMMENT ON COLUMN structures.block_name IS 'Name of the block in the document';
          COMMENT ON COLUMN structures.lines IS 'Integer range representing the lines covered by this block';
        SQL
      end
    end
  end
end
