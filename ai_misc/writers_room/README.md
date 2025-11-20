# Writer's Room - AI-Powered Multi-Character Dialog System

An experimental Ruby-based system for generating multi-character dialog using independent AI agents. Each character is an autonomous actor process that uses LLMs to generate dialog while maintaining consistent personality and voice.

## Overview

The Writer's Room is designed to experiment with AI-driven theatrical dialog. It features:

- **6 Distinct Characters**: Marcus, Jamie, Tyler, Alex, Benny, and Zoe from a comedic teen play
- **8 Detailed Scenes**: Complete scene breakdowns with objectives, beats, and relationship progressions
- **Independent Actor Processes**: Each character runs as a separate Ruby process
- **Redis-Based Communication**: Actors communicate via SmartMessage over Redis pub/sub
- **LLM-Powered Dialog**: Uses RubyLLM with Ollama (gpt-oss model) by default
- **Director Orchestration**: Manages multiple actors and produces transcripts
- **Flexible Configuration**: Easy switching between Ollama, OpenAI, Anthropic, or other providers

## Project Structure

```
writers_room/
├── actor.rb                    # Actor class (executable)
├── director.rb                 # Director orchestration script (executable)
├── run_scene_example.sh        # Quick start launcher (executable)
├── messages/                   # SmartMessage subclasses
│   ├── dialog_message.rb
│   ├── scene_control_message.rb
│   ├── stage_direction_message.rb
│   └── meta_message.rb
├── projects/                   # Project-based organization
│   └── teen_play/              # Teen comedy play project
│       ├── project.yml         # Project metadata (title, tagline, description)
│       ├── characters/         # Character YAML definitions
│       │   ├── marcus.yml
│       │   ├── jamie.yml
│       │   ├── tyler.yml
│       │   ├── alex.yml
│       │   ├── benny.yml
│       │   └── zoe.yml
│       └── scenes/             # Scene YAML definitions
│           ├── scene_01_gym_wars.yml
│           ├── scene_02_statistical_anomaly.yml
│           ├── scene_04_equipment_room.yml
│           └── scene_08_data_dump.yml
└── logs/                       # Actor process logs (created automatically)
```

**Note**: The project structure allows multiple independent projects. Character directories are auto-detected from scene file paths.

## Requirements

### System Requirements
- Ruby 3.0+
- Redis server running locally or accessible
- MacStudio M2max (or similar)

### Ruby Gems
```bash
gem install debug_me
gem install ruby_llm
gem install smart_message
gem install redis
```

## Setup

### 1. Start Redis Server

Ensure Redis is running:
```bash
redis-server
```

Or if using Homebrew:
```bash
brew services start redis
```

### 2. Configure LLM Provider

**Default Configuration: Ollama with gpt-oss model**

The system is pre-configured to use Ollama with the `gpt-oss` model. Ensure Ollama is running:

```bash
# Start Ollama
ollama serve

# Pull the gpt-oss model if you haven't already
ollama pull gpt-oss
```

**Using Different Providers (Optional)**

You can override the default Ollama configuration with environment variables:

```bash
# Use a different Ollama model
export RUBY_LLM_MODEL="llama2"

# Use Ollama on a different host
export OLLAMA_URL="http://192.168.1.100:11434"

# Switch to OpenAI
export RUBY_LLM_PROVIDER="openai"
export OPENAI_API_KEY="your-key-here"

# Switch to Anthropic
export RUBY_LLM_PROVIDER="anthropic"
export ANTHROPIC_API_KEY="your-key-here"
```

### 3. Verify Setup

Test that Redis is accessible:
```bash
redis-cli ping
# Should return: PONG
```

Test that Ollama is accessible:
```bash
curl http://localhost:11434
# Should return Ollama version info

ollama list | grep gpt-oss
# Should show the gpt-oss model
```

### 4. Configuration Reference

For detailed configuration options, see **[CONFIGURATION.md](CONFIGURATION.md)**

Quick reference:
- Default provider: Ollama with gpt-oss model
- Switch models: `export RUBY_LLM_MODEL="llama2"`
- Switch providers: `export RUBY_LLM_PROVIDER="openai"`
- Debug mode: `export DEBUG_ME=1`

## Usage

### Running a Scene

The simplest way to run a scene is using the director:

```bash
./director.rb -s projects/teen_play/scenes/scene_01_gym_wars.yml
```

This will:
1. Load the scene configuration
2. Auto-detect the character directory (`projects/teen_play/characters/`)
3. Start actor processes for all characters in the scene
4. Monitor and display their dialog in real-time
5. Save a transcript when complete

### Director Options

```bash
./director.rb [options]

Options:
  -s, --scene FILE         Scene YAML file (required)
  -c, --characters DIR     Character directory (auto-detected if not specified)
  -o, --output FILE        Transcript output file
  -l, --max-lines N        Maximum lines before ending (default: 50)
  -h, --help              Show help
```

### Examples

