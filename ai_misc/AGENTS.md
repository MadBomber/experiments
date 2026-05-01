# AGENTS.md - AI Agent Guide for experiments/ai_misc

**Last Updated:** January 13, 2026  
**Ruby Version:** 4.0.0  
**Platform:** macOS (darwin, arm64)

## Repository Overview

This is **Dewayne VanHoozer's** experimental AI/ML repository containing Ruby-based AI experiments, tools, and frameworks. This is a **playground for AI/LLM experimentation**, not a production codebase. Expect:

- Multiple independent projects and experiments
- Standalone scripts alongside gem-structured projects
- Heavy use of cutting-edge AI Ruby gems
- SQLite and Redis infrastructure
- MCP (Model Context Protocol) implementations
- Agentic frameworks and RAG systems

**Key Philosophy:** This is an exploration space. Code quality varies intentionally. Some projects are polished gems, others are quick experiments. Respect the experimental nature.

---

## Project Structure

### Core Categories

1. **Gem Projects** (structured with gemspec, Rakefile, tests)
   - `bayesian_inference/` - Bayesian time series prediction

2. **Standalone Scripts** (root-level `.rb` files)
   - AI assistants, embedders, RAG implementations, client wrappers
   - `assistant.rb`, `disco.rb`, `embedder.rb`, `ima.rb`, `rag.rb`
   - `ollama_client.rb`, `openai_vector_store.rb`, `qroq_ai.rb`, `xai.rb`
   - `robots_talking_to_themselves.rb`, `subreddits.rb`, `topic_context.rb`
   - `using_onnx_models.rb`, `rate_limiter.rb`

3. **MCP Servers** (`mcp_server/`, `mcp_client/`)
   - Model Context Protocol implementations
   - Knowledge servers, fast-mcp examples

4. **Creative Projects**
   - `writers_room/` - Multi-character AI dialog system
   - `blog/` - MonkeysPaw-based blog framework

5. **Coding Agents**
   - `coding_agent_with_ruby_llm/` - Coding agent implementation

6. **Documentation**
   - `mcp_spec/` - MCP protocol documentation
   - Project-specific READMEs in subdirectories

---

## Essential Commands

### Gem Projects (bayesian_inference)

```bash
# Navigate to gem project
cd bayesian_inference/

# Install dependencies
bundle install

# Run tests (Minitest)
rake test
# or
ruby test/<test_file>_test.rb

# Run examples
ruby examples/<example_file>.rb
```

### Standalone Scripts

```bash
# Most standalone scripts are executable
chmod +x script_name.rb
./script_name.rb

# Or run directly
ruby script_name.rb

# Common patterns
ruby assistant.rb          # AI assistant (requires external dependencies)
ruby embedder.rb [exp]     # Fast CPU embeddings (2000/s with ONNX)
ruby disco.rb              # Social conversation mining with RAG
ruby ima.rb                # Agentic framework
ruby rag.rb                # RAG implementation
ruby ollama_client.rb      # Ollama API client
ruby xai.rb                # xAI integration
```

### Writer's Room (Multi-Character Dialog)

```bash
cd writers_room/

# Quick start
./run_scene_example.sh

# Start Redis (required)
redis-server
# or
brew services start redis

# Run a scene with director
./director.rb -s projects/teen_play/scenes/scene_01_gym_wars.yml

# Verify setup
redis-cli ping             # Should return PONG
curl http://localhost:11434  # Verify Ollama
```

### MonkeysPaw Blog Framework

```bash
cd blog/

# Start the server
./xyzzy.rb

# MonkeysPaw uses Sinatra on port 4567
# Access at http://localhost:4567
```

---

## Development Environment

### Required Infrastructure

1. **Redis** (for writers_room, SmartMessage-based systems)
   ```bash
   brew services start redis
   redis-cli ping
   ```

2. **Ollama** (default LLM provider for many projects)
   ```bash
   ollama serve
   ollama pull gpt-oss      # Default model
   ollama list              # Check installed models
   ```

### Environment Variables

