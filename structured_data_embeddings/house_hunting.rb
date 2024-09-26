#!/usr/bin/env ruby
# experiments/structured_data_embeddings/house_hunting.rb

require 'json'
require 'date'
require 'rumale/nearest_neighbors/k_neighbors_classifier'
require 'rumale/clustering/k_means'
require 'numo/narray'
require 'find'

# Convert structured data into a vector for processing
def structured_data_to_vector(a_hash)
  vector = []
  text_data = []

  a_hash.keys.sort.each do |key| # Sort keys
    value = a_hash[key]
    case value
    when Numeric
      vector << value.to_f
    when TrueClass, FalseClass
      vector << (value ? 1.0 : 0.0)
    when String
      text_data << value
    when Date, Time
      vector << value.to_time.to_f
    when Hash
      vector.concat(structured_data_to_vector(value)) # Recursive call for nested Hash
    when Array
      value.each { |item| vector.concat(structured_data_to_vector(item)) } # Recursive call for Array    
    else
      vector << 0.0 # Default for unsupported types
    end
  end

  # Convert text data to embeddings (simple example)
  unless text_data.empty?
    text_data.each { |text| vector << text.length.to_f }
  end

  vector
end

# Load JSON files from a directory recursively
def load_json_files(directory)
  json_files = []
  Find.find(directory) do |path|
    json_files << path if path.end_with?('.json')
  end
  
  json_files.flat_map do |file_path|
    puts "Loading #{file_path} ..."
    JSON.parse(File.read(file_path))
  end
end

# Train K-means model
def train_kmeans_model(vectors, k: 3)
  Rumale::Clustering::KMeans.new(n_clusters: k).fit(vectors)
end

# Find the most similar objects using KNN
def find_similar_objects(knn, new_vector)
  # Get the indices of the nearest neighbors
  similar_indices = knn.predict(new_vector)
  similar_indices
end

# Main execution
if ARGV.length != 2
  puts "Usage: #{$0} <query_json_file_path> <json_files_directory>"
  exit 1
end

query_file_path, json_files_directory = ARGV
query_data = JSON.parse(File.read(query_file_path))

# Load and process JSON files from the specified directory
data_entries = load_json_files(json_files_directory)

# Convert loaded data entries to vectors
vectors = data_entries.map { |entry| structured_data_to_vector(entry) }

# Train K-means model
kmeans = train_kmeans_model(vectors)

# Convert user-provided values to a vector
user_vector = structured_data_to_vector(query_data)

# Initialize the KNeighborsClassifier
knn = Rumale::NearestNeighbors::KNeighborsClassifier.new(n_neighbors: 3)
knn.fit(vectors, (0...vectors.size).to_a) # Fit with the vector data and corresponding labels (indices)

# Find similar objects using KNN
similar_indices = find_similar_objects(knn, [user_vector])

# Convert the Numo::Int32 to an array to facilitate further operations or display
similar_indices_array = similar_indices.to_a

puts "Most similar object indices: #{similar_indices_array.join(', ')}"
