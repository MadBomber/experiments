---
name: continuous-development
description: Use when building, changing, or extending a software project so work stays continuous, prioritized, and consistent across sessions
---

# Continuous Development

## Overview

This skill standardizes how agents keep a project moving over time, even when the agent/model changes. It does this by maintaining four lightweight, human-readable artifacts in the repo root: `VISION.md` (north star), `MISSION.md` (capability checklist), `PLAN.md` (current work queue), and `AGENTS.md` (durable operating rules for agents).

**Core principle:** the repo must always answer "what are we building?" and "what should I do next?" in under 2 minutes.

**Contract (production-complete):**

- `MISSION.md` must be the **complete** capability list required to fulfill `VISION.md` **in production** (backend, frontend, UX, infra/config, security, performance, operations, and quality bars).
- `PLAN.md` must be the **complete** set of slices required to complete `MISSION.md` **Now** **in production**. If a `MISSION.md` Now item has no corresponding `PLAN.md` Now slice, add the missing slice immediately before continuing.

## Default Run Loop (Agent Autonomy)

When this skill is in use and `PLAN.md` has any unchecked items in **Now**, the agent should:

1. Pick the **top-most** unchecked item in `PLAN.md` **Now** and start implementing it immediately.
2. Only stop when one of these is true:
   - A **hard blocker** exists (missing credentials, missing infra, unknown requirement that cannot be inferred safely).
   - The next action would be **high-risk or destructive** (data loss, prod operations, irreversible changes) and requires explicit human approval.
   - A **product decision** is required that cannot be reasonably inferred from repo context.
3. **Do not report progress.** Keep picking up the next top-most unchecked item and continue working without status updates. Only interrupt the human when:
   - All items in `PLAN.md` **Now** are complete, or
   - A hard blocker / high-risk gate / product decision is encountered.
   This is a strong default: avoid "here's what I'm doing" updates; keep executing.
4. **Before stopping or reporting**, the agent must explicitly answer these two questions:
   - **Are all `PLAN.md` Now items done?**
   - **Was a hard blocker / high-risk gate / product decision encountered?**
   If the answer to **both** is **no**, the agent must not stop (unless the human explicitly asks it to stop). It must:
   - Update `PLAN.md` (and `MISSION.md`/`VISION.md` if needed), then
   - Immediately continue with the next top-most unchecked `PLAN.md` **Now** item.
   Emphasize this strongly: **no quiet pauses, no "I'll wait" behavior, no progress reports**—keep executing until completion or a real blocker.

**CRITICAL: Never let PLAN.md Now become empty.** When it becomes empty (all items completed), the agent MUST immediately:

1. Bring in a **sizable batch** of new tasks from `MISSION.md` **Now** (or promote from Mission **Next** if needed).
2. Update `PLAN.md` with these new tasks in the proper dependency order.
3. Update `MISSION.md` to mark any changed statuses (move items to/from Now/Next/Later as appropriate).
4. Keep the work rolling without stopping—do not ask for new instructions, do not report "all done", do not wait for input.

The goal is to finish the entire MISSION.md, not just to empty PLAN.md Now. Work continues until every capability in MISSION.md Now is complete and promoted to Done (recent).