```bash
# LLM Providers
export OPENAI_API_KEY="..."
export ANTHROPIC_API_KEY="..."
export OLLAMA_URL="http://localhost:11434"
export XAI_API_KEY="..."

# Ruby LLM Configuration
export RUBY_LLM_PROVIDER="ollama"        # Default
export RUBY_LLM_MODEL="gpt-oss"          # Default model

# Debug mode
export DEBUG_ME=1                        # Enable debug_me gem output
```

### Key Ruby Gems Used

**AI/LLM Frameworks:**
- `ruby_llm` - Multi-provider LLM interface (OpenAI, Anthropic, Ollama)
- `omniai-*` - Generalized AI service framework
- `langchainrb` - Ruby LangChain implementation
- `ima` - Agentic framework
- `sublayer` - Model-agnostic GenerativeAI DSL

**MCP (Model Context Protocol):**
- `fast-mcp` - Ruby MCP implementation
- `actionmcp` - Rails MCP tooling
- `mcp-rb` - Lightweight MCP framework
- `ruby-mcp-client` - MCP client library

**Vector/Embedding:**
- `sqlite-vec` - Vector search for SQLite
- `faiss` - Similarity search
- `clip-rb` - CLIP embeddings via ONNX

**Database:**
- `sqlite3` - SQLite
- `redis` - Redis client

**Testing:**
- `minitest` - Testing framework (used in gem projects)
- `rspec-llama` - AI model testing

**Utilities:**
- `debug_me` - Debug helper (print labeled variable values)
- `tiktoken_ruby` - Token counting
- `monkeyspaw` - Prompt-driven web framework

---

## Code Patterns & Conventions

### File Organization

**Gem Structure (bayesian_inference):**
```
project_name/
├── Gemfile
├── Gemfile.lock
├── Rakefile
├── README.md
├── project_name.gemspec
├── lib/
│   ├── project_name.rb          # Main entry point
│   └── project_name/
│       ├── version.rb
│       └── <components>.rb
├── test/
│   ├── test_helper.rb
│   └── *_test.rb
└── examples/
    └── *.rb
```

**Standalone Scripts:**
- Shebang: `#!/usr/bin/env ruby`
- Encoding declaration: `# encoding: utf-8`
- Source comment with URL references
- Often use `require_relative` for local dependencies
- May require external `lib/` files from parent directories

### Naming Conventions

- **Files:** `snake_case.rb`
- **Classes:** `PascalCase` (e.g., `BayesianInference::Predictor`)
- **Methods:** `snake_case` with `?` for predicates, `!` for mutators
- **Constants:** `UPPER_SNAKE_CASE`
- **Modules:** `PascalCase` (e.g., `BayesianInference`)

### Common Patterns

**Debug Output:**
```ruby
require 'debug_me'
include DebugMe

debug_me { [:variable_name, :another_var] }
```

**LLM Configuration (RubyLLM):**
```ruby
require 'ruby_llm'

RubyLLM.configure do |config|
  config.openai_api_key = ENV['OPENAI_API_KEY']
  # Defaults to Ollama with gpt-oss if no provider specified
end

chat = RubyLLM.chat
chat.with_tools(*tool_classes)
response = chat.ask("prompt")
```

**Vector Storage (sqlite-vec):**
```ruby
require 'sqlite3'
require 'sqlite_vec'

db = SQLite3::Database.new("data.sqlite")
db.enable_load_extension(true)
SqliteVec.load(db)
db.enable_load_extension(false)

db.execute <<-SQL
  CREATE VIRTUAL TABLE vec_table USING vec0(
    id INTEGER PRIMARY KEY,
    embedding FLOAT[384]
  );
SQL
```

**Redis/SmartMessage (writers_room):**
```ruby
require 'smart_message'

# Messages inherit from SmartMessage::Base
class DialogMessage < SmartMessage::Base
  attributes :character, :line, :timestamp
end

# Publish
DialogMessage.publish(character: "Marcus", line: "...")

# Subscribe
DialogMessage.subscribe do |msg|
  puts "#{msg.character}: #{msg.line}"
end
```

---

## Testing

### Test Framework: Minitest

Gem projects use Minitest (not RSpec).

