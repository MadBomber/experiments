# Writers Room — Rails Application Design

**Date**: 2026-05-01
**Status**: Approved

## Overview

A multi-user Rails 8 web application that turns the `writers_room` experiment into a full platform for AI-powered screenplay development. Characters are modeled as persistent robot_lab agents (ActiveRecord models with serialized LLM state), following the "agents as domain models" pattern. The app guides writers through the full screenplay prep process before running AI-generated scene dialog in real time.

---

## Tech Stack

| Layer | Choice |
|---|---|
| Framework | Rails 8 |
| Views | Phlex + ruby_ui components |
| Real-time | Hotwire (Turbo Streams + Stimulus) + ActionCable |
| LLM agents | robot_lab gem (wraps ruby_llm) |
| Authentication | passwordless gem (magic-link email) |
| Authorization | Pundit (policy objects per resource) |
| Background jobs | Solid Queue (Rails 8 default) |
| Import / Export | Markdown files with YAML frontmatter |

---

## Domain Model

### Core Concept

The domain is modeled after real film/theater production:

- **Actor** — a real person (e.g. Michael J. Fox) with a consistent LLM persona applied to every character they play
- **Character** — a role (e.g. Marty McFly) that is a persistent robot_lab agent carrying LLM state across all projects
- **Casting** — a pure three-way join linking Actor + Character + Project; no narrative attributes
- **Project** — a production (film, play, radio drama) containing scenes, story, and prep material
- **Story** — the prose narrative treatment for a project (separate from project metadata; one project can have multiple story drafts)
- **CharacterArc** — how a specific character's arc manifests within a specific project (start state, end goal, current position, key turning points)
- **Scene** — a single scene within a project, with its own lifecycle status
- **SceneRun** — one execution of a scene, producing a transcript via live AI dialog generation
- **ResearchMaterial** — freeform research notes anchored to a project, character, or scene

### Key Design Decisions

1. **Character IS the LLM agent.** Character holds both the role definition (personality, voice, arc) and the robot_lab agent state (model, provider, data, token counts). State persists across projects — Marty McFly remembers BTTF1 when he enters BTTF2.

2. **Casting is a pure join.** Actor + Character + Project, nothing else. The same character can be recast with a different actor in a different project.

3. **An Actor can play multiple Characters in the same Scene.** SceneCharacter references Character directly — there is no constraint preventing two Characters in a scene from sharing an Actor. (Radio drama convention.)

4. **Arcs belong to the project layer.** `Character.character_arc` is a timeless arc concept. `CharacterArc` (per character per project) holds the project-specific start state, end goal, and current position. `Project` holds the macro story arc and plot points. `SceneCharacter.arc_advancement` records what arc movement each scene delivers.

5. **Scene status is a state machine.** `draft → ready_for_review → released`. Only released scenes are visible to Actor-role users.

6. **Project has a prep workflow.** `prep_status` tracks the 6-phase screenplay prep process. Only `ready` projects can have scenes created and run.

---

## Database Schema

### Users & Auth

```
users
  id, email (unique not null), name
  actor_id (optional — links a user to their Actor record when role includes :actor)
  timestamps

roles
  id, name (enum: producer | writer | director | casting_director | actor)

user_roles
  user_id, role_id
  unique on [user_id, role_id]
```

### Actors & Characters

```
actors
  id, name, description
  style_notes          # LLM persona consistency — informs system prompt Layer 1
  preferred_model
  preferred_provider
  timestamps

characters             # IS the robot_lab agent
  id
  name, archetype
  personality          # timeless — unchanged across all projects
  voice_pattern
  character_arc        # timeless arc concept
  motivation
  internal_conflict
  physical_description
  mannerisms
  # robot_lab agent state
  model, provider
  data (text)          # serialized LLM conversation state
  input_tokens, output_tokens, total_tokens
  timestamps
```

### Castings & Arcs

```
castings              # pure three-way join
  id
  actor_id
  character_id
  project_id
  unique on [character_id, project_id]
  timestamps

character_arcs        # character's arc within a specific project
  id
  character_id
  project_id
  arc_description
  arc_start_state
  arc_end_goal
  current_position    # updated after each scene run
  key_turning_points  # json array of arc beat descriptions
  timestamps
  unique on [character_id, project_id]
```

### Projects & Stories