**CRITICAL: Keep `MISSION.md` complete.** If you discover a missing prerequisite or capability needed to fulfill `VISION.md`, add it to `MISSION.md` in the correct dependency order (usually `Next` or `Later` unless it's a prerequisite for `MISSION.md` **Now**). Then keep `PLAN.md` aligned so it fully covers `MISSION.md` **Now**.

After each completed slice:

- Update `PLAN.md` immediately (move the slice to **Done (recent)**).
- Run targeted verification for the change (tests or the project's verification default).
- Commit the completed slice using the repo's git workflow (one logical change per commit).
- Immediately start the next top-most item in `PLAN.md` **Now**.

## When to Use

- Always, when doing project work that changes behavior, adds features, refactors, fixes bugs, or updates docs.
- Especially when work is spread across multiple sessions and you want a consistent "what next" source of truth.

## The Four Documents

### `VISION.md` (North Star)

`VISION.md` is the narrative north star: what the product is, who it is for, and what "winning" means. It should be short and stable.

Rules:

- No checklists.
- Rarely edited; update only when direction changes.
- Prefer clarity over completeness.

Recommended sections:

- **Purpose**: 2–5 sentences
- **Audience**: who it serves
- **Winning**: what success looks like
- **Scope Boundaries**: what the project will not do (short, explicit)

### `MISSION.md` (Capability Checklist)

`MISSION.md` is a living checklist of product capabilities and quality bars. It can be edited and pruned as understanding changes.

Rules:

- Items are outcomes/capabilities, not implementation steps.
- Items should be stable enough to matter for weeks, not hours.
- It is allowed to rewrite, split, merge, and reorder items.
- **Aim to keep at least 10 items in each of Now, Next, and Later sections.** When there is more pending work, keep more. Only reduce below 10 when the entire project is complete and there is nothing left to work on.

Recommended sections:

- **Now**: capabilities to actively drive right now
- **Next**: important capabilities that are queued but not active
- **Later**: capabilities intentionally deferred
- **Done (recent)**: recently completed capabilities (prunable)
- **Quality Bars**: performance, reliability, security, cost guardrails (`[ ] ...`)
- **Scope Boundaries**: what the project will not do (short, explicit)

### `PLAN.md` (Work Queue)

`PLAN.md` is the current queue of small slices that push VISION forward. It should always contain a clear "next thing to do".

Rules:

- Items are one-line slices, written as outcomes.
- Avoid deep detail (no code, no file lists, no step-by-step tutorials).
- Each slice must be self-contained: completable, verifiable, and meaningfully "done" without hidden follow-up work.
- Do not put operating rules here. `PLAN.md` is a prunable task board.
- `PLAN.md` must only contain slices that advance items in `MISSION.md` **Now**. Do not pull work from Mission Next/Later.
- **Aim to keep at least 10 items in each of Now and Next sections.** When there is more pending work, keep more. Only reduce below 10 when all MISSION.md Now items are complete and there is nothing left to work on.

Recommended sections:

- **Now**: aim for 10+ items when MISSION Now has pending work
- **Next**: queued items that are ready but not urgent (aim for 10+ when possible)
- **Later**: ideas that are explicitly not committed
- **Done (recent)**: a small buffer of recently completed items (for continuity)

### `AGENTS.md` (Operating Rules)

`AGENTS.md` is the durable operating system for agents working in the repo. It should contain how to work, how to verify, and how to keep `VISION.md`/`MISSION.md`/`PLAN.md` accurate and clean.

Rules:

- This is where process rules live.
- Keep it concise and action-oriented.
- Prefer stable defaults over exhaustive instructions.

## Bootstrapping (If Docs Are Missing)

If any of `VISION.md`, `MISSION.md`, `PLAN.md`, or `AGENTS.md` is missing, create it. Bootstrap quickly from repo context, then collaborate with the human to confirm the intent and priorities.

Order:

1. `AGENTS.md` (so agents know how to operate)
2. `VISION.md` (north star)
3. `MISSION.md` (capability checklist)
4. `PLAN.md` (current slices)

Process:

- Read repo context first (README, docs, existing runbooks, current product behavior, recent changes).
- Draft minimal versions using the templates in this skill.
- Ask the human to confirm: north star, scope boundaries, and the top items for **Now**.
- After confirmation, keep the docs accurate as the work evolves.

Minimum viable bootstraps:

- `VISION.md`: 5–15 lines, narrative only.
- `MISSION.md`: 10–30 checkboxes to start; merge/split later.
- `PLAN.md`: at least 1 item in **Now** (or an explicit blocker).
- `AGENTS.md`: how to run/verify, how to update/prune the docs, and stop/ask rules.

## Grand vs Immediate (The Placement Test)

Decide where an item belongs using these tests:

- **MISSION.md** if it answers: "What capability or quality bar must become true?"
- **PLAN.md** if it answers: "What is the next smallest verifiable slice to do today?"

If an item is phrased like "Refactor…", "Clean up…", "Improve…", it usually belongs in PLAN only if it unblocks a VISION outcome. Otherwise, it does not belong.

## Bottoms-Up Planning (Dependency Order First)

Plan work bottoms up to avoid broken dependencies and half-done slices.

Rules:

- Before adding slices to `PLAN.md`, determine the dependency order (what must exist first).
- Keep `MISSION.md` and `PLAN.md` ordered so the **top-most** items are always the next to be picked (highest priority) and are not dependent on unfinished work below.
- Prefer enabling primitives first, then building features on top, so each slice is completable when started.
- Do not write slices that require unspecified "future work" to be complete. If a prerequisite is missing, make that prerequisite the first slice.
- If ordering is unclear, collaborate with the human before expanding `PLAN.md`.

`MISSION.md` is also bottoms up:

- Order capabilities so prerequisites come before dependents within `Now` and `Next`.
- Do not put a dependent capability into Mission `Now` if its prerequisites are not already done or explicitly listed above it in Mission `Now`.
- When a grand goal is blocked by missing foundations, rewrite Mission `Now` to focus on the missing foundations first.

## The Continuous Loop (Always Running)

Repeat until blocked:

1. Read `AGENTS.md`, `VISION.md`, `MISSION.md`, and `PLAN.md`, then pick the first unchecked item in **Now**.
2. If `MISSION.md` **Now** is empty, promote the highest-priority items from Mission **Next** into Mission **Now**.
3. Ensure `PLAN.md` **Now/Next/Later** only contains slices that advance Mission **Now**. If `PLAN.md` contains work for Mission Next/Later, move or delete it.
4. Work the smallest slice to completion.
5. Update `PLAN.md` immediately: check the item, add the next slice if it became obvious, and keep caps enforced.
6. If the slice changes capabilities/quality bars, update `MISSION.md`. If it changes direction, update `VISION.md`.

**Silence rule:** do not emit progress updates while executing this loop. Keep going autonomously and continuously.

Stop only for real blockers (missing access, unclear requirements that change behavior, unsafe operations requiring explicit approval) or when `PLAN.md` **Now** is fully complete.

## Caps and Pruning (Keep Docs Clean)

### PLAN pruning rules (no separate done log)

Default caps (not hard limits):

- **Now**: aim for >= 10 items while `MISSION.md` **Now** has pending work (use **Next** to park overflow)
- **Done (recent)**: aim for <= 20 items to preserve quick continuity

Pruning policy:

- When **Done (recent)** exceeds 20, delete the oldest completed items from `PLAN.md`.
- When **Now** grows too large to scan quickly, move overflow to **Next**.

Rationale: checked items are preserved in git history; the live docs must stay readable.

### MISSION pruning rules

Default cap (recommended, but flexible):

- Total checkboxes in `MISSION.md`: aim for <= 50, but allow more if they stay high-signal and well-organized

Pruning policy:

- Remove outcomes that are fully delivered and no longer informative.
- Merge overlapping outcomes into a single clearer one.
- If quality bars are met and stable, keep only the bar statement (not the history).
- Keep `Now` stocked and ordered (aim for 10+); park deferred capabilities in `Next` and `Later`.

## Large Backlogs Without Noise

It is acceptable for `MISSION.md` and `PLAN.md` to contain many items if needed. The constraint is not item count; it is scanability.

Rules:

- Keep **Now** stocked and ordered (aim for 10+); put overflow in **Next** and **Later**.
- Keep items one-line and outcome-shaped.
- Prefer grouping by short section headers (e.g., "Auth", "Billing", "Search") over letting lists become a wall of text.
- Prune completed or superseded items aggressively to prevent noise.

## No Overlap or Duplication Between Docs

The four docs must not contain overlapping or duplicated information. Each doc has one job:

- `VISION.md`: direction (north star narrative)
- `MISSION.md`: capabilities and quality bars (checkboxes)
- `PLAN.md`: current slices and status
- `AGENTS.md`: operating rules for agents

If the same idea appears in multiple places, rewrite it once in the correct doc and delete duplicates. Prefer moving information over copying it.

## Self-Describing Docs (Required)

Each of the four files must state what it is for at the top. Use a short "Purpose" section so new agents/humans orient quickly.

Minimum:

- `VISION.md`: `## Purpose` (north star narrative)
- `MISSION.md`: `## Purpose` (capability and quality-bar checklist)
- `PLAN.md`: `## Purpose` (current slices and status)
- `AGENTS.md`: `## Purpose` (agent operating rules)

## When The Road Expands (New Information)

This is normal and frequent. During development, the road will expand: hidden requirements, constraints, edge cases, unknown dependencies, new stakeholder expectations, or better ways to frame the work will appear mid-flight. This is not an exception case, it is the default reality of building.

Treat "the road expanded" as a productivity event: it is an opportunity to remove future confusion and keep momentum with the latest information.

Rule:
- If new information changes what is true, update the relevant doc(s) so the next agent starts from reality.
- Do not "keep going" on stale assumptions. Keep going by updating the system first (small) or proposing the change (major), then proceed using the updated truth.

Small vs major change gate:
- **Small change** (implement immediately): clarifies wording, splits/merges checklist items, reorders bottoms-up dependencies, adds/removes a few slices, or tightens a scope boundary without changing direction.
- **Major change** (propose first to the human): changes the north star, meaningfully expands scope, introduces a new major subsystem, changes priorities across domains, or adds new operating rules that affect how work is done.

Where to record new information:
- Direction change: `VISION.md`
- Capability/quality change: `MISSION.md`
- Work sequencing change: `PLAN.md`
- Operating/process change: `AGENTS.md`

Practical rule of thumb:
- If the change alters what the "next slice" should be, update `MISSION.md`/`PLAN.md` immediately before coding further.
- If the change alters what the project is, ask the human before editing `VISION.md`, then proceed with the clarified direction.

## "Done" Means Done (Slice Completion Standard)

A slice is only "done" when:

- The outcome is achieved.
- It has an explicit verification method (tests, a reproducible check, or a measurable signal).
- `PLAN.md` reflects the new reality.
- `MISSION.md` checklists reflect the new reality.

If you are working in a repo that expects commits, treat "slice done" as "ready to commit".
If committing is not explicitly requested, ask before committing, but still complete the slice and update the checklists.

## Writing Rules for Checklist Items

Checklist items must be:

- **Outcome-shaped**: describes what becomes true, not how
- **Unambiguous**: a new agent can interpret it the same way
- **Small enough** (PLAN): can be completed without inventing requirements

Allowed phrasing examples:

- MISSION: `[ ] Users can export invoices as PDF`
- PLAN: `[ ] Add invoice PDF export endpoint and UI entry point`

Avoid:

- VISION: `[ ] Improve invoices`
- PLAN: `[ ] Refactor billing code`

## Consistency Rules Across Agents

To reduce model variance, enforce these rules:

- Always keep `PLAN.md` "Now" non-empty (or explicitly state the blocker).
- Always finish a work session by updating `PLAN.md` to reflect reality.
- Never add deep instructions, code, or file listings to these docs; keep them as coordination artifacts.
- Prefer revising existing items over adding duplicates.

## Minimal Templates

### `VISION.md`

```md
# Vision

## Purpose

North star narrative: what we are building, for whom, and what "winning" means.

## Audience

...

## Winning

...

## Scope Boundaries

...
```

### `MISSION.md`

```md
# Mission

## Purpose

Living checklist of capabilities and quality bars. The source of truth for "what must become true".

## Now

- [ ] ...

## Next

- [ ] ...

## Later

- [ ] ...

## Done (recent)

- [x] ...

## Quality Bars

- [ ] ...

## Scope Boundaries

- ...
```

### `PLAN.md`

```md
# Plan

## Purpose

Current work queue of slices. This is a prunable task board, not a place for operating rules.

## Now

- [ ] ...

## Next

- [ ] ...

## Later

- [ ] ...

## Done (recent)

- [x] ...
```

### `AGENTS.md`

```md
# Agent Operating Rules

## Purpose

Durable operating rules for agents: how to run, verify, update/prune the docs, and when to stop/ask.

- How to run the project locally.
- How to verify changes before calling work "done".
- How to update/prune `VISION.md`, `MISSION.md`, and `PLAN.md`.
- Stop/ask rules for risky or ambiguous work.
```