**Run tests:**
```bash
rake test                           # All tests
ruby test/specific_test.rb          # Single test file
```

**Test Structure:**
```ruby
require_relative 'test_helper'

class ComponentTest < Minitest::Test
  def setup
    # Test setup
  end

  def test_something
    assert_equal expected, actual
  end

  def test_another_thing
    assert_raises(SomeError) { dangerous_method }
  end
end
```

**Test Helpers:**
- Located in `test/test_helper.rb`
- Typically requires `minitest/autorun`
- May set up test databases or mock objects

---

## Project-Specific Notes

### bayesian_inference (Time Series Predictor)

**Purpose:** Bayesian inference for discrete outcome prediction from time series.

**Key Components:**
- `BayesianInference::Prior` - P(outcome)
- `BayesianInference::Likelihood` - P(data|outcome) via KDE
- `BayesianInference::Posterior` - P(outcome|data)
- `BayesianInference::TimeSeriesPredictor` - Main API

**Usage:**
```ruby
require 'bayesian_inference'

predictor = BayesianInference.predictor(
  outcomes: [-2, -1, 0, 1, 2],
  bandwidth: 1.0
)

predictor.train([1.0, 2.0, 3.0], outcome: 1)
posterior = predictor.predict([1.0, 2.0, 3.0])

puts posterior.max_outcome    # MAP estimate
puts posterior.confidence
```

### writers_room (Multi-Character Dialog)

**Purpose:** AI-powered theatrical dialog generation with independent actor processes.

**Architecture:**
- **Director** (`director.rb`) - Orchestrates actors, produces transcripts
- **Actors** (`actor.rb`) - Independent processes, one per character
- **SmartMessage** - Redis pub/sub for inter-process communication
- **RubyLLM** - Ollama/gpt-oss for dialog generation

**Dependencies:**
- Redis (mandatory)
- Ollama with gpt-oss model (default)
- Character YAML files (`characters/*.yml`)
- Scene YAML files (`scenes/*.yml`)

**Project Structure:**
- Supports multiple projects under `projects/`
- Current: `projects/teen_play/` (6 characters, 8 scenes)

**Message Types:**
- `DialogMessage` - Character dialog lines
- `SceneControlMessage` - Scene start/stop/pause
- `StageDirectionMessage` - Actions, beats
- `MetaMessage` - System communication

**Configuration:**
```bash
# Default: Ollama/gpt-oss
export RUBY_LLM_PROVIDER="ollama"
export RUBY_LLM_MODEL="gpt-oss"

# Override for different provider
export RUBY_LLM_PROVIDER="openai"
export OPENAI_API_KEY="..."
```

### MCP Servers

**Purpose:** Model Context Protocol server implementations.

**Projects:**
- `mcp_server/fast_mcp_server.rb` - Example server with resources/tools
- `mcp_server/knowledge_server/` - Knowledge retrieval server
- `mcp_server/sinatra_fastmcp_server.rb` - Sinatra-based MCP server

**Key Patterns:**
```ruby
require 'fast_mcp'

server = FastMcp::Server.new(name: 'server-name', version: '1.0.0')

# Define resources
class MyResource < FastMcp::Resource
  uri 'resource-uri'
  resource_name 'DisplayName'
  description 'Resource description'
  
  def content
    # Return content (string or JSON)
  end
end

# Define tools
class MyTool < FastMcp::Tool
  description 'Tool description'
  
  def call
    # Tool logic
    { result: "value" }
  end
end

server.register_resources(MyResource)
server.register_tools(MyTool)
```

### Standalone Scripts

**assistant.rb** - Unix-style AI filter for code/text processing
- Uses Mistral AI
- Processes stdin or files
- Fixes code bugs, spelling errors
- Preserves style and conventions

**disco.rb** - Social conversation mining with RAG
- Mines millions of Reddit conversations
- Multi-audience analysis
- RAG over SQLite with vec0
- Parallel processing

**embedder.rb** - Fast CPU embeddings
- ONNX-based (no GPU required)
- ~2000 embeddings/second on CPU
- Uses sentence-transformers/static-retrieval-mrl-en-v1
- Requires cloned HuggingFace model directory

