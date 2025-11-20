# HTM - Hierarchical Temporary Memory

Intelligent memory management for LLM-based applications (robots). HTM implements a two-tier memory system with durable long-term storage and token-limited working memory, enabling robots to recall context from past conversations using RAG (Retrieval-Augmented Generation).

## Features

- **Two-Tier Memory Architecture**
  - Working Memory: Token-limited active context for immediate LLM use
  - Long-term Memory: Durable PostgreSQL/TimescaleDB storage

- **Never Forgets (Unless Told)**
  - All memories persist in long-term storage
  - Only explicit `forget()` commands delete data
  - Working memory evicts to long-term, never deletes

- **RAG-Based Retrieval**
  - Vector similarity search (pgvector with RubyLLM/Ollama embeddings)
  - Full-text search (PostgreSQL)
  - Hybrid search (combines both)
  - Temporal filtering ("last week", date ranges)
  - Default: Ollama with gpt-oss model via RubyLLM

- **Hive Mind**
  - All robots share global memory
  - Cross-robot context awareness
  - Track which robot said what

- **Knowledge Graph**
  - Relationship tracking between nodes
  - Tag-based categorization
  - Importance scoring

- **Time-Series Optimized**
  - TimescaleDB hypertables
  - Automatic compression for old data
  - Fast time-range queries

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'htm'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install htm
```

## Setup

### 1. Database Configuration

HTM uses TimescaleDB (PostgreSQL with time-series extensions). Set up your database connection via environment variables:

```bash
# Source the Tiger database configuration
source ~/.bashrc__tiger

# This loads TIGER_DBURL and other connection parameters
```

### 2. Initialize Database Schema

```ruby
require 'htm'

# Run once to set up database schema
HTM::Database.setup
```

Or from command line:

```bash
ruby -r ./lib/htm -e "HTM::Database.setup"
```

### 3. Verify Setup

```bash
ruby test_connection.rb
```

See [SETUP.md](SETUP.md) for detailed setup instructions.

## Usage

### Basic Example

```ruby
require 'htm'

# Initialize HTM for your robot
# By default, uses RubyLLM with Ollama provider and gpt-oss model for embeddings
htm = HTM.new(
  robot_name: "Code Helper",
  working_memory_size: 128_000,    # tokens
  embedding_service: :ollama,      # RubyLLM with Ollama (default)
  embedding_model: 'gpt-oss'       # gpt-oss model (default)
)

# Add memories (embeddings generated automatically via Ollama)
htm.add_node(
  "decision_001",
  "We decided to use PostgreSQL for HTM storage",
  type: :decision,
  category: "architecture",
  importance: 9.0,
  tags: ["database", "architecture"]
)

# Recall from the past
memories = htm.recall(
  timeframe: "last week",
  topic: "database decisions"
)

# Create context for LLM
context = htm.create_context(strategy: :balanced)

# Forget (explicit deletion only)
htm.forget("old_decision", confirm: :confirmed)
```

### Memory Types

HTM supports different memory types:

- `:fact` - Immutable facts ("User's name is Dewayne")
- `:context` - Conversation state
- `:code` - Code snippets and patterns
- `:preference` - User preferences
- `:decision` - Architectural/design decisions
- `:question` - Unresolved questions

### Embedding Configuration

HTM uses RubyLLM for embedding generation. By default, it uses the Ollama provider with the gpt-oss model:

```ruby
# Default: Ollama with gpt-oss
htm = HTM.new(robot_name: "My Robot")

# Explicit Ollama configuration
htm = HTM.new(
  robot_name: "My Robot",
  embedding_service: :ollama,
  embedding_model: 'gpt-oss'
)

# Use different Ollama model
htm = HTM.new(
  robot_name: "My Robot",
  embedding_service: :ollama,
  embedding_model: 'llama2'
)

# Use OpenAI (requires implementation)
htm = HTM.new(
  robot_name: "My Robot",
  embedding_service: :openai
)
```

**Ollama Setup:**
```bash
# Install Ollama
curl https://ollama.ai/install.sh | sh

# Pull gpt-oss model
ollama pull gpt-oss

# Verify Ollama is running
curl http://localhost:11434/api/version
```

### Recall Strategies

```ruby
# Vector similarity search (semantic) - uses Ollama embeddings
htm.recall(timeframe: "last week", topic: "HTM", strategy: :vector)

# Full-text search (keyword matching) - PostgreSQL full-text search
htm.recall(timeframe: "last month", topic: "database", strategy: :fulltext)

# Hybrid (combines both) - best of both worlds
htm.recall(timeframe: "yesterday", topic: "testing", strategy: :hybrid)
```

### Context Assembly

```ruby
# Recent memories first
context = htm.create_context(strategy: :recent)

# Most important memories
context = htm.create_context(strategy: :important)

# Balanced (importance × recency)
context = htm.create_context(strategy: :balanced)

# With token limit
context = htm.create_context(strategy: :balanced, max_tokens: 50_000)
```

### Hive Mind Queries

```ruby
# Which robot discussed a topic?
breakdown = htm.which_robot_said("PostgreSQL")
# => { "robot-123" => 15, "robot-456" => 8 }

# Get conversation timeline
timeline = htm.conversation_timeline("HTM design", limit: 50)
# => [{ timestamp: ..., robot: "...", content: "...", type: :decision }, ...]
```

### Memory Statistics

```ruby
stats = htm.memory_stats
# => {
#   total_nodes: 1234,
#   nodes_by_robot: { "robot-1" => 800, "robot-2" => 434 },
#   working_memory: { current_tokens: 45000, max_tokens: 128000, utilization: 35.16 },
#   database_size: 52428800,  # bytes
#   ...
# }
```

## Development

After checking out the repo, run:

```bash
# Install dependencies
bundle install

# Run tests
rake test

# Run example
ruby examples/basic_usage.rb
```

## Testing

HTM uses Minitest:

```bash
# Run all tests
rake test

# Run specific test file
ruby test/htm_test.rb
```

## Architecture

See [htm_teamwork.md](htm_teamwork.md) for detailed design documentation and planning notes.

### Key Components

- **HTM**: Main API, coordinates all components
- **WorkingMemory**: In-memory, token-limited active context
- **LongTermMemory**: PostgreSQL-backed permanent storage
- **EmbeddingService**: Vector embedding generation via RubyLLM (Ollama/gpt-oss)
- **Database**: Schema setup and management

### Database Schema

- `nodes`: Main memory storage with vector embeddings
- `relationships`: Knowledge graph connections
- `tags`: Flexible categorization
- `operations_log`: Audit trail (hypertable)
- `robots`: Robot registry

## Roadmap

- [x] Phase 1: Foundation (basic two-tier memory)
- [ ] Phase 2: RAG retrieval (semantic search)
- [ ] Phase 3: Relationships & tags
- [ ] Phase 4: Working memory management
- [ ] Phase 5: Hive mind features
- [ ] Phase 6: Operations & observability
- [ ] Phase 7: Advanced features
- [ ] Phase 8: Production-ready gem

See [htm_teamwork.md](htm_teamwork.md) for the complete roadmap.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/madbomber/htm.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Credits

Developed by Dewayne VanHoozer with brainstorming assistance from Claude (Anthropic).

See [htm_teamwork.md](htm_teamwork.md) for the complete development journey and design decisions.
