# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Dynamic Creature Terrarium — a terminal-based ecosystem using Zeitwerk for autoloading and hot-reloading, Mudis for centralized state management, and procedural creature generation. Autonomous creatures live on a 2D grid, moving, interacting, claiming territory, and broadcasting messages in real-time.

## Commands

```bash
# Install dependencies
bundle install

# Run the terrarium
bundle exec ruby main.rb

# Generate a new robot with random traits
ruby generate.rb

# Generate a robot with a specific name
ruby generate.rb "Dancer"
```

During simulation: edit `robots/*.rb` files to change behavior live, delete to remove creatures, add new files to spawn creatures. Press `Ctrl+C` or `q` to exit.

## Architecture

**Entry point:** `main.rb` — `Terrarium` class orchestrates the load-watch-tick-render loop at ~4 ticks/second.

**Core pipeline:**
1. `RobotLoader` (`lib/robot_loader.rb`) — Uses Zeitwerk for autoloading and hot-reloading of robot files. Each robot defines a class inheriting from `Creature`.
2. `World` (`lib/world.rb`) — 40x20 grid simulation engine. Uses StateStore (Mudis) for all persistent state. Manages robot positions, territory ownership, markers, encounters, and action resolution per tick.
3. `Renderer` (`lib/renderer.rb`) — Ratatui-based terminal UI with a 75/25 split: colored grid on the left, scrolling event log on the right.
4. `AsyncRunner` (`lib/async_runner.rb`) — Fiber-based concurrency via the `async` gem. Provides `map_concurrent()` for parallel robot ticks and fire-and-forget LLM background tasks.

**Supporting modules:**
- `lib/creature.rb` — Base `Creature` class. Defines the `tick(state, neighbors, world)` / `encounter(other_name, other_icon)` interface plus territory helpers, Mudis-backed memory/broadcast helpers, and optional LLM integration.
- `lib/state_store.rb` — Central state management layer wrapping Mudis. Provides namespaced access to world state, robot data, territory, markers, events, broadcasts, and per-robot memory.
- `lib/llm_config.rb` — Configures RubyLLM for Ollama (localhost:11434) and `chaos_to_the_rescue` for runtime method generation. Degrades silently if unavailable.
- `lib/logging.rb` — Lumberjack file logger writing to `log/terrarium.log`.

**Hot-reload flow:** `listen` gem watches `robots/` → any file change sets a reload flag → at start of next tick, Zeitwerk reloads all robot constants → fresh creature instances synced with World.

## Robot Contract

Every `robots/*.rb` file defines a class inheriting from `Creature` (e.g., `class Wanderer < Creature`). The class name must match the filename in CamelCase (zeitwerk convention).

Required interface:
- `name`, `icon` (single char), `color` (ANSI symbol), `max_energy`
- `tick(state, neighbors, world)` → returns action hash(es): `move`, `say`, `place_marker`, `absorb`
- `encounter(other_name, other_icon)` → returns action hash(es)

The base `Creature` class provides defaults, territory helpers (`territory_suggest_move`, `territory_stats`), Mudis-backed memory/broadcast helpers (`store_memory`, `recall_memory`, `broadcast`, `read_broadcasts`), and optional LLM methods (`llm_decide`, `llm_strategize`).

## Key Technical Details

- **Zeitwerk** handles autoloading and hot-reloading of robot files. All-or-nothing reload triggered by file changes.
- **Mudis** (in-memory LRU cache) serves as the central state store via the `StateStore` module. All simulation data (positions, territory, markers, events) flows through Mudis namespaces.
- **RubyLLM** provides LLM integration via Ollama (localhost:11434). Optional — degrades silently.
- **chaos_to_the_rescue** generates missing method implementations at runtime via LLM.
- `generate.rb` procedurally creates robots from randomized traits and drops them into `robots/` for automatic pickup.
- Logging goes to `log/terrarium.log`, not stdout.
