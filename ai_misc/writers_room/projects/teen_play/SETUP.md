# HTM Setup Guide

## Prerequisites

1. **Ruby** (version 3.0 or higher)
2. **TimescaleDB Cloud Account** (already set up)
3. **Database Environment Variables** (already configured)
4. **Ollama** (for embeddings via RubyLLM)

## Ollama Setup

HTM uses RubyLLM with the Ollama provider for generating embeddings. You need to install and run Ollama locally.

### 1. Install Ollama

**macOS:**
```bash
curl https://ollama.ai/install.sh | sh
```

**Or download from:** https://ollama.ai/download

### 2. Start Ollama Service

```bash
# Ollama typically starts automatically after installation
# Verify it's running:
curl http://localhost:11434/api/version
```

### 3. Pull the gpt-oss Model

```bash
# Pull the default model used by HTM
ollama pull gpt-oss

# Verify the model is available
ollama list
```

### 4. Test Embedding Generation

```bash
# Test that embeddings work
ollama run gpt-oss "Hello, world!"
```

### Optional: Custom Ollama URL

If Ollama is running on a different host/port, set the environment variable:

```bash
export OLLAMA_URL="http://custom-host:11434"
```

## Database Setup

### 1. Load Database Credentials

The HTM project uses environment variables to manage database credentials. These are defined in `~/.bashrc__tiger`.

```bash
# Load the Tiger database environment variables
source ~/.bashrc__tiger
```

To make these variables available automatically in new shell sessions, ensure `~/.bashrc__tiger` is sourced in your `~/.bashrc` or `~/.bash_profile`.

### 2. Verify Connection

Test the database connection:

```bash
cd /path/to/HTM
ruby test_connection.rb
```

You should see:
```
✓ Connected successfully!
✓ TimescaleDB Extension: Version 2.22.1
✓ pgvector Extension: Version 0.8.1
✓ pg_trgm Extension: Version 1.6
```

### 3. Enable Extensions (One-time)

Enable required PostgreSQL extensions (already done, but can be re-run safely):

```bash
ruby enable_extensions.rb
```

## Environment Variables Reference

After sourcing `~/.bashrc__tiger`, these variables are available:

| Variable | Description | Example Value |
|----------|-------------|---------------|
| `TIGER_SERVICE_NAME` | Service identifier | `db-67977` |
| `TIGER_DBNAME` | Database name | `tsdb` |
| `TIGER_DBUSER` | Database user | `tsdbadmin` |
| `TIGER_DBPASS` | Database password | `***` |
| `TIGER_DBURL` | Full connection URL (preferred) | `postgres://...` |
| `TIGER_DBPORT` | Database port | `37807` |

## Development Workflow

### Quick Start

```bash
# 1. Source environment variables (if not in .bashrc)
source ~/.bashrc__tiger

# 2. Install dependencies (when gem is created)
bundle install

# 3. Initialize database schema (when ready)
ruby -r ./lib/htm -e "HTMDatabase.setup"

# 4. Test HTM functionality (when implemented)
ruby examples/basic_usage.rb
```

### Testing

HTM uses Minitest for testing:

```bash
# Run all tests
rake test

# Or run directly with Ruby
ruby test/htm_test.rb

# Run specific test file
ruby test/embedding_service_test.rb

# Run integration tests (requires database)
ruby test/integration_test.rb
```

## Project Structure

```
HTM/
├── lib/
│   ├── htm.rb                    # Main HTM class
│   ├── htm/
│   │   ├── database.rb           # Database setup and schema
│   │   ├── long_term_memory.rb   # PostgreSQL-backed storage
│   │   ├── working_memory.rb     # In-memory active context
│   │   ├── embedding_service.rb  # RubyLLM embedding generation (Ollama/gpt-oss)
│   │   └── version.rb            # Version constant
├── sql/
│   └── schema.sql                # Database schema
├── test/
│   ├── test_helper.rb            # Minitest configuration
│   ├── htm_test.rb               # Basic HTM tests
│   ├── embedding_service_test.rb # Embedding tests (RubyLLM/Ollama)
│   └── integration_test.rb       # Full integration tests
├── examples/
│   └── basic_usage.rb            # Basic usage example
├── test_connection.rb            # Verify database connection
├── enable_extensions.rb          # Enable PostgreSQL extensions
├── SETUP.md                      # This file
├── README.md                     # Project overview
├── htm_teamwork.md               # Planning and design doc
├── Gemfile
├── htm.gemspec
└── Rakefile                      # Rake tasks
```

## Next Steps

1. **Phase 1**: Create basic gem structure
2. **Phase 2**: Implement database schema
3. **Phase 3**: Implement LongTermMemory class
4. **Phase 4**: Implement WorkingMemory class
5. **Phase 5**: Implement HTM main class
6. **Phase 6**: Add tests
7. **Phase 7**: Create examples

See `htm_teamwork.md` for detailed roadmap.

## Troubleshooting

### Ollama Issues

If you encounter embedding errors:

```bash
# Verify Ollama is running
curl http://localhost:11434/api/version

# Check if gpt-oss model is available
ollama list | grep gpt-oss

# Test embedding generation
ollama run gpt-oss "Test embedding"

# View Ollama logs
ollama logs

# Restart Ollama service
# On macOS, Ollama runs as a background service
# Check Activity Monitor or restart from the menu bar
```

**Common Ollama Errors:**

- **"connection refused"**: Ollama service is not running. Start Ollama from Applications or via CLI.
- **"model not found"**: Run `ollama pull gpt-oss` to download the model.
- **Custom URL not working**: Ensure `OLLAMA_URL` environment variable is set correctly.

### Database Connection Issues

If you get connection errors:

```bash
# Verify environment variables are set
echo $TIGER_DBURL

# Test connection manually
psql $TIGER_DBURL

# Check if ~/.bashrc__tiger is sourced
grep "bashrc__tiger" ~/.bashrc
```

### Extension Issues

If extensions aren't available:

```bash
# Re-run extension setup
ruby enable_extensions.rb

# Check extension status manually
psql $TIGER_DBURL -c "SELECT extname, extversion FROM pg_extension ORDER BY extname"
```

### SSL Issues

The TimescaleDB Cloud instance requires SSL. If you see SSL errors:

```bash
# Ensure sslmode is set in connection URL
echo $TIGER_DBURL | grep sslmode
# Should show: sslmode=require
```

## Resources

- **Ollama**: https://ollama.ai/
- **RubyLLM**: https://github.com/madbomber/ruby_llm
- **TimescaleDB Docs**: https://docs.timescale.com/
- **pgvector Docs**: https://github.com/pgvector/pgvector
- **Planning Document**: `htm_teamwork.md`
- **PostgreSQL Docs**: https://www.postgresql.org/docs/

## Support

For issues or questions:
1. Check `htm_teamwork.md` for design decisions
2. Review examples in `examples/` directory
3. Run tests with `rake test` (Minitest framework)
4. Check Ollama status for embedding issues
