# Writer's Room - Quick Start Guide

## What You Have

A complete AI-powered multi-character dialog system with:

### ✅ Core System
- `actor.rb` - Independent AI actor process (executable)
- `director.rb` - Orchestration and transcript management (executable)
- `run_scene_example.sh` - Easy scene launcher (executable)

### ✅ Characters (6 fully defined)
- Marcus "Stats" Chen - The analytical math whiz
- Jamie Patel - The logical robotics president
- Tyler Rodriguez - The sensitive soccer captain
- Alex Washington - The intense basketball captain
- Benny Morrison - The insecure class clown
- Zoe Kim - The theatrical drama kid

### ✅ Scenes (4 ready to run)
1. **The Gym Wars** - All 6 characters meet (Week 1)
2. **Statistical Anomaly** - Marcus, Jamie, Benny in library (Week 2)
3. **Equipment Room Incident** - Benny & Zoe breakthrough (Week 6)
4. **The Data Dump** - All 6, finale scene (Week 16)

### ✅ Infrastructure
- SmartMessage classes for Redis communication
- Character YAML templates
- Scene YAML templates
- Comprehensive documentation

## Getting Started in 3 Steps

### Step 1: Install Dependencies

```bash
# Install required gems
gem install debug_me ruby_llm smart_message redis

# Start Redis (choose one)
brew services start redis
# OR
redis-server
```

### Step 2: Start Ollama (Default LLM Provider)

The system uses **Ollama with gpt-oss model** by default:

```bash
# Start Ollama server
ollama serve

# Pull the gpt-oss model (if not already installed)
ollama pull gpt-oss
```

**Optional: Use different provider**
```bash
# Use different Ollama model
export RUBY_LLM_MODEL="llama2"

# Or switch to OpenAI/Anthropic
export RUBY_LLM_PROVIDER="openai"
export OPENAI_API_KEY="your-key-here"
```

### Step 3: Run a Scene

**Option A: Use the quick-start script (recommended)**
```bash
./run_scene_example.sh
```

**Option B: Run director directly**
```bash
./director.rb -s scenes/scene_01_gym_wars.yml
```

That's it! Watch the AI characters converse in real-time.

## What Happens When You Run

1. Director loads scene and character definitions
2. Spawns independent actor processes for each character
3. Actors connect to Redis and subscribe to dialog channel
4. Characters begin conversing based on:
   - Their personality and voice patterns
   - Scene objectives
   - Conversation context
   - Relationship dynamics
5. Director monitors and displays dialog
6. When complete, saves transcript with statistics

## Example Output

```
============================================================
SCENE 1: The Gym Wars
Location: Riverside High gymnasium
Characters: Marcus, Jamie, Tyler, Alex, Benny, Zoe
============================================================

[SCENE BEGINS]

Tyler: We're here until 6:30.
Alex: So are we. Guess we're roommates.
Marcus: According to the scheduling system, there's been a double-booking error. The probability of this happening is approximately 2.3%.
Jamie: Let me see that code. Oh, I found the bug! Your conditional logic is inverted.
Benny: Or we could just arm wrestle for it. I volunteer as tribute.
Zoe: As West Side Story taught us, when two rival gangs meet, only musical theatre can save us!
Tyler [laughing]: Okay, okay. How about we share the gym? Half court each?
Alex: Fair enough. But we make it interesting.

[continues...]
```

## File Structure Created

```
writers_room/
├── actor.rb                          # ✅ Core actor AI
├── director.rb                       # ✅ Scene orchestrator
├── run_scene_example.sh             # ✅ Quick launcher
├── README.md                         # ✅ Full documentation
├── QUICKSTART.md                    # ✅ This file
├── .gitignore                       # ✅ Git ignore rules
│
├── characters/                      # ✅ 6 characters defined
│   ├── marcus.yml
│   ├── jamie.yml
│   ├── tyler.yml
│   ├── alex.yml
│   ├── benny.yml
│   └── zoe.yml
│
├── scenes/                          # ✅ 4 scenes ready
│   ├── scene_01_gym_wars.yml
│   ├── scene_02_statistical_anomaly.yml
│   ├── scene_04_equipment_room.yml
│   └── scene_08_data_dump.yml
│
└── messages/                        # ✅ SmartMessage types
    ├── dialog_message.rb
    ├── scene_control_message.rb
    ├── stage_direction_message.rb
    └── meta_message.rb
```

## Tips for First Run

1. **Start small**: Try Scene 2 first (only 3 characters)
2. **Limit lines**: Use `-l 20` flag to keep it short initially
3. **Watch the logs**: Check `logs/` directory if actors misbehave
4. **Monitor Redis**: Run `redis-cli monitor` in another terminal
5. **Interrupt anytime**: Ctrl+C saves transcript and stops gracefully

## Common Commands

**Run specific scene:**
```bash
./director.rb -s scenes/scene_04_equipment_room.yml
```

**Limit to 20 lines:**
```bash
./director.rb -s scenes/scene_01_gym_wars.yml -l 20
```

**Custom transcript name:**
```bash
./director.rb -s scenes/scene_02_statistical_anomaly.yml -o my_test.txt
```

**Run single actor manually (testing):**
```bash
./actor.rb -c characters/marcus.yml -s scenes/scene_01_gym_wars.yml
```

**Enable debug output:**
```bash
DEBUG_ME=1 ./director.rb -s scenes/scene_01_gym_wars.yml
```

## Next Steps

Once you've run a scene successfully:

1. **Experiment with scenes** - Try all 4 included scenes
2. **Adjust line limits** - See how longer conversations develop
3. **Create new characters** - Use existing YAMLs as templates
4. **Design new scenes** - Build your own scene configurations
5. **Customize prompts** - Edit `actor.rb` to tune dialog generation
6. **Try different LLMs** - Compare results across models

## Understanding the Architecture

```
┌─────────────────────────────────────────┐
│          DIRECTOR PROCESS               │
│  • Spawns actors                        │
│  • Monitors Redis dialog channel        │
│  • Records transcript                   │
└──────────────┬──────────────────────────┘
               │
        ┌──────┴────────┐
        │               │
   Redis Pub/Sub   Redis Pub/Sub
        │               │
    ┌───┴───┐       ┌───┴───┐
    │MARCUS │←─────→│ JAMIE │
    │Actor  │       │ Actor │
    └───┬───┘       └───┬───┘
        │               │
     RubyLLM         RubyLLM
        │               │
    LLM API         LLM API
```

Each actor:
1. Receives character profile and scene info
2. Subscribes to Redis dialog channel
3. Generates dialog using LLM based on:
   - Character personality and voice
   - Scene objectives
   - Recent conversation history
   - Relationship context
4. Decides when to speak (turn-taking logic)
5. Publishes dialog to Redis
6. Other actors receive and react

## Troubleshooting

**"Redis connection refused"**
```bash
# Start Redis first
brew services start redis
# OR
redis-server
```

**"No output from actors"**
- Check LLM API key is set
- View actor logs in `logs/` directory
- Try `DEBUG_ME=1` for verbose output

**"Actors talking over each other"**
- This is normal! Adjust `should_respond?` logic in `actor.rb`
- Lower the random interjection probability

**"Scene runs forever"**
- Set `-l` flag to limit lines
- Press Ctrl+C to stop and save transcript

## Support

- Full documentation: `README.md`
- Character reference: `characters/*.yml`
- Scene reference: `scenes/*.yml`
- Source code: `actor.rb`, `director.rb`

## Have Fun! 🎭

You now have a complete AI theater company ready to perform. Experiment, iterate, and enjoy watching your characters come to life!
