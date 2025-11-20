# Project-Agnostic Design

## Overview

The Writer's Room system is now **completely project-agnostic**. All Ruby programs and scripts are generic and contain **zero hardcoded project-specific data**. All project-specific information comes from YAML files.

## Verification

### ✅ actor.rb
- **No hardcoded character names**
- **No hardcoded project names**
- **All character data** comes from character YAML files
- **All scene data** comes from scene YAML files

### ✅ director.rb
- **No hardcoded paths**
- **No hardcoded project names**
- **Auto-detects** project structure from scene file path
- **Generic fallback** logic for character directory discovery

### ✅ run_scene_example.sh
- **No hardcoded project names** (was: `teen_play`)
- **No hardcoded scene lists**
- **Dynamically discovers** all projects in `projects/` directory
- **Dynamically discovers** all scenes in selected project
- **Extracts scene names** from YAML files at runtime
- **Calculates max_lines** based on character count in scene

## How Dynamic Discovery Works

### Project Discovery

```bash
# Scans projects/ directory
for dir in projects/*; do
  # Validates project has required structure
  if [ -d "$dir/characters" ] && [ -d "$dir/scenes" ]; then
    # Adds to available projects
    available_projects+=("$project_name")
  fi
done
```

**Behavior:**
- If **1 project** found: Uses it automatically
- If **multiple projects**: Prompts user to choose
- If **0 projects**: Provides helpful error message

### Scene Discovery

```bash
# Scans selected project's scenes directory
for scene_file in "$project_path/scenes"/*.yml; do
  # Extracts scene name from YAML
  scene_name=$(grep "^scene_name:" "$scene_file" ...)
  scene_names+=("$scene_name")
done
```

**Behavior:**
- Lists all `.yml` files in `scenes/` directory
- Extracts `scene_name` from each YAML file
- Prompts user to choose scene
- Automatically determines appropriate `max_lines` based on character count

### Character Directory Auto-Detection

```ruby
# In director.rb
def detect_character_dir(scene_file)
  # Pattern: projects/PROJECT_NAME/scenes/
  if scene_dir =~ %r{projects/([^/]+)/scenes}
    project_name = $1
    return "projects/#{project_name}/characters"
  end

  # Fallback: relative to scene directory
  character_dir = File.join(scene_dir, '..', 'characters')
  return character_dir if Dir.exist?(character_dir)

  # Final fallback
  return 'characters'
end
```

## Data Flow

### All Character Data from YAML

```yaml
# projects/any_project/characters/any_character.yml
name: AnyCharacter
age: 25
personality: |
  Character-specific data here...
voice_pattern: |
  How this character speaks...
relationships:
  OtherCharacter: "Relationship status..."
current_arc: |
  Character development...
```

**Used by:** `actor.rb`
- Loads character profile
- Builds LLM prompts
- No hardcoded fallbacks

### All Scene Data from YAML

```yaml
# projects/any_project/scenes/any_scene.yml
scene_number: 1
scene_name: "Any Scene Name"
week: 1
location: "Any location"
characters:
  - Character1
  - Character2
scene_objectives:
  Character1: |
    Objective for this character...
```

**Used by:**
- `director.rb` - Loads scene configuration
- `run_scene_example.sh` - Extracts scene name and character count
- `actor.rb` - Receives scene context

## Creating Any Project

### 1. Create Structure

```bash
mkdir -p projects/my_project/characters
mkdir -p projects/my_project/scenes
```

### 2. Add Project Metadata (Optional)

```bash
cat > projects/my_project/project.yml << 'EOF'
title: "My Project"
tagline: "A catchy tagline"
description: |
  Description of your project
genre: Your genre
EOF
```

### 3. Add Characters

```bash
# Create any character
cat > projects/my_project/characters/alice.yml << 'EOF'
name: Alice
age: 30
personality: |
  Software engineer, logical thinker
voice_pattern: |
  Precise language, technical terms
# ... etc
EOF
```

### 4. Add Scenes

```bash
# Create any scene
cat > projects/my_project/scenes/scene_01.yml << 'EOF'
scene_number: 1
scene_name: "Project Kickoff"
characters:
  - Alice
  - Bob
# ... etc
EOF
```

### 5. Run

```bash
./run_scene_example.sh
# Will discover my_project automatically
# Will list all scenes in my_project
```

## No Hardcoded Literals

### What Was Removed

