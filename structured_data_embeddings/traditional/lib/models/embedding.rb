# scripts/lib/embedding.rb

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
end
