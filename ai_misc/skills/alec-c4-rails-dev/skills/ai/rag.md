# RAG & Vector Search (pgvector)

> **Stack:** PostgreSQL (pgvector extension), `neighbor` gem.
> **Goal:** Retrieval-Augmented Generation (Search by semantic meaning).

## 1. Setup (Postgres)
Enable the extension in a migration.

```ruby
class EnableVectorExtension < ActiveRecord::Migration[8.0]
  def change
    enable_extension "vector"
  end
end
```

## 2. Model Setup
Use the `neighbor` gem for easier ActiveRecord integration.

```ruby
# Gemfile
gem "neighbor"

# app/models/document.rb
class Document < ApplicationRecord
  has_neighbors :embedding
  
  # Callback to generate embedding on save
  after_save :generate_embedding, if: :content_changed?
end
```

## 3. Embedding Generation
Use a dedicated interaction to fetch embeddings (e.g., via OpenAI `text-embedding-3-small`).

```ruby
# app/interactions/documents/embed.rb
def execute
  vector = OpenAI::Client.new.embeddings(
    parameters: { model: "text-embedding-3-small", input: document.content }
  )
  document.update_column(:embedding, vector)
end
```

## 4. Semantic Search
```ruby
# Find 5 most similar documents
relevant_docs = Document.nearest_neighbors(:embedding, query_embedding, distance: "cosine").first(5)
```