**Run Scene 1 with default settings:**
```bash
./director.rb -s projects/teen_play/scenes/scene_01_gym_wars.yml
```

**Run Scene 2 with custom transcript name:**
```bash
./director.rb -s projects/teen_play/scenes/scene_02_statistical_anomaly.yml -o scene2_take1.txt
```

**Run Scene 4 with more lines:**
```bash
./director.rb -s projects/teen_play/scenes/scene_04_equipment_room.yml -l 100
```

### Running Individual Actors

You can also run actors manually for testing:

```bash
./actor.rb -c projects/teen_play/characters/marcus.yml -s projects/teen_play/scenes/scene_01_gym_wars.yml
```

In a separate terminal, run another actor:
```bash
./actor.rb -c projects/teen_play/characters/jamie.yml -s projects/teen_play/scenes/scene_01_gym_wars.yml
```

They will automatically begin conversing via Redis.

## Character Definitions

Each character is defined in a YAML file with the following structure:

```yaml
name: Marcus
age: 16
personality: |
  Description of character traits and behaviors...

voice_pattern: |
  How the character speaks, example phrases...

sport: Basketball team statistician

relationships:
  Jamie: "Current relationship status..."
  Tyler: "Current relationship status..."
  # ... other characters

current_arc: |
  Where the character is in their development...
```

See `projects/teen_play/characters/` directory for complete examples.

## Scene Definitions

Scenes are defined in YAML with detailed structure:

```yaml
scene_number: 1
scene_name: "The Gym Wars"
week: 1
location: "School gymnasium"

context: |
  Detailed scene setup and situation...

characters:
  - Marcus
  - Jamie
  - Tyler
  - Alex
  - Benny
  - Zoe

scene_objectives:
  Marcus: |
    What Marcus wants to achieve in this scene...
  Jamie: |
    What Jamie wants to achieve in this scene...
  # ... objectives for all characters

beat_structure:
  - beat: "The Standoff"
    duration: "2 minutes"
    description: "What happens in this beat..."

  - beat: "The Negotiators"
    duration: "3 minutes"
    description: "What happens in this beat..."

relationship_status:
  Marcus_Jamie: "Strangers → Intrigued"
  Tyler_Alex: "Rivals → Respectful competitors"
```

See `projects/teen_play/scenes/` directory for complete examples.

## How It Works

### Architecture

```
┌─────────────────────────────────────────────────────────┐
│                      DIRECTOR                           │
│  - Spawns actor processes                               │
│  - Monitors dialog via Redis                            │
│  - Saves transcripts                                    │
└─────────────────┬───────────────────────────────────────┘
                  │
         ┌────────┴────────┐
         │                 │
    Redis Pub/Sub      Redis Pub/Sub
         │                 │
    ┌────┴────┐       ┌────┴────┐
    │ Actor   │       │ Actor   │
    │ Process │←─────→│ Process │
    │ (Marcus)│       │ (Jamie) │
    └─────────┘       └─────────┘
         │                 │
    RubyLLM           RubyLLM
         │                 │
    LLM Provider      LLM Provider
```

### Message Flow

1. **Director** sends `SceneControlMessage` to start scene
2. **Actors** subscribe to `writers_room:dialog` channel
3. **Actor** generates dialog using character info + scene context + conversation history
4. **Actor** publishes `DialogMessage` to Redis
5. **Other Actors** receive message, decide whether to respond
6. **Actor** generates response if appropriate
7. **Director** monitors all messages and records transcript

### Dialog Generation

Each actor uses a two-part prompt system:

**System Prompt:**
- Character profile (personality, voice pattern, age, sport)
- Current character arc
- Relationship statuses
- Scene context and objectives
- Instructions for staying in character

**User Prompt:**
- Recent conversation history (last 10 exchanges)
- Additional context (if responding to specific dialog)
- Prompt: "What does [Character] say?"

The LLM generates a response, which is cleaned and published as dialog.

### Response Decision Logic

Actors decide whether to respond based on:
1. **Direct address**: Name mentioned in dialog
2. **Conversation flow**: Not spoken recently, appropriate turn
3. **Random interjection**: 10% chance to interject
4. **Character-specific logic**: Can be customized per character

## SmartMessage Integration

The system uses SmartMessage subclasses for type-safe Redis communication:

### DialogMessage
```ruby
DialogMessage.new(
  from: "Marcus",
  content: "There's a 73% chance this will work!",
  scene: 1,
  timestamp: Time.now.to_i,
  emotion: "excited",        # optional
  addressing: "Jamie"        # optional
)
```

### SceneControlMessage
```ruby
SceneControlMessage.start_scene(1)
SceneControlMessage.stop_scene(1)
SceneControlMessage.end_scene(1)
```

### StageDirectionMessage
```ruby
StageDirectionMessage.new(
  character: "Marcus",
  action: "pulls out tablet nervously",
  scene: 1,
  timestamp: Time.now.to_i
)
```

## Output

### Transcript Format

