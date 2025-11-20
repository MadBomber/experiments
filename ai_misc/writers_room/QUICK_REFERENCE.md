# Writer's Room - Quick Reference Card

## 🚀 Quick Start (3 Commands)

```bash
ollama serve                              # 1. Start Ollama
ollama pull gpt-oss                       # 2. Get model
./run_scene_example.sh                    # 3. Run scene
```

## 📋 Default Configuration

| Setting | Value |
|---------|-------|
| Provider | Ollama |
| Model | gpt-oss |
| URL | http://localhost:11434 |
| Timeout | 120 seconds |

## 🔧 Common Commands

### Run Scenes
```bash
./run_scene_example.sh                                    # Interactive chooser
./director.rb -s scenes/scene_01_gym_wars.yml            # Scene 1
./director.rb -s scenes/scene_02_statistical_anomaly.yml # Scene 2
./director.rb -s scenes/scene_04_equipment_room.yml      # Scene 4
./director.rb -s scenes/scene_08_data_dump.yml           # Scene 8
```

### Control Scene Length
```bash
./director.rb -s scenes/scene_01_gym_wars.yml -l 20  # Short (20 lines)
./director.rb -s scenes/scene_01_gym_wars.yml -l 50  # Medium (50 lines)
./director.rb -s scenes/scene_01_gym_wars.yml -l 100 # Long (100 lines)
```

### Debug Mode
```bash
DEBUG_ME=1 ./director.rb -s scenes/scene_01_gym_wars.yml
```

## 🔄 Switch Models

### Different Ollama Model
```bash
export RUBY_LLM_MODEL="llama2"
./director.rb -s scenes/scene_01_gym_wars.yml
```

### OpenAI
```bash
export RUBY_LLM_PROVIDER="openai"
export RUBY_LLM_MODEL="gpt-4"
export OPENAI_API_KEY="sk-..."
./director.rb -s scenes/scene_01_gym_wars.yml
```

### Anthropic Claude
```bash
export RUBY_LLM_PROVIDER="anthropic"
export RUBY_LLM_MODEL="claude-3-5-sonnet-20241022"
export ANTHROPIC_API_KEY="sk-ant-..."
./director.rb -s scenes/scene_01_gym_wars.yml
```

## 🧪 Test & Verify

```bash
redis-cli ping                           # Check Redis
curl http://localhost:11434              # Check Ollama
ollama list | grep gpt-oss               # Check model
```

## 📁 Project Structure

```
actor.rb          - AI actor process
director.rb       - Scene orchestrator
characters/       - 6 character definitions
scenes/           - 4 scene definitions
messages/         - SmartMessage types
logs/             - Actor output logs
```

## 🎭 Available Characters

1. **Marcus** - Math whiz, speaks in statistics
2. **Jamie** - Robotics president, logical thinker
3. **Tyler** - Soccer captain, secretly sensitive
4. **Alex** - Basketball captain, intense competitor
5. **Benny** - Class clown hiding insecurity
6. **Zoe** - Theater kid quoting movies

## 🎬 Available Scenes

| # | Name | Characters | Week | Type |
|---|------|------------|------|------|
| 1 | The Gym Wars | All 6 | 1 | First meeting |
| 2 | Statistical Anomaly | M, J, B | 2 | Library |
| 4 | Equipment Room | B, Z | 6 | Breakthrough |
| 8 | The Data Dump | All 6 | 16 | Finale |

*M=Marcus, J=Jamie, B=Benny, Z=Zoe*

## ⚙️ Environment Variables

```bash
RUBY_LLM_PROVIDER=ollama               # Provider (ollama/openai/anthropic)
RUBY_LLM_MODEL=gpt-oss                 # Model name
OLLAMA_URL=http://localhost:11434      # Ollama server
OPENAI_API_KEY=sk-...                  # OpenAI key (if used)
ANTHROPIC_API_KEY=sk-ant-...           # Anthropic key (if used)
DEBUG_ME=1                             # Debug mode
```

## 📊 Output Files

```bash
logs/marcus_[timestamp].log             # Actor stdout
logs/marcus_[timestamp]_err.log         # Actor stderr
transcript_scene_1_[timestamp].txt      # Scene transcript
```

## 🛠️ Troubleshooting

### Redis not running
```bash
brew services start redis
# OR
redis-server
```

### Ollama not running
```bash
ollama serve
```

### Model not found
```bash
ollama pull gpt-oss
```

### View actor logs
```bash
tail -f logs/*.log
```

### Clear Redis
```bash
redis-cli FLUSHALL
```

## 📚 Documentation

- `README.md` - Full documentation
- `QUICKSTART.md` - Getting started guide
- `CONFIGURATION.md` - Configuration details
- `CHANGELOG.md` - Recent changes

## 💡 Tips

- Start with Scene 2 (only 3 characters, easier to follow)
- Use `-l 20` for quick tests
- Enable `DEBUG_ME=1` if actors aren't responding
- Check `logs/` directory if something goes wrong
- Press Ctrl+C to stop and save transcript

## 🎯 Typical Workflow

```bash
# Terminal 1: Services
redis-server
ollama serve

# Terminal 2: Run scene
cd writers_room
./run_scene_example.sh

# Choose scene, watch magic happen!
# Press Ctrl+C when done
# Check transcript_*.txt for output
```

## 🔥 One-Liner Examples

```bash
# Quick test with llama2
RUBY_LLM_MODEL=llama2 ./director.rb -s scenes/scene_02_statistical_anomaly.yml -l 15

# Debug mode with custom output
DEBUG_ME=1 ./director.rb -s scenes/scene_01_gym_wars.yml -o test_run.txt

# Long scene with GPT-4
RUBY_LLM_PROVIDER=openai RUBY_LLM_MODEL=gpt-4 OPENAI_API_KEY=$OPENAI_API_KEY ./director.rb -s scenes/scene_08_data_dump.yml -l 100
```

---

**Need more help?** Check `README.md` or `CONFIGURATION.md`