```
projects
  id
  title, description, genre, tagline
  # narrative fields
  setting, tone
  logline, synopsis
  story_arc           # macro narrative (Level 1 of arc hierarchy)
  plot_points         # json array
  conflicts, core_stakes, conflict_escalation
  # screenplay prep fields
  research_notes, world_building_notes
  similar_works       # json array
  visual_references   # json array
  differentiation_notes, marketing_angle
  title_alternatives  # json array
  # workflow
  prep_status         # enum: concept|seed_growing|visualization|research|references|identity|ready
  created_by          # user_id
  timestamps

stories               # prose narrative treatment (separate from project metadata)
  id
  project_id
  title
  act_structure       # enum: three_act | five_act | hero_journey | etc.
  narrative_arc       # prose treatment of the full arc (distinct from project.story_arc summary)
  acts                # json array of {label, content} — supports any act structure
  plot_points         # prose
  conflict_escalation # prose
  resolution          # prose
  timestamps
  # Note: project.story_arc is a one-sentence summary of the macro narrative.
  # stories.narrative_arc is the full prose treatment — they are complementary, not duplicated.
```

### Scenes & Runs

```
scenes
  id
  project_id
  number, name
  location, week
  context             # prose setup
  beat_structure      # json array of beats
  atmosphere          # prose
  key_imagery         # prose
  # lifecycle
  status              # enum: draft | ready_for_review | released
  submitted_at        # when writer submitted for review
  released_at         # when director approved
  released_by         # user_id of approving director
  timestamps

scene_characters      # cast list for a scene
  id
  scene_id
  character_id
  scene_objectives    # what this character wants in this scene
  arc_advancement     # what arc movement this scene delivers for this character
  timestamps

scene_runs            # one execution of a scene
  id
  scene_id
  status              # enum: queued | running | completed | failed
  started_at, completed_at
  started_by          # user_id
  timestamps

transcript_lines
  id
  scene_run_id
  character_id
  content             # the dialog line
  emotion             # optional
  addressing          # optional — character being addressed
  position            # integer ordering
  timestamps
```

### Research

```
research_materials
  id
  subject
  category            # enum: world_building | character_study | historical | visual | other
  project_id
  character_id        # optional
  scene_id            # optional
  summary             # prose
  key_facts           # prose
  world_building_notes # prose
  accuracy_requirements # prose
  sources             # json array
  timestamps
```

---

## Role-Based Access Control

Five roles. A user can hold multiple roles simultaneously. Producer is the superuser.

| Resource | Producer | Writer | Director | Casting Dir. | Actor |
|---|---|---|---|---|---|
| Actors | CRUD | CRUD | read | CRUD | own only |
| Characters | CRUD | CRUD | read | read | own only |
| Projects | CRUD | CRUD | read | read | read |
| Scenes (draft) | CRUD | CRUD | — | — | — |
| Scenes (ready_for_review) | CRUD | read+submit | read+approve/reject | — | — |
| Scenes (released) | CRUD | read | read+run | read | own scenes only |
| Castings | CRUD | read | read | CRUD | read |
| CharacterArcs | CRUD | CRUD | read | read | own only |
| Stories | CRUD | CRUD | read | — | — |
| Research | CRUD | CRUD | read | — | — |
| Scene Runs / Transcripts | all | read | create+read | read | own scenes only |
| Import / Export | ✓ | ✓ | — | — | — |
| Users / Roles | CRUD | — | — | — | — |

**Actor-role scoping**: "own only" / "own scenes" means records are scoped to the Actor record linked to `current_user.actor`.

---

## Authentication Flow (passwordless)

1. User enters email at `/auth/sign_in`
2. `passwordless` sends a magic link token by email
3. User clicks link → session established, `current_user` available in all controllers
4. Pundit policies check `current_user.roles` on every controller action
5. `User#has_role?(name)` helper: `roles.exists?(name:)` — no additional gem needed

---

## Rails App Structure

