# experiments/pg_vector/generate_context_using_content_index.rb

# This is the service class we use to perform the vector search
class GenerateContextUsingContentIndex
  def initialize(user:, content:, model:, content_index:)
    self.user = user
    self.content = content
    self.model = model
    self.content_index = content_index
  end

  def call
    find_or_create_user_query
    perform_vector_search
    generate_context
  end

  private

  def find_or_create_user_query
    self.user_query = user.user_queries.find_or_create_by!(content: content.strip.chomp)
  end

  # Uses ActiveRecord to narrow the search space, then uses the vector search
  def perform_vector_search
    scope = content_index.content_nodes.sources.small_chunks
    scope = scope.nearest_neighbors(:embedding, user_query.embedding, distance: 'inner_product')
    self.content_nodes = scope.select(:content).limit(30)
    self.vector_search_result_strings = content_nodes.map(&:content)
  end

  def generate_context
    # Creates the context string up to the max allowed length (determined by the model and internal limits)
  end

  attr_accessor :content_nodes, :content_index, :vector_search_result_strings, :user, :content, :model, :user_query
end
