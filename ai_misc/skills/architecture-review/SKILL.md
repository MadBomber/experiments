---
description: Deep architecture review before major features. Challenges the existing stack, asks the greenfield question, identifies forcing functions. Use when adding a new platform, major capability, or anything that feels like "bolting on."
argument-hint: Brief description of the new requirement (e.g., "iOS companion app with sync")
---

# Architecture Review

You are helping a developer evaluate whether their current system architecture is the right foundation for a major new requirement. Your job is to challenge assumptions, not to confirm them.

## When to Use This Skill

Invoke `/architecture-review` BEFORE `/feature-dev` when any of these are true:
- Adding a new platform (mobile, desktop, web, CLI)
- Adding sync/replication between devices
- Changing from single-user to multi-user (or vice versa)
- A new requirement needs capabilities the current stack can't provide natively
- You're about to add a "bridge," "sidecar," or "adapter" to connect two different technology stacks
- The feature spans >5 files and requires new infrastructure

## Anti-Patterns This Skill Catches

| Smell | What it looks like | What it usually means |
|-------|-------------------|----------------------|
| **Bridge-to-a-bridge** | Adding a Swift sidecar to a Tauri app to talk to CloudKit | The host technology is wrong for the new requirements |
| **Bolting on** | "We'll add a sync endpoint to the existing API" | Sync is a fundamentally different concern that deserves its own design |
| **Three-process stack** | Host → Backend → Helper, each in a different language | Accidental complexity; one of these layers should be the host |
| **"We already have X"** | Keeping a technology because it exists, not because it fits | Sunk cost fallacy; the question is what's right going forward |
| **Incremental thinking** | Designing the new feature as an addition to the old system | Missing the chance to re-evaluate the whole architecture |

---

## Phase 1: Understand the Requirement Deeply

**Goal**: Understand what the user actually needs, not what they're asking for technically.

**New requirement**: $ARGUMENTS

**Actions**:
1. Ask the user about **usage patterns** before proposing solutions:
   - How will they use this feature day-to-day? (commute, desk, travel, etc.)
   - What devices, what connectivity, what frequency?
   - What's the failure mode they care most about? (data loss, downtime, latency)
   - Is this for them alone, or will others use it?

2. Ask about the **2-year horizon**:
   - What other features are likely after this one?
   - Will there be more platforms? More users? More data?
   - What capabilities would they want that seem "too hard" right now?

3. **Do not propose solutions yet.** Just listen and document.

---

## Phase 2: Map the Existing Architecture

**Goal**: Understand what exists and identify the load-bearing walls vs. the drywall.

**Actions**:
1. Launch a code-explorer agent to map the current architecture:
   - What are the major components and their responsibilities?
   - What technology stack is each component built with?
   - Which components are tightly coupled vs. loosely coupled?
   - Which components are "load-bearing" (hard to replace) vs. "drywall" (easy to swap)?

2. Classify each component:

   | Component | Role | Technology | Load-bearing? | Why? |
   |-----------|------|-----------|---------------|------|
   | (fill in) | | | | |

3. Identify the **interfaces between components**:
   - Are they subprocess calls? HTTP APIs? Function calls? FFI bridges?
   - Which interfaces are clean contracts vs. tight coupling?

---

## Phase 3: The Greenfield Question

**Goal**: Break anchoring bias by designing from scratch.

**CRITICAL**: This is the most important phase. It's the one most likely to be skipped, and the one that catches the biggest architectural mistakes.

**Actions**:
1. **Forget the existing code.** Ask yourself:
   > "If I were building this system today — knowing it needs [current capabilities] AND [new requirement] — what technology stack would I choose?"

2. Design the greenfield architecture:
   - What language/framework for each component?
   - What are the interfaces?
   - What are the deployment targets?

3. Compare greenfield vs. current:

   | Capability | Current Stack | Greenfield Stack | Friction |
   |-----------|--------------|-----------------|----------|
   | (new requirement) | How would you add it? | How would it work natively? | How much bridging? |
   | (existing feature 1) | Already works | Would it be easier/harder? | |
   | (existing feature 2) | Already works | Would it be easier/harder? | |

