# Project Structure Guide

## Overview

The Writer's Room now supports a **project-based organization** allowing multiple independent dialog projects to coexist.

## Directory Layout

```
writers_room/
├── actor.rb                    # Core actor AI (shared)
├── director.rb                 # Scene orchestrator (shared)
├── run_scene_example.sh        # Quick launcher (uses teen_play)
├── messages/                   # SmartMessage types (shared)
│   ├── dialog_message.rb
│   ├── scene_control_message.rb
│   ├── stage_direction_message.rb
│   └── meta_message.rb
├── projects/                   # PROJECT-BASED ORGANIZATION
│   ├── teen_play/              # Example project
│   │   ├── project.yml         # Project metadata (optional)
│   │   ├── characters/
│   │   │   ├── marcus.yml
│   │   │   ├── jamie.yml
│   │   │   └── ...
│   │   └── scenes/
│   │       ├── scene_01_gym_wars.yml
│   │       └── ...
│   └── your_project/           # Your custom project
│       ├── project.yml         # Project metadata (optional)
│       ├── characters/
│       └── scenes/
└── logs/                       # Actor logs (auto-created)
```

## Project Metadata (Optional)

Each project can include a `project.yml` file with metadata about the project:

```yaml
# projects/my_project/project.yml
title: "My Project Title"
tagline: "A catchy tagline for your project"
description: |
  A detailed description of your project, its themes,
  and what it's about.
genre: Comedy  # or Drama, Thriller, etc.
target_audience: Teenagers and young adults
setting: Where your story takes place
themes:
  - Theme 1
  - Theme 2
```

When present, the launcher (`run_scene_example.sh`) will display the project title, tagline, and description when the project is selected. This is purely informational and does not affect the execution of scenes.

## Auto-Detection

The director **automatically detects** the character directory from the scene file path:

```bash
# Scene path: projects/teen_play/scenes/scene_01.yml
# Auto-detects: projects/teen_play/characters/

./director.rb -s projects/teen_play/scenes/scene_01_gym_wars.yml
# Characters loaded from: projects/teen_play/characters/
```

## Creating a New Project

### 1. Create Project Directory Structure

```bash
mkdir -p projects/my_project/characters
mkdir -p projects/my_project/scenes
```

### 2. Add Project Metadata (Optional)

Create a `project.yml` file with your project information:

```yaml
# projects/my_project/project.yml
title: "My Awesome Dialog"
tagline: "A story about..."
description: |
  Full description of your project
```

### 3. Add Character Definitions

Create YAML files in `projects/my_project/characters/`:

```yaml
# projects/my_project/characters/alice.yml
name: Alice
age: 25
personality: |
  Your character description...
voice_pattern: |
  How this character speaks...
# ... etc
```

### 4. Create Scene Definitions

Create YAML files in `projects/my_project/scenes/`:

```yaml
# projects/my_project/scenes/scene_01.yml
scene_number: 1
scene_name: "Opening Scene"
characters:
  - Alice
  - Bob
# ... etc
```

### 5. Run Your Project

```bash
./director.rb -s projects/my_project/scenes/scene_01.yml
```

The director will automatically find characters in `projects/my_project/characters/`.

## Path Resolution Logic

The director uses this logic to find characters:

1. **Explicit override**: If `-c` flag provided, use that path
2. **Project pattern**: If scene matches `projects/PROJECT_NAME/scenes/`, use `projects/PROJECT_NAME/characters/`
3. **Relative lookup**: Check for `../characters/` relative to scene directory
4. **Fallback**: Use `characters/` in current directory

## Running Commands

### Using Auto-Detection (Recommended)

```bash
./director.rb -s projects/teen_play/scenes/scene_01_gym_wars.yml
```

### Specifying Character Directory Manually

```bash
./director.rb -s projects/my_project/scenes/scene_01.yml -c projects/my_project/characters
```

### Running Individual Actors

```bash
./actor.rb \
  -c projects/my_project/characters/alice.yml \
  -s projects/my_project/scenes/scene_01.yml
```

## Example Projects

### Teen Play (Included)

```
projects/teen_play/
├── project.yml          # Project metadata
├── characters/          # 6 teen characters
│   ├── marcus.yml
│   ├── jamie.yml
│   ├── tyler.yml
│   ├── alex.yml
│   ├── benny.yml
│   └── zoe.yml
└── scenes/              # 4 complete scenes
    ├── scene_01_gym_wars.yml
    ├── scene_02_statistical_anomaly.yml
    ├── scene_04_equipment_room.yml
    └── scene_08_data_dump.yml
```

### Your Custom Project

```
projects/your_project/
├── characters/
│   ├── character1.yml
│   └── character2.yml
└── scenes/
    └── scene_01.yml
```

## Benefits of Project Structure

✅ **Multiple Projects**: Run different dialog projects independently
✅ **Clean Organization**: Each project is self-contained
✅ **Easy Sharing**: Share individual projects as directories
✅ **Auto-Detection**: No need to specify character paths
✅ **Flexible**: Can still use custom paths with `-c` flag

## Migration from Flat Structure

If you have an older setup with flat `characters/` and `scenes/` directories:

```bash
# Old structure:
writers_room/characters/*.yml
writers_room/scenes/*.yml

# Migrate to:
mkdir -p projects/my_project
mv characters projects/my_project/
mv scenes projects/my_project/

# Update your commands:
# OLD: ./director.rb -s scenes/scene_01.yml
# NEW: ./director.rb -s projects/my_project/scenes/scene_01.yml
```

## Tips

- **One project at a time**: Each scene run uses one project
- **Share characters**: Copy character YAMLs between projects
- **Version control**: Each project can have its own git repo
- **Templates**: Use `teen_play` as a template for new projects

---

**Need help?** See `README.md` for full documentation.
