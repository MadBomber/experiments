# experiments/pg_vector/content_node.rb

class ContentNode < ApplicationRecord
  include HasAncestry

  # Describes the level of abstraction
  NODE_TYPES = [
    'document',
    # Big Chunk: Used to generate summaries. Parents of regular chunks
    'big_chunk',
    # Chunk: Used to generate embeddings. Children of Big Chunks
    'small_chunk',
    # A meta node you could set overtly (e.g. from a book) or generate
    'table_of_contents'
  ]

  # Describes the purpose and type of content of the node
  CONTENT_TYPES = [
    # Container: for structure only, have no content themselves, but have descendants that do
    'container',
    # Source: has actual original source content
    'source',
    # Summaries have generated summaries from 'source'
    'summary_short',
    'summary_medium',
    'summary_long'
  ]
  # Provides all the tree functionality
  has_ancestry
  has_neighbors :embedding

  # Arguably this is a denormalized column for all but the root content_node in the tree.
  # But we set it for all nodes, for performance and query convenience
  belongs_to :content_index, counter_cache: true, touch: true

  scope :documents, -> { where(node_type: 'document') }
  scope :big_chunks, -> { where(node_type: 'big_chunk') }
  scope :small_chunks, -> { where(node_type: 'small_chunk') }
  scope :table_of_contents, -> { where(node_type: 'table_of_contents') }
  
  scope :sources, -> { where(content_type: 'source') }
  scope :summaries, -> { where(content_type: ['summary_short', 'summary_medium', 'summary_long']) }

  validates :content, presence: true, if: :source_or_summary?
  validates :node_type, inclusion: { in: NODE_TYPES }
  validates :content_type, inclusion: { in: CONTENT_TYPES }

  attribute :metadata, :jsonb, default: {}
  attribute :should_create_embedding, :boolean, default: true
  attribute :create_embedding_in_process, :boolean, default: false

  after_commit :create_embedding, on: :create, if: :source_or_summary?

  def source_or_summary?
    source? || summary?
  end

  def summary?
    content_type.start_with?('summary')
  end

  def source?
    content_type == 'source'
  end

  private

  def create_embedding
    return unless should_create_embedding?
    if create_embedding_in_process?
      CreateEmbeddingJob.perform_now(signed_gid:to_sgid.to_s)
    else
      CreateEmbeddingJob.perform_later(signed_gid:to_sgid.to_s)
    end
  end
end
