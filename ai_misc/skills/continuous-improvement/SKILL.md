---
name: continuous-improvement
description: Use while building or maintaining a project to continuously improve the development system itself by fixing recurring process failures, tightening docs/skills, and proposing larger improvements when uncertain
---

# Continuous Improvement

## Overview

This skill makes the development system better over time. While doing normal project work, continuously look for repeated friction (missed checks, unclear steps, inconsistent standards, avoidable mistakes) and convert it into better defaults via small, safe process improvements.

**Core principle:** fix the system, not just the symptom.

## When to Use

- Always alongside active project work (features, fixes, refactors, docs)
- Whenever you notice repeated misses like "forgot to run full tests", unclear handoffs, or recurring production/debugging confusion

## What This Skill Changes (And What It Doesn't)

This skill can improve:
- Existing docs in the repo (`VISION.md`, `MISSION.md`, `PLAN.md`, README/runbooks)
- Existing global skills under `~/.agents/skills/`
- Existing project-level agent guidance files (like `AGENTS.md`), if present

This skill does not:
- Silently introduce large process changes
- Make destructive operational changes (especially in production)

## The Improvement Loop (Always Running)

During work, continuously do:

1. **Notice**: capture the friction in one sentence.
2. **Classify**: is it a one-off or a pattern?
3. **Choose**: fix now (small + certain) or propose (bigger/uncertain).
4. **Apply**: update the smallest existing artifact that prevents recurrence.
5. **Verify**: ensure the change is consistent and doesn't add busywork.

## Special Pattern: Agents Stopping With Work Remaining

If an agent repeatedly stops while `PLAN.md` **Now** still has unchecked items (and there is no hard blocker), treat it as a process failure and fix the system by tightening the relevant guidance (prefer `AGENTS.md`, then the `continuous-development` skill) so the default behavior is to pick the top-most item and continue.

## Classification Rules

Treat as a **pattern** if any is true:
- It happened more than once in the same session
- It's a common failure mode across agents/models (verification skipped, scope creep, missing handoff)
- It's high-impact even once (secrets exposure risk, production risk, data loss risk)

Otherwise treat as a one-off and leave a note in `PLAN.md` if needed.

## Fix vs Propose (Decision Gate)

### You may implement immediately (no ask) only when ALL are true

- The change is **small** (few lines, localized)
- It updates **existing** docs/skills/checklists (no new files)
- It is **clearly beneficial** and low-risk (reduces ambiguity, adds a reminder, tightens a cap)
- It does not meaningfully change product scope or engineering policy

Examples of safe immediate improvements:
- Add or tighten a `PLAN.md` slice rule like "verification: required"
- Clarify pruning caps in `PLAN.md`/`MISSION.md`
- Add a missing "don't print secrets" line to an existing runbook/skill
- Add a "before you say done: run X" reminder to an existing checklist

### You must propose first (and wait for approval) when ANY are true

- Creating new docs/skills/templates
- Editing CI configs (GitHub Actions, Buildkite, etc.)
- Adding new checks that could slow development meaningfully
- Changing team policy (branching strategy, release process, deployment rules)
- Any change where you are not sure it will improve the system

When proposing, present:
- The observed pattern (1–2 sentences)
- The smallest change that prevents recurrence
- The tradeoff (time/cost/noise)

## Where to Put Improvements (Order of Preference)

1. `AGENTS.md` (durable, agent-facing defaults; best for process rules)
2. `MISSION.md` checklist wording (prevents scope drift)
3. `VISION.md` clarifications (prevents direction drift)
4. Existing repo docs/runbooks (README, troubleshooting guides)
5. Existing global skills (when the fix is broadly reusable)
6. `PLAN.md` task queue (transient; task items only)
7. CI changes (only when approved and justified)

### Special rule: keep `PLAN.md` free of operating rules

Do not "improve the system" by adding operating rules to `PLAN.md`. `PLAN.md` is for slices and status only.
Put durable process rules in `AGENTS.md`.

## Anti-Patterns to Avoid

- Turning docs into verbose specs
- Adding rules that are hard to follow or easy to ignore
- Adding new checklists for everything instead of tightening the few that matter
- "Process theater": changes that look good but don't prevent the actual failure

## Minimal Output Standard (End of Session)

If you made any system improvement:
- Mention what changed and why (1–2 sentences)
- Point to the artifact changed (file path)
- If you proposed something, leave the proposal in the conversation (and optionally a note in `PLAN.md`)
