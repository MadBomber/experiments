# Architecture Review — Claude Code Skill

A [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skill that forces deep architectural thinking before major features. It challenges the existing stack, asks the greenfield question, and identifies forcing functions that should trigger re-architecture.

## The Problem It Solves

When a major new requirement arrives (new platform, sync, new capability), the natural instinct is to bolt it onto the existing system. This leads to:

- **Bridge-to-a-bridge**: Adding a Swift sidecar to a Tauri app to talk to CloudKit
- **Three-process stacks**: Host → Backend → Helper, each in a different language
- **Sunk cost architecture**: Keeping technology because it exists, not because it fits

This skill forces you to ask: *"If I were building this system today with ALL known requirements, would I make the same technology choices?"*

## Origin

This skill was born from a real planning session where an iOS companion app was being designed for a macOS desktop app (Tauri/Rust + Python). Through three rounds of feedback from an external architect, the team discovered that:

1. The LAN-only sync approach was impractical (should have asked about usage patterns first)
2. CloudKit was the right transport (should have evaluated native platform capabilities)
3. The entire Tauri host should be replaced by native Swift (should have asked the greenfield question)

The skill encodes the thinking patterns that an experienced architect would apply — particularly the **greenfield question** that breaks anchoring bias.

## Install

### Option A: Clone to Claude Code skills directory

```bash
# Clone into your Claude Code skills directory
git clone https://github.com/lbyiuou0329/claude-skill-architecture-review.git \
  ~/.claude/skills/architecture-review
```

### Option B: Copy the SKILL.md file

```bash
mkdir -p ~/.claude/skills/architecture-review
curl -o ~/.claude/skills/architecture-review/SKILL.md \
  https://raw.githubusercontent.com/lbyiuou0329/claude-skill-architecture-review/main/SKILL.md
```

## Usage

In Claude Code, invoke the skill before starting a major feature:

```
/architecture-review iOS companion app with CloudKit sync
```

Or when you notice you're about to add a bridge:

```
/architecture-review Adding real-time collaboration to our Electron app
```

## What It Does

The skill runs through 6 phases:

| Phase | Purpose | Key Question |
|-------|---------|-------------|
| 1. Understand Requirements | Ask about real usage patterns | "How do you actually use this day-to-day?" |
| 2. Map Architecture | Classify components as load-bearing vs. drywall | "Which parts are hard to replace?" |
| 3. Greenfield Question | Design from scratch, compare to current | "If starting today, would I pick the same stack?" |
| 4. Evaluate Pivot Cost | Inventory what survives vs. needs rewriting | "Is >50% of the code host-agnostic?" |
| 5. Propose Options | Present bolt-on vs. pivot vs. hybrid | "What does this look like in 6 months?" |
| 6. Document Decision | Persist analysis in project docs | "Will future-me find this decision and its rationale?" |

## Anti-Patterns It Catches

| Smell | Example | Signal |
|-------|---------|--------|
| **Bridge-to-a-bridge** | Swift sidecar for Tauri to use CloudKit | Host technology is wrong |
| **Three-process stack** | Rust → Python → Swift helper | Accidental complexity |
| **"We already have X"** | Keeping Tauri because it's built | Sunk cost fallacy |
| **Bolting on** | "Add a sync endpoint to the REST API" | Sync deserves its own design |
| **Incremental thinking** | New platform as an addon, not a redesign trigger | Missing the forcing function |

## When to Use

Use `/architecture-review` **before** `/feature-dev` when:

- Adding a new platform (mobile, desktop, web)
- Adding sync/replication between devices
- Changing user model (single → multi, or vice versa)
- A new requirement needs capabilities your stack can't provide natively
- You're about to add a "bridge," "sidecar," or "adapter"

## License

MIT