```
app/
  controllers/
    actors_controller.rb
    characters_controller.rb
    castings_controller.rb
    projects_controller.rb
    stories_controller.rb
    scenes_controller.rb
    scene_runs_controller.rb
    research_materials_controller.rb
    imports_controller.rb
    exports_controller.rb
    users_controller.rb          # producer-only user management
  models/
    user.rb, role.rb, user_role.rb
    actor.rb, character.rb
    casting.rb
    project.rb, story.rb
    character_arc.rb
    scene.rb, scene_character.rb
    scene_run.rb, transcript_line.rb
    research_material.rb
  views/                         # Phlex components
    layouts/application_layout.rb
    components/                  # ruby_ui + custom shared components
    actors/, characters/
    projects/, stories/
    scenes/, scene_runs/
    research_materials/
    imports/, exports/
  jobs/
    scene_run_job.rb             # runs the scene in background
  services/
    director_service.rb          # orchestrates robot_lab agents for a scene run
    system_prompt_builder.rb     # composes the 4-layer system prompt per character
    markdown_import_service.rb   # dispatches to per-type importers
    markdown_export_service.rb
    importers/
      actor_importer.rb
      character_importer.rb
      project_importer.rb
      story_importer.rb
      arc_importer.rb            # also creates Casting record
      scene_importer.rb
      research_importer.rb
  policies/                      # Pundit policies
    application_policy.rb
    actor_policy.rb, character_policy.rb
    casting_policy.rb, project_policy.rb
    story_policy.rb, scene_policy.rb
    scene_run_policy.rb, research_material_policy.rb
  channels/
    scene_run_channel.rb         # ActionCable subscription for live transcript
```

---

## Scene Lifecycle

```
draft
  └─ Writer clicks "Submit for Review"
ready_for_review
  ├─ Director clicks "Approve" → released
  └─ Director clicks "Reject"  → draft (with notes)
released
  └─ Director can run scene
```

Scene `submitted_at`, `released_at`, and `released_by` are recorded on status transition.

---

## Project Prep Workflow

```
concept → seed_growing → visualization → research → references → identity → ready
```

Each phase maps to the screenplay prep skill's 6 phases. Only `ready` projects can have scenes created. Writers see a prep checklist dashboard per project showing which phases are complete. The UI surfaces relevant fields for each phase.

**Policy constraint**: `ScenePolicy#create?` must verify `project.prep_status == :ready` in addition to the role check. A Writer cannot create scenes in a project that hasn't completed the prep workflow.

---

## System Prompt Strategy

Each Character in a scene run gets its own robot_lab agent. `DirectorService` builds the agent via `SystemPromptBuilder`, which composes four layers:

**Layer 1 — Actor** (consistent across all characters this actor plays)
- `actor.name`, `actor.style_notes`

**Layer 2 — Character** (timeless, unchanged across all projects)
- `character.personality`, `character.voice_pattern`, `character.character_arc`
- `character.motivation`, `character.internal_conflict`, `character.archetype`
- `character.physical_description`, `character.mannerisms`
- `character_arc.arc_start_state`, `character_arc.current_position` (where they are NOW in this project)

**Layer 3 — Project** (the production context)
- `project.title`, `project.genre`, `project.setting`, `project.tone`
- `project.story_arc`, `project.plot_points`

**Layer 4 — Scene** (immediate context)
- `scene.context`, `scene.atmosphere`, `scene.beat_structure`
- `scene_character.scene_objectives` (what this character wants in this scene)
- `scene_character.arc_advancement` (what arc movement this scene is meant to deliver)
- Cast list (names of other characters present)

**Runtime user prompt** (changes each turn)
- Last N transcript lines
- "What does [character name] say?"

**Model/provider cascade**: `character.model || actor.preferred_model`

After each scene run completes, `character_arc.current_position` is updated to reflect arc advancement — the character carries this forward into subsequent scenes.

### Response Decision Logic

Each agent decides whether to speak using the same logic from the original experiment:
1. Always respond if character's name appears in the most recent line
2. Respond if last speaker wasn't this character and they haven't spoken more than once in the last 3 lines
3. 10% random chance to interject (preserves natural conversation flow)

---

## Scene Run Flow (Real-Time)

1. Director clicks **Run Scene** → `POST /scene_runs`
2. `SceneRun` created (status: `queued`), `SceneRunJob` enqueued
3. Turbo Stream redirects browser to live transcript page
4. `SceneRunJob` starts: `DirectorService` builds one robot_lab agent per character in the scene
5. Agents take turns generating dialog; each line saved as `TranscriptLine`
6. `Turbo::StreamsChannel.broadcast_append_to("scene_run_#{id}", target: "transcript", ...)` fires per line — dialog appears in browser as generated
7. Stats bar (line count, tokens) updated via separate `broadcast_replace_to`
8. Scene ends → `SceneRun` status: `completed`, `character_arc.current_position` updated per character

