# experiments/pg_vector/content_index.rb

class ContentIndex < ApplicationRecord
  # e.g. an uploaded file, web page, etc
  belongs_to :owner, polymorphic: true, optional: true

  # Arguably this is a denormalized column for all but the root content_node in the tree.
  # But we set it for all nodes, for performance and query convenience.
  has_many :content_nodes, dependent: :destroy

  validates :title, presence: true, uniqueness: { scope: [:owner_id, :owner_type] }
end
