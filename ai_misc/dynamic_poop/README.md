# Dynamic Creature Terrarium

A terminal-based creature ecosystem that demonstrates **Ruby 4.0's `Ruby::Box`** namespace isolation combined with **hot-reloading** via the `listen` gem. Each `.rb` file dropped into the `robots/` directory becomes a living creature on a 2D grid — edit the file and its behavior changes on the next tick; delete it and the creature vanishes.

## Purpose

This project is an experiment in three Ruby 4.0 capabilities:

1. **In-process namespace isolation** — Every robot is loaded inside its own `Ruby::Box`, so class definitions, constants, and global state in one file cannot collide with another. Discarding a Box cleanly unloads all of its definitions.
2. **Live code reloading** — The `listen` gem watches `robots/` for filesystem events. Added, modified, or removed files are picked up within one tick cycle with no restart required.
3. **Procedural generation** — A standalone generator script creates new robot files from randomized traits (movement patterns, personalities, special abilities) and drops them into the watched directory so they join the simulation automatically.

## How It Works

```
main.rb  ──>  RobotLoader  ──>  Ruby::Box.new per file
   │               │
   │               └──  robots/*.rb  (watched by listen)
   │
   ├──  World       (40x20 grid, tick engine, collision resolution)
   └──  Renderer    (ANSI escape codes, colored grid + event log)
```

On startup, `main.rb` loads every `.rb` file in `robots/` into its own `Ruby::Box`, spawns a `Creature` instance from each, and places them on a 40x20 grid. A simulation loop ticks ~4 times per second:

1. Each creature's `tick()` method receives its position, energy, age, nearby neighbors, and world state.
2. The creature returns action hashes — move, speak, place a marker, or absorb a neighbor.
3. The world resolves all actions, checks for encounters between adjacent creatures, and the renderer redraws the terminal.

When a file changes on disk, `listen` fires a callback:
- **Added** — a new Box is created, the file is loaded, and the creature joins the grid.
- **Modified** — the old Box is discarded, a fresh Box loads the updated file, and the creature's behavior changes in place.
- **Removed** — the Box is discarded and the creature disappears from the grid.

### Fallback Mode

When `RUBY_BOX=1` is not set (or on Ruby < 4.0), the loader falls back to wrapping each file in an anonymous `Module` for partial isolation. The simulation runs identically; only the depth of namespace separation differs.

## Robot Contract

Each file in `robots/` defines a `Creature` class that implements:

```ruby
class Creature
  def name        = "MyRobot"
  def icon        = "R"        # single character shown on the grid
  def color       = :cyan      # :red, :green, :yellow, :blue, :magenta, :cyan, :white
  def max_energy  = 100

  # Called every tick. Returns an action hash or array of action hashes.
  def tick(state, neighbors, world)
    # state:     { x:, y:, energy:, age: }
    # neighbors: [{ name:, icon:, distance:, direction: }]
    # world:     { width:, height:, tick:, markers: [...] }
    { move: [1, 0] }
  end

  # Called when another robot is on an adjacent cell.
  def encounter(other_name, other_icon)
    { say: "Hello, #{other_name}!" }
  end
end
```

Available actions:

| Action | Example | Effect |
|---|---|---|
| `move` | `{ move: [dx, dy] }` | Move relative to current position |
| `say` | `{ say: "text" }` | Broadcast a message to the event log |
| `place_marker` | `{ place_marker: "#" }` | Leave a visible marker on the grid cell |
| `absorb` | `{ absorb: true }` | Absorb the nearest adjacent robot, gaining half its energy |

Return an array to combine multiple actions in one tick: `[{ move: [1, 0] }, { say: "Moving!" }]`

## Starter Robots

| Robot | Icon | Color | Behavior |
|---|---|---|---|
| Wanderer | `W` | cyan | Random walk, greets neighbors |
| Predator | `X` | red | Chases nearest robot, absorbs on contact |
| Builder | `B` | green | Walks in a square, places markers |
| Philosopher | `?` | magenta | Stationary, broadcasts philosophical quotes |
| Mimic | `M` | yellow | Copies the movement direction of the last robot it encountered |

## Setup

Requires **Ruby 4.0+** for `Ruby::Box` isolation (falls back gracefully on older versions).

```bash
bundle install
```

## Usage

Run the simulation with full namespace isolation:

```bash
RUBY_BOX=1 bundle exec ruby main.rb
```

Run without `Ruby::Box` (fallback mode):

```bash
bundle exec ruby main.rb
```

Generate a new robot with a random name:

```bash
ruby generate.rb
```

Generate a robot with a specific name:

```bash
ruby generate.rb "Dancer"
```

While the simulation is running:
- Edit any file in `robots/` and the creature's behavior updates on the next tick.
- Delete a file and the creature vanishes from the grid.
- Drop a new `.rb` file into `robots/` (manually or via `generate.rb`) and it joins automatically.
- Press `Ctrl+C` to exit.

## File Structure

```
dynamic_poop/
├── Gemfile              # listen, lumberjack, ruby_llm, chaos_to_the_rescue
├── main.rb              # Entry point: watcher + simulation loop
├── generate.rb          # Procedural robot generator
├── lib/
│   ├── robot_contract.rb  # Creature base class injected into each Box
│   ├── robot_loader.rb    # Ruby::Box lifecycle: load / reload / unload
│   ├── world.rb           # 2D grid, tick engine, collision detection, markers
│   └── renderer.rb        # ANSI terminal rendering (grid + event log)
└── robots/              # Watched directory — drop .rb files here
    ├── wanderer.rb
    ├── predator.rb
    ├── builder.rb
    ├── philosopher.rb
    └── mimic.rb
```

## Dependencies

- [listen](https://github.com/guard/listen) ~> 3.10 — filesystem event watcher
- [lumberjack](https://github.com/bdurand/lumberjack) — file-based logging
- [ruby_llm](https://github.com/crmne/ruby_llm) — unified LLM interface (Ollama)
- [chaos_to_the_rescue](https://github.com/codenamev/chaos_to_the_rescue) — LLM-powered runtime method generation
