-- HTM Database Schema for PostgreSQL/TimescaleDB
-- Enable required extensions

CREATE EXTENSION IF NOT EXISTS pgvector;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Main nodes table
CREATE TABLE IF NOT EXISTS nodes (
  id BIGSERIAL PRIMARY KEY,
  key TEXT UNIQUE NOT NULL,
  value TEXT NOT NULL,
  type TEXT,  -- fact, context, code, preference, decision, question
  category TEXT,
  importance REAL DEFAULT 1.0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  last_accessed TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  token_count INTEGER,
  in_working_memory BOOLEAN DEFAULT FALSE,
  robot_id TEXT NOT NULL,
  embedding vector(1536)  -- OpenAI ada-002/text-embedding-3-small uses 1536 dimensions
);

-- Relationships between nodes
CREATE TABLE IF NOT EXISTS relationships (
  id BIGSERIAL PRIMARY KEY,
  from_node_id BIGINT NOT NULL REFERENCES nodes(id) ON DELETE CASCADE,
  to_node_id BIGINT NOT NULL REFERENCES nodes(id) ON DELETE CASCADE,
  relationship_type TEXT,
  strength REAL DEFAULT 1.0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(from_node_id, to_node_id, relationship_type)
);

-- Tags for flexible categorization
CREATE TABLE IF NOT EXISTS tags (
  id BIGSERIAL PRIMARY KEY,
  node_id BIGINT NOT NULL REFERENCES nodes(id) ON DELETE CASCADE,
  tag TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(node_id, tag)
);

-- Operation log for debugging and replay
CREATE TABLE IF NOT EXISTS operations_log (
  id BIGSERIAL PRIMARY KEY,
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  operation TEXT NOT NULL,  -- add, retrieve, remove, evict, recall
  node_id BIGINT REFERENCES nodes(id) ON DELETE SET NULL,
  robot_id TEXT NOT NULL,
  details JSONB  -- Flexible storage for additional metadata
);

-- Robots registry (track all robots using the system)
CREATE TABLE IF NOT EXISTS robots (
  id TEXT PRIMARY KEY,
  name TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  last_active TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  metadata JSONB  -- Store robot-specific configuration
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_nodes_created_at ON nodes(created_at);
CREATE INDEX IF NOT EXISTS idx_nodes_updated_at ON nodes(updated_at);
CREATE INDEX IF NOT EXISTS idx_nodes_last_accessed ON nodes(last_accessed);
CREATE INDEX IF NOT EXISTS idx_nodes_type ON nodes(type);
CREATE INDEX IF NOT EXISTS idx_nodes_category ON nodes(category);
CREATE INDEX IF NOT EXISTS idx_nodes_robot_id ON nodes(robot_id);
CREATE INDEX IF NOT EXISTS idx_nodes_in_working_memory ON nodes(in_working_memory);

-- Vector similarity search index (HNSW for better performance)
CREATE INDEX IF NOT EXISTS idx_nodes_embedding ON nodes
  USING hnsw (embedding vector_cosine_ops)
  WITH (m = 16, ef_construction = 64);

-- Full-text search
CREATE INDEX IF NOT EXISTS idx_nodes_value_gin ON nodes USING gin(to_tsvector('english', value));
CREATE INDEX IF NOT EXISTS idx_nodes_key_gin ON nodes USING gin(to_tsvector('english', key));

-- Trigram indexes for fuzzy matching
CREATE INDEX IF NOT EXISTS idx_nodes_value_trgm ON nodes USING gin(value gin_trgm_ops);

-- Relationship indexes
CREATE INDEX IF NOT EXISTS idx_relationships_from ON relationships(from_node_id);
CREATE INDEX IF NOT EXISTS idx_relationships_to ON relationships(to_node_id);

-- Tags indexes
CREATE INDEX IF NOT EXISTS idx_tags_node_id ON tags(node_id);
CREATE INDEX IF NOT EXISTS idx_tags_tag ON tags(tag);

-- Operation log indexes
CREATE INDEX IF NOT EXISTS idx_operations_log_timestamp ON operations_log(timestamp);
CREATE INDEX IF NOT EXISTS idx_operations_log_robot_id ON operations_log(robot_id);
CREATE INDEX IF NOT EXISTS idx_operations_log_operation ON operations_log(operation);

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_nodes_updated_at ON nodes;
CREATE TRIGGER update_nodes_updated_at
  BEFORE UPDATE ON nodes
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- View for node statistics
CREATE OR REPLACE VIEW node_stats AS
SELECT
  type,
  COUNT(*) as count,
  AVG(importance) as avg_importance,
  SUM(token_count) as total_tokens,
  MIN(created_at) as oldest,
  MAX(created_at) as newest
FROM nodes
GROUP BY type;

-- View for robot activity
CREATE OR REPLACE VIEW robot_activity AS
SELECT
  r.id,
  r.name,
  COUNT(n.id) as total_nodes,
  MAX(n.created_at) as last_node_created
FROM robots r
LEFT JOIN nodes n ON n.robot_id = r.id
GROUP BY r.id, r.name;
