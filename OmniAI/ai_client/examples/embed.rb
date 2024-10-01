#!/usr/bin/env ruby
# experiments/OmniAI/ai_client/examples/embed.rb

require_relative 'common'
require 'matrix'
require 'kmeans-clusterer'

# We'll use only one model for this example
model = 'nomic-embed-text'
client = AiClient.new(model, provider: :ollama)

# More meaningful text samples
texts = [
  "The quick brown fox jumps over the lazy dog.",
  "Machine learning is a subset of artificial intelligence.",
  "Natural language processing is crucial for chatbots.",
  "Deep learning models require large amounts of data.",
  "Quantum computing may revolutionize cryptography.",
  "Renewable energy sources include solar and wind power.",
  "Climate change is affecting global weather patterns.",
  "Sustainable agriculture practices can help protect the environment.",
  "The human genome project mapped our DNA sequence.",
  "CRISPR technology allows for precise gene editing.",
  "Artificial neural networks are inspired by biological brains.",
  "The Internet of Things connects everyday devices to the web.",
]

title "Generating Embeddings"

embeddings = client.batch_embed(texts, batch_size: 1)

debug_me{[
  :embeddings,
  'embeddings.methods.sort'
]}

# Helper function to compute cosine similarity
def cosine_similarity(a, b)
  dot_product = a.zip(b).map { |x, y| x * y }.sum
  magnitude_a = Math.sqrt(a.map { |x| x**2 }.sum)
  magnitude_b = Math.sqrt(b.map { |x| x**2 }.sum)
  dot_product / (magnitude_a * magnitude_b)
end

title "Clustering Embeddings"

# Convert embeddings to a format suitable for KMeans
data = embeddings.map(&:embedding)

debug_me{[
  'data.class',
  'data.size',
  'data.first.size'
]}

# Perform K-means clustering
k = 3  # Number of clusters
kmeans = KMeansClusterer.run(k, data, labels: texts, runs: 5)

puts "Clusters:"
kmeans.clusters.each_with_index do |cluster, i|
  puts "Cluster #{i + 1}:"
  cluster.points.each { |p| puts "  - #{p.label}" }
  puts
end

title "Finding Similar Texts"
sleep 1 # Rate Limit gets exceeded without this

query_text = "Artificial intelligence and machine learning"
query_embedding = client.embed(query_text)

debug_me{[
  :query_embedding,
  'query_embedding.methods.sort'
]}

similarities = texts.zip(embeddings).map do |text, embedding|
  similarity = cosine_similarity(query_embedding.embedding, embedding.embedding)
  [text, similarity]
end

puts "Top 3 texts similar to '#{query_text}':"
similarities.sort_by { |_, sim| -sim }.first(3).each do |text, sim|
  puts "#{text} (Similarity: #{sim.round(4)})"
end

title "Simple Classification"

# Define some categories and their representative texts
categories = {
  "Technology" => "Computers, software, and digital innovations",
  "Science" => "Scientific research, experiments, and discoveries",
  "Environment" => "Nature, ecology, and environmental issues"
}

# Generate embeddings for category descriptions
category_embeddings = client.batch_embed(categories.values, batch_size: 1)

# Classify each text
puts "Classification results:"
texts.each do |text|
  sleep 1 # DEBUG: Rate Limited
  text_embedding = client.embed(text)

  # Find the category with the highest similarity
  best_category = categories.keys.max_by do |category|
    category_index = categories.keys.index(category)
    cosine_similarity(text_embedding.embedding, category_embeddings[category_index].embedding)
  end

  puts "#{text} => #{best_category}"
end