**ima.rb** - Agentic framework
- Task-based system
- Tool integration
- Based on @ahoward's ima gem

**rag.rb** - RAG implementation
- SQLite + sqlite-vec
- Chunks, facets, embeddings
- Semantic search

**ollama_client.rb** - Ollama API client wrapper
- Direct Ollama API integration
- Model management and inference

**xai.rb** - xAI (X.AI/Grok) integration
- API client for xAI models
- LLM integration

---

## Common Gotchas

### Redis

**writers_room:**
- Redis must be running before starting actors
- Default: `localhost:6379`
- SmartMessage requires Redis for pub/sub
- Check with: `redis-cli ping`

### Ollama

**Default LLM Provider:**
- Many projects default to Ollama with gpt-oss
- Must be running: `ollama serve`
- Pull models first: `ollama pull gpt-oss`
- Override with `RUBY_LLM_PROVIDER` and provider API key

### RubyLLM Configuration

**Provider Selection:**
- Defaults to Ollama if no provider specified
- Environment variables override config
- Each project may configure differently
- Check project README for specifics

### File Dependencies

**Standalone Scripts:**
- May require files from `../lib/` (parent directory)
- May expect specific directory structures
- Check `require_relative` statements
- Some scripts expect `~/lib/ruby` directory

### SQLite + vec0

**Vector Storage:**
- Must enable extensions before loading SqliteVec
- Extension must be disabled after loading
- Virtual tables use `vec0` type

---

## Useful References

### External Documentation

- **MCP Specification:** `mcp_spec/mcp.md`
- **Project Configs:** `writers_room/CONFIGURATION.md`

### Gists & External Sources

Many scripts reference GitHub gists by @ahoward:
- `assistant.rb`: https://gist.github.com/ahoward/6c9dce583ab3607307c18e5b3b539254
- `disco.rb`: https://gist.github.com/ahoward/abc555bf1a8e01dea8b83a10d791e8d5
- `embedder.rb`: https://gist.github.com/ahoward/2a1d45499ac9e755d802dbcbaf401b71
- `rag.rb`: https://gist.github.com/ahoward/3726b9339a62fbc82b1cd62bd0c1668f

### Key Blog Posts

- **Coding Agent in Ruby:** https://radanskoric.com/articles/coding-agent-in-ruby
- **Fastest Embeddings:** https://drawohara.io/nerd/fastest-possible-embeddings/

---

## Working with This Codebase

### As an AI Agent

**DO:**
- Respect the experimental nature - not all code is production-ready
- Check project-specific READMEs before making changes
- Run tests after modifications (when they exist)
- Preserve existing patterns within each project
- Use `debug_me` for debugging when enabled
- Check environment variable requirements

**DON'T:**
- Assume all projects follow the same structure
- Apply production standards to experimental scripts
- Break existing tests without fixing them
- Change core patterns without understanding context
- Assume database connections work without verification

### Testing Changes

```bash
# Gem projects
cd <project>/
bundle install
rake test

# Standalone scripts
ruby script.rb
# Check output manually
```

### Adding New Experiments

**Standalone Script:**
```bash
# Create in root with shebang and encoding
#!/usr/bin/env ruby
# encoding: utf-8
# experiments/ai_misc/my_experiment.rb

# Add source reference if applicable
# See: https://...

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'debug_me'
  gem 'ruby_llm'
end

# Your code here
```

**New Gem Project:**
```bash
# Create directory structure
mkdir -p my_project/{lib/my_project,test,examples}

# Create gemspec, Gemfile, Rakefile
# Follow patterns from bayesian_inference/

# Add README.md with:
# - Purpose
# - Setup instructions
# - Usage examples
# - Dependencies
```

---

## Environment Setup Checklist

Before working on this codebase, ensure:

- [ ] Ruby 4.0.0+ installed
- [ ] Bundler installed (`gem install bundler`)
- [ ] Redis (if working on writers_room)
- [ ] Ollama installed and running (`ollama serve`)
- [ ] gpt-oss model pulled (`ollama pull gpt-oss`)
- [ ] Environment variables set (see above)
- [ ] API keys for LLM providers (if needed)

