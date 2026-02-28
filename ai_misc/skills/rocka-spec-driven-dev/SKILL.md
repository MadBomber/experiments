---
name: spec-driven-dev
description: Structured software development workflow that moves from specification through planning and review to test-driven implementation. Creates specs, breaks work into stories, defines test contracts, reviews plans with a devil's advocate agent, and builds features test-first. Use when building a new feature, refactoring a module, or when the user says /spec-dev.
license: MIT
compatibility: Requires git
metadata:
  author: bmobot
  version: "1.0"
---

# Spec-Driven Development

A structured workflow that takes features from idea to implementation through four phases: Specify → Plan → Review → Build.

## When to Activate

- User wants to build a new feature or significant change
- User says `/spec-dev` or "let's build this properly"
- User wants a structured approach to development
- A task is complex enough to benefit from upfront planning

## Why This Workflow

Most AI coding goes wrong in the same way: jumping straight to code without understanding what to build, then burning context fixing design mistakes that planning would have caught.

This workflow prevents that by:
1. **Specifying** what to build before writing any code
2. **Planning** the implementation as testable stories
3. **Reviewing** the plan with a fresh perspective (catches 80% of design issues)
4. **Building** test-first so you know when you're done

## Instructions

### Phase 1: Specify (`/spec-dev spec`)

Create a clear specification document.

**Gather requirements:**
- What problem does this solve?
- Who uses it and how?
- What are the inputs, outputs, and edge cases?
- What are the constraints (performance, compatibility, security)?
- What does "done" look like?

**Write the spec:**

Create `specs/{feature-name}.md`:

```markdown
# Feature: {Name}

## Problem
[What problem does this solve and why does it matter?]

## Solution
[High-level description of the approach]

## Requirements

### Functional
- [ ] [Specific, testable requirement]
- [ ] [Another requirement]

### Non-Functional
- [ ] [Performance target, if any]
- [ ] [Security constraints, if any]

## User Stories
- As a [role], I want [action] so that [benefit]

## Edge Cases
- [What happens when X?]
- [What about empty/null/concurrent inputs?]

## Out of Scope
- [Explicitly list what this does NOT include]

## Open Questions
- [Anything that needs clarification before building]
```

**Output**: Confirm the spec with the user. Resolve any open questions before proceeding.

### Phase 2: Plan (`/spec-dev plan`)

Break the spec into implementable stories with test contracts.

**Create stories:**

Each story is a small, independently testable unit of work:

```markdown
## Story 1: {Title}

**Description**: [What this story implements]
**Files**: [Which files will be created or modified]

### Acceptance Criteria
- [ ] [Specific, verifiable criterion]
- [ ] [Another criterion]

### Test Contract
```
Test: {test description}
Given: {precondition}
When: {action}
Then: {expected result}
```

### Dependencies
- Depends on: [other stories, if any]
- Blocks: [stories that need this first]
```

**Order stories** so each builds on the last. Earlier stories should establish foundations (types, interfaces, utilities). Later stories add behavior.

**Create the plan:**

Create `plans/{feature-name}.md`:

```markdown
# Plan: {Feature Name}

**Spec**: specs/{feature-name}.md
**Stories**: {count}
**Estimated complexity**: Low / Medium / High

## Architecture Notes
[Key design decisions, patterns used, rationale]

## Story Order
1. {Story 1 title} — {one-line summary}
2. {Story 2 title} — {one-line summary}
...

## Stories
[Full story details as above]

## Risk Areas
[Parts of the plan that might need adjustment during build]
```

### Phase 3: Review (`/spec-dev review`)

Before building, get a second opinion. This catches overcomplexity, missed edge cases, and simpler alternatives.

**Devil's advocate review:**

Spawn a sub-agent (using the Task tool) with this prompt:

```
Review this implementation plan. You are a skeptical senior engineer.
Challenge the approach:

1. Is anything overcomplicated? Could it be simpler?
2. Are there missed edge cases or failure modes?
3. Does the story order make sense?
4. Are the test contracts actually testing the right things?
5. Is anything missing from the spec that the plan assumes?

Be specific. If you'd do something differently, say what and why.

Verdict: GO (plan is solid) or PAUSE (fix these issues first)

[paste plan content]
```

**If PAUSE**: Revise the plan based on feedback, then re-review.
**If GO**: Proceed to build.

### Phase 4: Build (`/spec-dev build`)

Implement stories in order, test-first.

**For each story:**

1. **Write tests first** based on the test contract
2. **Run tests** — they should fail (red)
3. **Implement** the minimum code to pass
4. **Run tests** — they should pass (green)
5. **Refactor** if needed (keeping tests green)
6. **Commit** with a clear message referencing the story

```bash
# Example commit
git commit -m "feat: add rate limiter middleware (story 3/7)

Implements token bucket algorithm with configurable
limits per route. Tests cover burst, sustained, and
reset scenarios."
```

**Key rules during build:**
- Tests define the contract — don't modify tests to make them pass
- If a test is wrong, stop and discuss with the user
- Each story should leave the codebase in a working state
- Don't skip ahead — story order exists for a reason

**After all stories complete:**

1. Run the full test suite
2. Verify all spec requirements are met (checklist)
3. Check for any regressions
4. Summarize what was built

## Quick Commands

| Command | Phase | Description |
|---------|-------|-------------|
| `/spec-dev spec` | Specify | Create or update a spec |
| `/spec-dev plan` | Plan | Create implementation plan from spec |
| `/spec-dev review` | Review | Devil's advocate review of plan |
| `/spec-dev build` | Build | Implement stories test-first |
| `/spec-dev status` | Any | Show current phase and progress |

## File Structure

```
specs/
  feature-name.md          # Specification
plans/
  feature-name.md          # Implementation plan with stories
tests/
  feature-name/            # Tests written during build
```

## When NOT to Use This

- **Quick fixes**: Typos, one-line bugs, config changes — just do them
- **Exploration**: If you're not sure what to build yet, explore first
- **Under 30 lines**: If the total change is small, skip the ceremony

The overhead of this workflow pays for itself on features that are medium complexity or higher — roughly anything that touches 3+ files or takes more than 15 minutes.

## Tips

- **Specs are living documents**: Update them when requirements change
- **Stories can be adjusted**: If you discover a better approach during build, update the story (but not the tests)
- **Review is not optional**: The 5 minutes spent on review saves 30 minutes of rework
- **Small stories > big stories**: If a story takes more than 30 minutes, it's too big — split it
