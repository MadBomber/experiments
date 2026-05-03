---
name: rubyllm-embeddings
description: |
  Generate vector embeddings with RubyLLM. Use this skill for semantic search, recommendations, content similarity, RAG applications, and any task requiring numerical text representations.
---

# RubyLLM Embeddings

Transform text into numerical vectors for semantic search, recommendations, and content similarity.

## Basic Usage

```ruby
# Single text
embedding = RubyLLM.embed("Ruby is elegant")
vector = embedding.vectors  # Array of floats
puts "Dimension: #{vector.length}"

# Multiple texts (batched, more efficient)
embeddings = RubyLLM.embed(["Ruby", "Python", "JavaScript"])
puts "Vectors: #{embeddings.vectors.length}"  # => 3

# Specific model
embedding = RubyLLM.embed("text", model: 'text-embedding-3-large')

# Access metadata
puts "Model: #{embedding.model}"
puts "Input tokens: #{embedding.input_tokens}"
```

## Models

| Model | Provider | Dimensions | Input/$1M |
|-------|----------|-----------|-----------|
| text-embedding-3-small | OpenAI | 1536 | $0.02 |
| text-embedding-3-large | OpenAI | 3072 | $0.13 |
| gemini-embedding-3 | Google | 768 | $0.025 |

```ruby
# OpenAI
RubyLLM.embed("text", model: 'text-embedding-3-small')

# Google
RubyLLM.embed("text", model: 'gemini-embedding-3')
```

## Similarity Calculation

```ruby
def cosine_similarity(a, b)
  dot = a.zip(b).sum { |x, y| x * y }
  dot / (Math.sqrt(a.sum { |x| x**2 }) * Math.sqrt(b.sum { |y| y**2 }))
end

vec1 = RubyLLM.embed("cat").vectors
vec2 = RubyLLM.embed("dog").vectors
vec3 = RubyLLM.embed("car").vectors

puts cosine_similarity(vec1, vec2)  # => ~0.85 (similar concepts)
puts cosine_similarity(vec1, vec3)  # => ~0.15 (different concepts)
```

## RAG Example

```ruby
class DocumentSearch
  def initialize(documents)
    @documents = documents
    @index = build_index
  end
  
  def search(query, limit: 5)
    # 1. Embed query
    query_embedding = RubyLLM.embed(query).vectors
    
    # 2. Find similar documents
    @documents.map do |doc|
      {
        doc: doc,
        similarity: cosine_similarity(query_embedding, doc.embedding)
      }
    end.sort_by { |d| -d[:similarity] }.first(limit)
  end
  
  private
  
  def build_index
    @documents.map do |doc|
      {
        doc: doc,
        embedding: RubyLLM.embed(doc.content).vectors
      }
    end
  end
  
  def cosine_similarity(a, b)
    dot = a.zip(b).sum { |x, y| x * y }
    dot / (Math.sqrt(a.sum { |x| x**2 }) * Math.sqrt(b.sum { |y| y**2 }))
  end
end

# Usage
docs = Document.all
searcher = DocumentSearch.new(docs)
results = searcher.search("Ruby programming", limit: 3)
```

## Rails Integration

### With pgvector

```ruby
# db/migrate/create_documents.rb
class CreateDocuments < ActiveRecord::Migration[7.2]
  def change
    create_table :documents do |t|
      t.text :content
      t.vector :embedding, limit: 1536  # pgvector
    end
    
    add_index :documents, :embedding, using: :ivfflat, opclass: :vector_cosine_ops
  end
end

# app/models/document.rb
class Document < ApplicationRecord
  before_save :generate_embedding, if: :content_changed?
  
  def self.search_similar(query, limit: 5)
    query_embedding = RubyLLM.embed(query).vectors
    where("embedding <=> :embedding < 0.5", embedding: query_embedding.to_s)
      .order("embedding <=> :embedding", embedding: query_embedding)
      .limit(limit)
  end
  
  private
  
  def generate_embedding
    self.embedding = RubyLLM.embed(content).vectors
  end
end
```

## Batch Processing

```ruby
# Efficient batch embedding
texts = Document.pluck(:content)
batches = texts.each_slice(100)

batches.each do |batch|
  embeddings = RubyLLM.embed(batch)
  # Process embeddings
end
```

## Async Embeddings

```ruby
require 'async'

Async do
  documents.map do |doc|
    Async do
      doc.update(embedding: RubyLLM.embed(doc.content).vectors)
    end
  end.map(&:wait)
end
```

## See Also

- **Main RubyLLM**: [rubyllm](../SKILL.md)
- **RAG Pattern**: See [agents](../agents/SKILL.md) for workflow examples