---

## Live Transcript UI

- Scene header: title, status badge, cast list
- Transcript area: `turbo_frame` target `#transcript`, each character color-coded by position in cast list
- "Generating…" indicator shows which character is currently being prompted
- Stop Scene button (Director/Producer only)
- Stats bar: line count, total tokens

**Actor-role users** see the same page with Run button removed, token stats hidden, navigation scoped to "My Scenes".

---

## Markdown Import / Export Format

All import/export files are `.md` with YAML frontmatter. The `type:` frontmatter field identifies the file type for the import dispatcher.

### Convention
- **YAML frontmatter**: structured/typed fields (enums, slug references, lists, model names)
- **`## Section` headers**: narrative prose — headings match database column names exactly, making import/export deterministic

### Seven File Types

**actor** — frontmatter: `name, preferred_model, preferred_provider` — body: `## Description`, `## Style Notes`, `## Notable Works`, `## Performance Notes`

**character** — frontmatter: `name, archetype, model, provider` — body: `## Personality`, `## Voice Pattern`, `## Character Arc`, `## Motivation`, `## Internal Conflict`, `## Physical Description`, `## Mannerisms`

**project** — frontmatter: `title, genre, prep_status, similar_works[], title_alternatives[]` — body: `## Tagline`, `## Logline`, `## Synopsis`, `## Setting`, `## Tone`, `## Conflicts`, `## Core Stakes`, `## Marketing Angle`

**story** — frontmatter: `project, act_structure` — body: `## Narrative Arc`, then one `## Act N — Title` section per act (count matches `act_structure`), then `## Plot Points`, `## Conflict Escalation`, `## Resolution`

**arc** — frontmatter: `character, project, actor` (encodes both Casting and CharacterArc) — body: `## Arc Description`, `## Arc Start State`, `## Arc End Goal`, `## Key Turning Points`, `## Current Position`
  - Import is idempotent: upserts both the Casting record and the CharacterArc record on `[character_id, project_id]` — safe to re-import after edits

**scene** — frontmatter: `number, project, location, week, status, characters[]` — body: `## Context`, `## Atmosphere`, `## Key Imagery`, `## Beat Structure`, `## Character Objectives`, `## Arc Advancements`

**research** — frontmatter: `subject, category, project, character (opt), scene (opt), sources[]` — body: `## Summary`, `## Key Facts`, `## World Building Notes`, `## Accuracy Requirements`, `## Sources`

### Export Directory Layout

```
project_export/
  back_to_the_future.md          # project
  story_treatment.md             # story
  characters/
    marty_mcfly.md
    doc_brown.md
  scenes/
    01_the_clock_tower.md
    02_enchantment_under_sea.md
  arcs/
    marty_in_back_to_the_future.md
    doc_in_back_to_the_future.md
  research/
    1955_hill_valley_culture.md
```

### Migrating the Existing Experiment

The `teen_play` project YAML files (`characters/*.yml`, `scenes/*.yml`, `project.yml`) are migrated on first import via a one-time `YamlToMarkdownMigrator` that converts the old format to the new Markdown convention before passing to the standard importers.

---

## UI Navigation

Five primary sections:

- **Actors** — create/edit actors, view their characters and projects
- **Characters** — define roles, personality, voice, view token usage history
- **Projects** — manage productions, assign castings, run prep workflow, browse scenes
- **Scenes** — write scene details, beats, cast list, run scenes, view transcripts
- **Import / Export** — upload Markdown files, download project exports (Writer/Producer only)

Producer-only: **Users** — manage user accounts, assign roles, link users to Actor records.

Actor-role users see a simplified navigation: **My Characters** and **My Scenes** only.

---

## Additional Notes

- **`robot_lab` Rails generators** should be run during setup to install the required infrastructure (jobs, broadcasting support)
- **`passwordless`** requires a `Passwordless::Session` model and mailer — use the gem's installer
- **No user ownership of individual records** beyond `projects.created_by` and `scene_runs.started_by` — access is purely role-based, not per-user ownership
- **The `teen_play` project** from the experiment is the seed data / first import test case
- **`.superpowers/`** should be added to `.gitignore`