4. **Look for the "bridge smell"**:
   - If the current stack needs a bridge/sidecar/adapter for the new requirement, that's a signal.
   - If the greenfield stack handles the new requirement natively AND the existing features equally well, that's a strong signal to pivot.

5. **Ask the hard question explicitly:**
   > "The current system uses [technology X] as the host. The new requirement needs [capability Y] which [technology X] can't provide natively. Should we pivot the host to [technology Z] which provides [capability Y] natively and can still call our existing [tools/CLIs/libraries]?"

   Present this question to the user with:
   - What you'd gain (list specific capabilities)
   - What you'd lose (list specific components that need rewriting)
   - What you'd preserve (list components that are already decoupled)
   - The migration path (can both stacks coexist during transition?)

---

## Phase 4: Evaluate the Pivot Cost

**Goal**: Make the pivot/stay decision concrete, not abstract.

**Actions**:
1. **Inventory what survives a pivot:**
   - Code designed as standalone tools/CLIs/libraries → survives
   - Code tightly coupled to the current host → needs rewriting
   - Data (databases, file formats, schemas) → survives if well-designed
   - Tests → may need adaptation but logic tests survive

2. **Inventory what needs rewriting:**
   - Host application code (UI, lifecycle, system integration)
   - Build/packaging scripts
   - Any FFI bridges or host-specific adapters

3. **Estimate the ratio:**
   - If >50% of the codebase survives → pivot is viable
   - If <20% survives → pivot is a rewrite (much higher cost)

4. **Check for the "already designed for this" signal:**
   - If the architecture explicitly documents patterns like "each tool must work standalone" or "subprocess + manifest pattern" — the system was already designed to be host-agnostic. A pivot is cheaper than it looks.

---

## Phase 5: Propose the Options

**Goal**: Present the user with clear options, not a single recommendation.

**Actions**:
1. Present 2-3 options:

   **Option A: Bolt On** (add to existing architecture)
   - What it looks like
   - What's awkward (bridges, sidecars, workarounds)
   - What's easy (no rewriting, incremental)
   - Risk: accumulating architectural debt

   **Option B: Pivot** (change the host, keep the tools)
   - What it looks like
   - What's better (native capabilities, simpler architecture)
   - What's harder (rewriting host code, learning new stack)
   - The migration path (can both coexist?)

   **Option C: Hybrid** (if applicable)
   - Keep current host for some functions, build new host for others
   - When this makes sense vs. when it's just delaying the pivot

2. **State your recommendation clearly** with reasoning.

3. **Present the "future features" test:**
   > "In 6 months, you'll likely want [Widget / Share Extension / Siri integration / etc.]. With Option A, that requires [X]. With Option B, that requires [Y]."

4. Ask the user to decide before proceeding to implementation planning.

---

## Phase 6: Document the Decision

**Goal**: Persist the analysis so it's not lost to context compaction.

**Actions**:
1. Create a decision document in the project's `docs/` directory:
   - The requirement that triggered the review
   - Options considered with trade-offs
   - The decision and rationale
   - What's preserved, what's rewritten, what's dropped
   - The migration path

2. If the decision is to pivot, create an architecture document for the new system.

3. If the decision is to bolt on, document the architectural debt explicitly:
   > "We chose to add [X] as a sidecar because [reason]. This means [future requirement] will also need a bridge. Revisit this decision when [trigger]."

---

## Checklist: Questions I Must Ask Before Proposing Any Architecture

- [ ] How does the user actually use this day-to-day? (not how I imagine they use it)
- [ ] What connectivity/environment? (desk, commute, plane, mixed)
- [ ] If I were starting today with ALL known requirements, would I pick the same stack?
- [ ] Does the new requirement need capabilities the current stack can't provide natively?
- [ ] Am I adding a bridge to a bridge? (three-process smell)
- [ ] What features are coming in the next 6-12 months? Does the current stack support them?
- [ ] What percentage of the existing code is host-agnostic (CLI tools, libraries, data schemas)?
- [ ] Can the current host and a new host coexist during migration?

If I skip any of these questions, I'm likely anchored to the existing architecture and not thinking clearly.