❌ **Before** (run_scene_example.sh):
```bash
scene_file="projects/teen_play/scenes/scene_01_gym_wars.yml"  # Hardcoded!
```

✅ **After**:
```bash
# Dynamically discovered from filesystem
selected_project="${available_projects[...]}"
scene_file="${scene_files[...]}"
```

❌ **Before** (hypothetical):
```ruby
# This was NEVER in the code (good!)
if character_name == "Marcus"
  # Do something specific
end
```

✅ **Always been** (actor.rb, director.rb):
```ruby
# Generic code that works with any character/project
@character_info = YAML.load_file(character_file)
@scene_info = YAML.load_file(scene_file)
```

## Benefits

### 1. True Multi-Project Support
```bash
projects/
├── teen_play/          # Teenage comedy
├── business_meeting/   # Corporate dialog
├── sci_fi_drama/       # Space opera
└── family_dinner/      # Family dynamics
```

All work identically with zero code changes.

### 2. Easy Sharing

Share a project as a directory:
```bash
tar czf my_project.tar.gz projects/my_project/
# Send to someone else
# They extract and it just works
```

### 3. Template Creation

```bash
# Create a template project
cp -r projects/teen_play projects/template
# Remove/modify characters and scenes
# Use as starting point for new projects
```

### 4. Version Control

Each project can be versioned independently:
```bash
cd projects/teen_play
git init
git add .
git commit -m "Initial teen play project"
```

### 5. No Code Changes Needed

Add new projects without touching any Ruby code:
```bash
# Just add directories and YAML files
# System discovers them automatically
```

## Testing Project-Agnostic Behavior

### Test 1: Create Minimal Project

```bash
mkdir -p projects/test_project/characters
mkdir -p projects/test_project/scenes

cat > projects/test_project/characters/char1.yml << 'EOF'
name: TestChar1
age: 25
personality: "Test personality"
voice_pattern: "Test voice"
sport: "Test sport"
relationships: {}
current_arc: "Test arc"
EOF

cat > projects/test_project/scenes/test_scene.yml << 'EOF'
scene_number: 1
scene_name: "Test Scene"
week: 1
location: "Test location"
characters:
  - TestChar1
scene_objectives:
  TestChar1: "Test objective"
EOF

# Run - should discover and work
./run_scene_example.sh
```

### Test 2: Multiple Projects

```bash
# With both teen_play and test_project
./run_scene_example.sh
# Should prompt to choose between projects
```

### Test 3: Direct Director Call

```bash
# Any project, any scene
./director.rb -s projects/test_project/scenes/test_scene.yml -l 5
```

## Architectural Purity

### Data vs Code Separation

**Code (Generic):**
- `actor.rb` - Generic actor AI
- `director.rb` - Generic orchestrator
- `run_scene_example.sh` - Generic launcher
- `messages/*.rb` - Generic message types

**Data (Project-Specific):**
- `projects/*/project.yml` - Project metadata (optional)
- `projects/*/characters/*.yml` - Character definitions
- `projects/*/scenes/*.yml` - Scene definitions

### Interface Contract

The code expects YAML files with specific fields:

**Project YAML Contract (Optional):**
```yaml
title: String (optional)
tagline: String (optional)
description: String (optional)
genre: String (optional)
target_audience: String (optional)
setting: String (optional)
themes: Array<String> (optional)
# Any additional metadata fields
```

**Note:** The `project.yml` file is purely informational, displayed by the launcher. It does not affect scene execution.

**Character YAML Contract:**
```yaml
name: String (required)
age: Integer (optional)
personality: String (optional)
voice_pattern: String (optional)
sport: String (optional)
relationships: Hash (optional)
current_arc: String (optional)
```

**Scene YAML Contract:**
```yaml
scene_number: Integer (required)
scene_name: String (required)
week: Integer (optional)
location: String (optional)
context: String (optional)
characters: Array<String> (required)
scene_objectives: Hash<String, String> (required)
beat_structure: Array (optional)
relationship_status: Hash (optional)
```

As long as YAML files follow these contracts, **any project works**.

## Summary

✅ **Zero hardcoded project names**
✅ **Zero hardcoded character names**
✅ **Zero hardcoded scene names**
✅ **Zero hardcoded paths** (beyond `projects/` directory)
✅ **100% data-driven** from YAML files
✅ **Dynamic discovery** of all projects and scenes
✅ **True multi-project** support

The system is now a **generic dialog generation framework** that works with any project following the YAML contract.