```
SCENE 1: The Gym Wars
Location: Riverside High gymnasium
Week: 1

------------------------------------------------------------

Tyler: We're here until 6:30.
Alex: So are we. Guess we're roommates.
Marcus: According to the scheduling system, there's been an error...
Jamie: Let me see that code. Oh, I see the bug!
Benny: Can we just settle this with rock-paper-scissors?
Zoe: As Shakespeare once said... actually, this is more West Side Story!

[continues...]
```

### Statistics Output

```
============================================================
SCENE STATISTICS
============================================================
Total lines: 47

Lines by character:
  Marcus: 12
  Jamie: 11
  Tyler: 9
  Alex: 8
  Benny: 4
  Zoe: 3
============================================================
```

## Debugging

### Enable Debug Output

The system uses the `debug_me` gem. To see debug output:

```bash
DEBUG_ME=1 ./director.rb -s projects/teen_play/scenes/scene_01_gym_wars.yml
```

### Actor Logs

Individual actor logs are saved in the `logs/` directory:
- `logs/marcus_[timestamp].log` - Standard output
- `logs/marcus_[timestamp]_err.log` - Error output

### Monitor Redis

Watch Redis traffic in real-time:
```bash
redis-cli monitor
```

Or subscribe to the dialog channel:
```bash
redis-cli
> SUBSCRIBE writers_room:dialog
```

## Customization

### Adding New Characters

1. Create a new YAML file in `projects/teen_play/characters/` (or your own project):
```yaml
name: NewCharacter
age: 16
personality: |
  Character description...
voice_pattern: |
  How they speak...
# ... etc
```

2. Add to scene's character list
3. Run the scene

### Adding New Scenes

1. Create scene YAML in `projects/teen_play/scenes/` (or your own project):
```yaml
scene_number: 9
scene_name: "New Scene"
characters:
  - Character1
  - Character2
scene_objectives:
  Character1: |
    Objective...
# ... etc
```

2. Run with director:
```bash
./director.rb -s projects/teen_play/scenes/scene_09_new_scene.yml
```

The director will auto-detect the character directory from the scene path.

### Customizing LLM Behavior

Edit the prompt building methods in `actor.rb`:
- `build_system_prompt` - Character definition and instructions
- `build_user_prompt` - Conversation context

### Adjusting Response Logic

Modify `should_respond?` method in `actor.rb` to change when actors speak.

## The Play: Character Arcs

The complete play spans 8 scenes over 16 weeks:

### Three Couples

**Marcus & Jamie** - "The Analysts"
- Arc: From "love is logical" → "love is beyond logic"
- Connection: Intellectual equals who make each other braver

**Tyler & Alex** - "The Captains"
- Arc: From rivals → teammates in life
- Connection: Competitive but supportive, bring out vulnerability

**Benny & Zoe** - "The Performers"
- Arc: From hiding behind personas → authentic selves
- Connection: See through each other's acts, permission to be real

### Timeline

- **Week 1** (Scene 1): Everyone meets
- **Week 2** (Scene 2): Marcus/Jamie bond over algorithm
- **Week 4** (Scene 3): Tyler/Alex forced to work together
- **Week 6** (Scene 4): Benny/Zoe breakthrough in equipment room
- **Week 8** (Scene 5): Group chat catastrophe, all feelings revealed
- **Week 10** (Scene 6): Track meet, relationships solidify
- **Week 14** (Scene 7): Championship games, Tyler/Alex first kiss
- **Week 16** (Scene 8): Algorithm revealed wrong, love wins

See the detailed planning documents for complete scene breakdowns, character maps, and relationship timelines.

## Troubleshooting

### Redis Connection Issues
```bash
# Check Redis is running
redis-cli ping

# Check Redis logs
tail -f /usr/local/var/log/redis.log
```

### Actor Process Issues
```bash
# Check running actor processes
ps aux | grep actor.rb

# Kill hung processes
pkill -f actor.rb
```

### LLM API Issues
- Verify API keys are set correctly
- Check rate limits on your LLM provider
- Review actor logs in `logs/` directory

## Performance Tips

1. **Limit dialog exchanges** with `-l` flag to prevent runaway conversations
2. **Use faster models** for experimentation (e.g., GPT-3.5, Claude Haiku)
3. **Run fewer actors** initially to test scene dynamics
4. **Monitor Redis memory** with `redis-cli info memory`

## Future Enhancements

Potential areas for expansion:

- [ ] Stage direction generation
- [ ] Emotion detection and tracking
- [ ] Dynamic scene beat progression
- [ ] Multi-scene continuity
- [ ] Voice synthesis integration
- [ ] Visual character representation
- [ ] Real-time web interface
- [ ] Character memory/learning across scenes
- [ ] Playwright format export

## License

Experimental project for educational purposes.

## Credits

Created for exploring multi-agent AI dialog generation using Ruby, RubyLLM, and SmartMessage.

---

**Happy Writing!** 🎭
