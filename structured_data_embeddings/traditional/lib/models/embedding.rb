# scripts/lib/embedding.rb
require 'json'
require 'open3'

class Embedding < ActiveRecord::Base
  # CAUTION: The hardcoded dimensions is based upon
  #           the use of the nomic-embed-text model
  #           if any other embedding model is used
  #           the dimensions will likely change.
  #           This 768 magic number is also tied to
  #           the SQL file that creates the table.

  has_neighbors :values, dimensions: 768
  
  validates :content, presence: true
  validates :data,    presence: true
  validates :values,  presence: true

  def self.find_nearest_from_file(file_path, number_of_results = 3)
    content = process_file(file_path)
    vector  = vectorize(content)

    find_nearest(vector, number_of_results)
  end

  # def content
  #   super.to_s
  # end
  #
  # def data
  #   super.to_s
  # end

  private

  def self.process_file(file_path)
    pathname = Pathname.new(file_path)
    if pathname.extname.downcase == '.json'
      gron_output, status = Open3.capture2('gron', pathname.to_s)
      raise "Failed to process JSON file with gron" unless status.success?
      gron_output
    else
      File.read(pathname)
    end
  end

  def self.vectorize(content)
    # Assuming you're using the MyClient class to interact with the embedding model
    client = MyClient.new('nomic-embed-text')
    result = client.embed(content)
    result.data['data'].first['embedding']
  end

  def self.find_nearest(vector, number_of_results)
    # Using the has_neighbors functionality to find the nearest embeddings
    nearest = Embedding.nearest_neighbors(:values, vector, distance: "euclidean").first(number_of_results)

    # nearest.map do |result|
    #   embedding = result.first
    #   distance = result.last || calculate_cosine_distance(vector, embedding.values)
    #   { embedding: embedding, distance: distance }
    # end
  end

  def self.calculate_cosine_distance(v1, v2)
    dot_product = v1.zip(v2).map { |a, b| a * b }.sum
    magnitude1 = Math.sqrt(v1.map { |x| x**2 }.sum)
    magnitude2 = Math.sqrt(v2.map { |x| x**2 }.sum)
    1 - (dot_product / (magnitude1 * magnitude2))
  end
end
