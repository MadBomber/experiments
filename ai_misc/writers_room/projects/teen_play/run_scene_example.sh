#!/bin/bash
##########################################################
###
##  File: run_scene_example.sh
##  Desc: Quick start example for running a scene
##        Dynamically discovers available projects and scenes
##
##########################################################

echo "============================================================"
echo "Writer's Room - Scene Launcher"
echo "============================================================"
echo ""

# Check if Redis is running
if ! redis-cli ping > /dev/null 2>&1; then
  echo "❌ Error: Redis is not running!"
  echo ""
  echo "Please start Redis first:"
  echo "  brew services start redis"
  echo "  OR"
  echo "  redis-server"
  echo ""
  exit 1
fi

echo "✓ Redis is running"
echo ""

# Check if Ollama is running (unless using a different provider)
if [ -z "$RUBY_LLM_PROVIDER" ] || [ "$RUBY_LLM_PROVIDER" = "ollama" ]; then
  ollama_url="${OLLAMA_URL:-http://localhost:11434}"
  if ! curl -s "$ollama_url" > /dev/null 2>&1; then
    echo "❌ Error: Ollama is not running!"
    echo ""
    echo "Please start Ollama first:"
    echo "  ollama serve"
    echo ""
    echo "And ensure gpt-oss model is installed:"
    echo "  ollama pull gpt-oss"
    echo ""
    echo "Or set a different provider:"
    echo "  export RUBY_LLM_PROVIDER=openai"
    echo "  export OPENAI_API_KEY=your-key"
    echo ""
    exit 1
  fi
  echo "✓ Ollama is running"

  # Check if gpt-oss model is available
  model="${RUBY_LLM_MODEL:-gpt-oss}"
  if ! ollama list | grep -q "$model"; then
    echo "⚠ Warning: Model '$model' not found in Ollama"
    echo ""
    echo "Pull the model with:"
    echo "  ollama pull $model"
    echo ""
    read -p "Continue anyway? (y/N): " continue_choice
    if [ "$continue_choice" != "y" ] && [ "$continue_choice" != "Y" ]; then
      exit 1
    fi
  else
    echo "✓ Model '$model' is available"
  fi
  echo ""
fi

# Create logs directory if it doesn't exist
mkdir -p logs

# Discover available projects
echo "Discovering available projects..."
echo ""

projects_dir="projects"
if [ ! -d "$projects_dir" ]; then
  echo "❌ Error: No 'projects' directory found!"
  echo ""
  echo "Please create a project structure:"
  echo "  mkdir -p projects/my_project/characters"
  echo "  mkdir -p projects/my_project/scenes"
  echo ""
  exit 1
fi

