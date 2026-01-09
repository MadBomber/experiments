# frozen_string_literal: true

require 'fact_db'
# This is the FactDb client:
# facts = FactDb::Fact.new

# ContextGraph - A unified layer for querying and transforming knowledge
# from multiple data stores (FactDB, HTM) into LLM-friendly formats.
#
# Based on concepts from:
# - Context Graph Manifesto (Daniel Davis)
# - Building the Event Clock (Kirk Marple)
#
# The Context Graph Layer provides:
# 1. Self-describing schema (introspection)
# 2. Structured output formats (triples, Cypher, RDF)
# 3. Unified queries across stores
# 4. Temporal query helpers
# 5. Optional Prolog-based inference

require_relative "context_graph/version"
require_relative "context_graph/layer"
require_relative "context_graph/query_result"
require_relative "context_graph/temporal_query"
require_relative "context_graph/transformers/base"
require_relative "context_graph/transformers/triple_transformer"
require_relative "context_graph/transformers/cypher_transformer"
require_relative "context_graph/transformers/text_transformer"
require_relative "context_graph/transformers/prolog_transformer"

module ContextGraph
  class Error < StandardError; end
  class StoreNotFoundError < Error; end
  class TransformError < Error; end

  # Convenience method to create a new Layer
  def self.new(**options)
    Layer.new(**options)
  end
end
