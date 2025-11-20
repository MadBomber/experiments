# Writer's Room Configuration Guide

## Default Configuration

The Writer's Room is pre-configured with the following defaults:

- **LLM Provider**: Ollama
- **Model**: gpt-oss
- **Ollama URL**: http://localhost:11434
- **Timeout**: 120 seconds (2 minutes)

## Environment Variables

All configuration can be customized using environment variables:

### LLM Provider Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `RUBY_LLM_PROVIDER` | `ollama` | LLM provider to use (ollama, openai, anthropic, etc.) |
| `RUBY_LLM_MODEL` | `gpt-oss` | Model name to use |
| `OLLAMA_URL` | `http://localhost:11434` | Ollama server URL |

### Provider-Specific API Keys

| Variable | Required For | Description |
|----------|-------------|-------------|
| `OPENAI_API_KEY` | OpenAI | API key for OpenAI models |
| `ANTHROPIC_API_KEY` | Anthropic | API key for Anthropic Claude models |

### Scene Control

| Variable | Default | Description |
|----------|---------|-------------|
| `MAX_LINES` | `50` | Maximum dialog lines before scene ends |
| `DEBUG_ME` | (unset) | Set to `1` to enable debug output |

## Configuration Examples

### Default: Ollama with gpt-oss

No configuration needed! Just ensure Ollama is running:

```bash
ollama serve
ollama pull gpt-oss
./run_scene_example.sh
```

### Use Different Ollama Model

```bash
export RUBY_LLM_MODEL="llama2"
./director.rb -s scenes/scene_01_gym_wars.yml
```

```bash
export RUBY_LLM_MODEL="mistral"
./director.rb -s scenes/scene_02_statistical_anomaly.yml
```

### Use Remote Ollama Server

```bash
export OLLAMA_URL="http://192.168.1.100:11434"
export RUBY_LLM_MODEL="llama2"
./director.rb -s scenes/scene_01_gym_wars.yml
```

### Switch to OpenAI

```bash
export RUBY_LLM_PROVIDER="openai"
export RUBY_LLM_MODEL="gpt-4"
export OPENAI_API_KEY="sk-your-key-here"
./director.rb -s scenes/scene_01_gym_wars.yml
```

### Switch to Anthropic Claude

```bash
export RUBY_LLM_PROVIDER="anthropic"
export RUBY_LLM_MODEL="claude-3-5-sonnet-20241022"
export ANTHROPIC_API_KEY="sk-ant-your-key-here"
./director.rb -s scenes/scene_01_gym_wars.yml
```

### Enable Debug Mode

```bash
export DEBUG_ME=1
./director.rb -s scenes/scene_01_gym_wars.yml
```

This will output detailed debug information from the `debug_me` gem, including:
- Character initialization details
- LLM configuration (provider, model, URL)
- Dialog generation prompts
- Message publishing/receiving
- Decision-making logic

### Longer Scenes

```bash
# Allow up to 100 dialog lines
./director.rb -s scenes/scene_08_data_dump.yml -l 100
```

### Combination Example

```bash
# Remote Ollama server with custom model and debug mode
export OLLAMA_URL="http://myserver.local:11434"
export RUBY_LLM_MODEL="mixtral"
export DEBUG_ME=1

./director.rb -s scenes/scene_01_gym_wars.yml -l 75
```

## Checking Your Configuration

### Before Running

Check that services are accessible:

```bash
# Check Redis
redis-cli ping
# Should return: PONG

# Check Ollama
curl http://localhost:11434
# Should return Ollama version info

# List available Ollama models
ollama list
# Should show gpt-oss (or your chosen model)
```

### During Execution

With `DEBUG_ME=1`, you'll see configuration details:

```
DEBUG: LLM setup complete for Marcus
  provider: "ollama"
  model: "gpt-oss"
  base_url: "http://localhost:11434"
```

### Verify Model

Test the model directly with Ollama:

```bash
ollama run gpt-oss "Test message: Hello!"
```

## Configuration Persistence

### Session-Based (Temporary)

Set environment variables in your terminal session:

```bash
export RUBY_LLM_MODEL="llama2"
# Only affects current terminal session
```

### Permanent Configuration