**Quick Verification:**
```bash
ruby --version              # 4.0.0+
bundle --version
redis-cli ping              # If using Redis projects
ollama list                 # Should show gpt-oss
env | grep -E 'OPENAI|ANTHROPIC|RUBY_LLM|XAI'
```

---

## Common Workflows

### Working on bayesian_inference

```bash
cd bayesian_inference/
bundle install
rake test
ruby examples/basic_usage.rb
```

### Working on writers_room

```bash
cd writers_room/
brew services start redis
redis-cli ping                   # Verify Redis
ollama serve &                   # Start Ollama
ollama pull gpt-oss             # Ensure model available
./run_scene_example.sh          # Quick test
./director.rb -s projects/teen_play/scenes/scene_01_gym_wars.yml
```

### Working on MCP Servers

```bash
cd mcp_server/knowledge_server/
bundle install
ruby server.rb                   # Start server on port 3000

# Test with curl
curl http://localhost:3000/...
```

### Running Standalone Experiments

```bash
# embedder requires HuggingFace model
git clone https://huggingface.co/sentence-transformers/static-retrieval-mrl-en-v1
ruby embedder.rb 14              # 2^14 embeddings

# disco requires data setup
ruby disco.rb < input.txt

# assistant as filter
echo "def foo() end" | ruby assistant.rb

# ollama client
ruby ollama_client.rb

# xAI integration
ruby xai.rb
```

---

## Key Insights from Dewayne's Code

### Style Preferences

- **Debug-friendly:** Heavy use of `debug_me` gem
- **Gist-driven:** Many experiments based on GitHub gists
- **Documentation:** Good README files for gem projects
- **External dependencies:** Comfortable with Redis, Ollama
- **AI-forward:** Embraces latest AI Ruby gems, MCP protocol
- **Experimental:** Not afraid to try cutting-edge approaches

### Technical Patterns

- **Database:** SQLite for experiments and vector storage
- **Testing:** Minitest for gem projects
- **LLM Access:** RubyLLM for multi-provider abstraction
- **Embeddings:** ONNX for fast CPU embeddings
- **Vector Search:** sqlite-vec for lightweight implementations

### Project Organization

- **Gem structure:** When serious (bayesian_inference)
- **Standalone scripts:** For quick experiments and filters
- **External lib/:** Sometimes references `~/lib/ruby` for shared code
- **Nested projects:** `writers_room/projects/teen_play/` pattern

---

## Summary

This repository is a **rich experimental playground** for AI/LLM work in Ruby. Key takeaways:

1. **Multiple paradigms:** Gem projects, standalone scripts, creative experiments
2. **Infrastructure-light:** Redis and Ollama for most projects
3. **Cutting-edge AI:** Embraces MCP, RAG, agentic frameworks
4. **Well-documented:** Good READMEs, detailed setup instructions
5. **Experimental:** Not production code, embrace the chaos

**For AI agents working here:**
- Read project READMEs first
- Verify infrastructure (Redis, Ollama) before running
- Respect the experimental nature - suggest improvements, don't enforce production standards
- Run tests when they exist
- Preserve existing patterns within each project

**Quick start for most projects:**
```bash
cd <project>/
bundle install          # If Gemfile exists
rake test              # If Rakefile exists
ruby examples/*.rb     # If examples exist
```

**When stuck:**
- Check README.md in project directory
- Verify environment variables
- Ensure Redis/Ollama running (if needed)
- Look for referenced gists or blog posts in source comments

---

## Contact & Attribution

**Author:** Dewayne VanHoozer (GitHub: @madbomber)  
**Repository:** experiments/ai_misc  
**Purpose:** AI/LLM experimentation and learning

**Credits:** Many experiments inspired by or directly from:
- Ara Howard (@ahoward) - ima, assistant, disco, embedder, rag
- Radan Skorić (@radanskoric) - Coding agent patterns

**Note:** This AGENTS.md reflects the state of the repository as of January 13, 2026. Projects like HTM, fact_db, and cg_gem have graduated to their own standalone gem repositories.