# Find all projects (directories in projects/ that have both characters/ and scenes/)
declare -a available_projects
for dir in "$projects_dir"/*; do
  if [ -d "$dir/characters" ] && [ -d "$dir/scenes" ]; then
    project_name=$(basename "$dir")
    available_projects+=("$project_name")
  fi
done

if [ ${#available_projects[@]} -eq 0 ]; then
  echo "❌ Error: No valid projects found!"
  echo ""
  echo "A valid project must have both 'characters/' and 'scenes/' directories."
  echo ""
  echo "Example structure:"
  echo "  projects/my_project/characters/"
  echo "  projects/my_project/scenes/"
  echo ""
  exit 1
fi

# Select project
if [ ${#available_projects[@]} -eq 1 ]; then
  # Only one project, use it automatically
  selected_project="${available_projects[0]}"
  echo "Using project: $selected_project"
  echo ""
else
  # Multiple projects, let user choose
  echo "Available projects:"
  for i in "${!available_projects[@]}"; do
    echo "  $((i+1))) ${available_projects[$i]}"
  done
  echo ""
  read -p "Choose a project (1-${#available_projects[@]}): " project_choice

  if [[ ! "$project_choice" =~ ^[0-9]+$ ]] || [ "$project_choice" -lt 1 ] || [ "$project_choice" -gt ${#available_projects[@]} ]; then
    echo "Invalid choice. Using first project: ${available_projects[0]}"
    selected_project="${available_projects[0]}"
  else
    selected_project="${available_projects[$((project_choice-1))]}"
  fi
  echo ""
  echo "Selected project: $selected_project"
  echo ""
fi

project_path="$projects_dir/$selected_project"

# Display project metadata if project.yml exists
if [ -f "$project_path/project.yml" ]; then
  echo "============================================================"

  # Extract title
  title=$(grep "^title:" "$project_path/project.yml" | head -1 | sed 's/title: *//; s/"//g; s/'\''//g')
  if [ -n "$title" ]; then
    echo "Project: $title"
  fi

  # Extract tagline
  tagline=$(grep "^tagline:" "$project_path/project.yml" | head -1 | sed 's/tagline: *//; s/"//g; s/'\''//g')
  if [ -n "$tagline" ]; then
    echo "$tagline"
  fi

  # Extract description (first line only for brevity)
  description=$(grep -A 5 "^description:" "$project_path/project.yml" | grep -v "^description:" | grep -v "^  *$" | head -1 | sed 's/^  //')
  if [ -n "$description" ]; then
    echo ""
    echo "$description"
  fi

  echo "============================================================"
  echo ""
fi

# Discover available scenes in the selected project
echo "Discovering scenes in $selected_project..."
echo ""

declare -a scene_files
declare -a scene_names
for scene_file in "$project_path/scenes"/*.yml; do
  if [ -f "$scene_file" ]; then
    scene_files+=("$scene_file")
    # Extract scene name from YAML file
    scene_name=$(grep "^scene_name:" "$scene_file" | head -1 | sed 's/scene_name: *//; s/"//g; s/'\''//g')
    if [ -z "$scene_name" ]; then
      scene_name=$(basename "$scene_file" .yml)
    fi
    scene_names+=("$scene_name")
  fi
done

if [ ${#scene_files[@]} -eq 0 ]; then
  echo "❌ Error: No scene files found in $project_path/scenes/"
  echo ""
  echo "Please add scene YAML files to $project_path/scenes/"
  echo ""
  exit 1
fi

# Choose scene
echo "Available scenes:"
for i in "${!scene_files[@]}"; do
  echo "  $((i+1))) ${scene_names[$i]}"
done
echo ""
read -p "Choose a scene (1-${#scene_files[@]}): " scene_choice

if [[ ! "$scene_choice" =~ ^[0-9]+$ ]] || [ "$scene_choice" -lt 1 ] || [ "$scene_choice" -gt ${#scene_files[@]} ]; then
  echo "Invalid choice. Using first scene."
  scene_index=0
else
  scene_index=$((scene_choice-1))
fi

scene_file="${scene_files[$scene_index]}"
scene_name="${scene_names[$scene_index]}"

# Determine appropriate max_lines based on scene
# Extract character count from scene file
char_count=$(grep -A 100 "^characters:" "$scene_file" | grep "^  -" | wc -l | tr -d ' ')

# Set max_lines based on number of characters
if [ "$char_count" -le 2 ]; then
  max_lines=25
elif [ "$char_count" -le 4 ]; then
  max_lines=30
else
  max_lines=40
fi

echo ""
echo "============================================================"
echo "Project: $selected_project"
echo "Scene: $scene_name"
echo "File: $scene_file"
echo "Characters: $char_count"
echo "Maximum lines: $max_lines"
echo "============================================================"
echo ""
echo "Press Ctrl+C to stop the scene and save transcript"
echo ""
sleep 2

# Run the director
./director.rb -s "$scene_file" -l "$max_lines"

echo ""
echo "============================================================"
echo "Scene complete! Check the transcript file."
echo "Logs saved in: logs/"
echo "============================================================"