Add to your shell profile (`~/.bashrc`, `~/.zshrc`, etc.):

```bash
# Writer's Room Configuration
export RUBY_LLM_PROVIDER="ollama"
export RUBY_LLM_MODEL="gpt-oss"
export OLLAMA_URL="http://localhost:11434"
```

Then reload:
```bash
source ~/.bashrc  # or ~/.zshrc
```

### Project-Specific (.env file)

Create a `.env` file in the writers_room directory:

```bash
# .env
RUBY_LLM_PROVIDER=ollama
RUBY_LLM_MODEL=gpt-oss
OLLAMA_URL=http://localhost:11434
MAX_LINES=50
```

Then load it before running:
```bash
source .env
./director.rb -s scenes/scene_01_gym_wars.yml
```

**Note**: The `.env` file is in `.gitignore` to keep your configuration private.

## Performance Tuning

### Model Selection Trade-offs

| Model Type | Speed | Quality | Memory | Best For |
|------------|-------|---------|--------|----------|
| Small (7B) | Fast | Good | Low | Quick iterations, testing |
| Medium (13B) | Medium | Better | Medium | Development, short scenes |
| Large (70B+) | Slow | Best | High | Final production, long scenes |

### Recommended Models by Use Case

**Quick Testing:**
```bash
export RUBY_LLM_MODEL="tinyllama"  # Very fast, basic quality
```

**Development:**
```bash
export RUBY_LLM_MODEL="gpt-oss"    # Default, good balance
# or
export RUBY_LLM_MODEL="llama2"     # Solid performance
```

**Production:**
```bash
export RUBY_LLM_MODEL="mixtral"    # High quality
# or
export RUBY_LLM_PROVIDER="openai"
export RUBY_LLM_MODEL="gpt-4"      # Best quality (paid)
```

## Troubleshooting Configuration

### "Connection refused" errors

**Check Ollama is running:**
```bash
ps aux | grep ollama
# Should show ollama serve process

# If not running:
ollama serve
```

**Check correct URL:**
```bash
curl $OLLAMA_URL
# Should connect successfully
```

### "Model not found" errors

**List installed models:**
```bash
ollama list
```

**Install missing model:**
```bash
ollama pull gpt-oss
# or whichever model you're using
```

### "Timeout" errors

**Increase timeout in actor.rb:**

Edit `actor.rb` line 188:
```ruby
timeout: 240  # Increase to 4 minutes
```

Or use a faster model:
```bash
export RUBY_LLM_MODEL="tinyllama"
```

### Debug Configuration Issues

**Enable debug mode:**
```bash
DEBUG_ME=1 ./director.rb -s scenes/scene_01_gym_wars.yml
```

**Check actor logs:**
```bash
tail -f logs/marcus_*.log
tail -f logs/marcus_*_err.log
```

**Monitor Redis traffic:**
```bash
redis-cli monitor
```

## Advanced Configuration

### Custom RubyLLM Client Options

Edit `actor.rb` method `setup_llm` to add custom options:

```ruby
@llm = RubyLLM::Client.new(
  provider: provider,
  model: model,
  base_url: base_url,
  timeout: 120,
  # Add custom options:
  temperature: 0.7,    # Creativity level
  max_tokens: 150,     # Response length
  top_p: 0.9,         # Nucleus sampling
  # etc.
)
```

### Per-Character Model Selection

Modify `Actor#initialize` to accept model override:

```ruby
def initialize(character_info, model: nil)
  @custom_model = model
  # ... rest of initialization
end
```

Then in `setup_llm`:
```ruby
model = @custom_model || ENV['RUBY_LLM_MODEL'] || 'gpt-oss'
```

Run with different models per character:
```bash
# Would require custom launcher script
```

## Summary

**Minimal Setup (Default):**
```bash
ollama serve
ollama pull gpt-oss
redis-server
./run_scene_example.sh
```

**Production Setup:**
```bash
# In ~/.bashrc or ~/.zshrc
export RUBY_LLM_PROVIDER="ollama"
export RUBY_LLM_MODEL="mixtral"
export OLLAMA_URL="http://localhost:11434"
```

The system is designed to work out-of-the-box with Ollama and gpt-oss, but gives you full flexibility to use any LLM provider supported by RubyLLM.
