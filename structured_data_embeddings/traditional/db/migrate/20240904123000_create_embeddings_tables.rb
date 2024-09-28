class CreateEmbeddingsTables < ActiveRecord::Migration[6.0]
  def change
    # Create the embeddings table
    create_table :embeddings do |t|
      t.json :data, null: false
      t.text :content, null: false
      t.column :values, :vector, limit: 768  # Adjust vector dimension as needed

      t.timestamps
    end
    # Add comments to the embeddings table
    reversible do |dir|
      dir.up do
        execute <<-SQL
          COMMENT ON TABLE embeddings IS 'Stores embeddings for document line ranges';
          COMMENT ON COLUMN embeddings.id IS 'Auto-generated sequential primary key';
          COMMENT ON COLUMN embeddings.data IS 'JSON of content';
          COMMENT ON COLUMN embeddings.content IS 'GRON of data';
          COMMENT ON COLUMN embeddings.values IS 'Vector representation of the embedding';
        SQL
      end
    end


  end
end
