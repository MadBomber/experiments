# experiments/pg_vector/user_query.rb

# A separate model with embeddings, used for vector searches
class UserQuery < ApplicationRecord
  has_neighbors :embedding

  belongs_to :user

  after_create :create_embedding

  private

  def create_embedding
    CreateEmbeddingJob.perform_now(signed_gid:to_sgid.to_s)
    # reload the model so the embedding is available for the current process
    reload
  end
end
