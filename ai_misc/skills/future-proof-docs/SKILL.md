---
name: future-proof-docs
description: This skill should be used during all code development work to maintain future-proof documentation practices. It ensures code comments explain "why" not "what," maintains a DECISIONS.md log of architectural and design decisions, keeps a SCRATCHPAD.md session journal for context continuity, and treats the README as an operational runbook. This skill activates proactively during normal coding, not only when documentation is explicitly requested.
---

# Future-Proof Docs

## Overview

Prevent "Context Bankruptcy" — the state where returning to code after weeks or months
means zero memory of why decisions were made. This skill integrates four documentation
practices into the standard development workflow, treating documentation as self-care
rather than a chore.

## Core Practices

### 1. Comment Quality — "Why" Over "What"

When writing or reviewing code comments, enforce this principle:

- **Never** comment what the code does when the code already says it. `# Increment counter` above `counter += 1` is noise.
- **Always** comment invisible constraints: business rules, upstream quirks, performance reasons, workarounds for known bugs.
- **Always** comment non-obvious intent: why this approach was chosen over the simpler-looking alternative.

**Bad:**
```ruby
# Set timeout to 5000ms
timeout = 5000
```

**Good:**
```ruby
# Stripe webhook occasionally hangs ~4s during their nightly maintenance window (midnight-1am UTC).
# 5s timeout prevents job queue backup while still tolerating the slow responses.
timeout = 5000
```

When encountering existing "what" comments during code work, improve them to "why" comments or remove them if the code is self-evident.

### 2. DECISIONS.md — The Decision Log

Maintain a `DECISIONS.md` file at the project root. Log entries when:

- Choosing between competing approaches or libraries
- Making architectural decisions (database choice, API design, file structure)
- Deliberately choosing a non-obvious approach
- Overriding a convention for a specific reason

To create or update DECISIONS.md, use the template in `references/DECISIONS_TEMPLATE.md`.

**Proactive behavior:** After making or implementing a significant design decision during coding work, prompt to record it in DECISIONS.md. A decision is "significant" if future-you might look at the code and wonder "why did I do it this way?"

### 3. SCRATCHPAD.md — The Session Journal

Maintain a `SCRATCHPAD.md` file at the project root. Update it:

- At the end of a work session — capture what was done, where things stand, and what comes next
- When context is complex enough that picking it back up later would take real effort

To create or update SCRATCHPAD.md, use the template in `references/SCRATCHPAD_TEMPLATE.md`.

**Proactive behavior:** When a session involves substantial work (multiple files touched, decisions made, problems debugged), suggest updating SCRATCHPAD.md before wrapping up. The goal is to eliminate the "ramp-up tax" of the next session.

### 4. README as Emergency Manual

Treat the README as an operational runbook, not a project description. It should answer: "What do I type to make this work?"

When creating or significantly updating a README, follow the structure in `references/README_RUNBOOK_TEMPLATE.md`. Prioritize:

- Commands over prose
- Quick-start path from clone to running
- Deployment steps and environment variables
- Troubleshooting known issues

Link to DECISIONS.md for architectural reasoning rather than duplicating it in the README.

## Workflow Integration

These practices are part of the standard development process, not separate documentation tasks.

### During coding:
- Write "why" comments naturally as code is written
- When a design decision is made, log it in DECISIONS.md

### When wrapping up:
- Update SCRATCHPAD.md with session state
- If deployment steps changed, update the README

### When starting a new project:
- Scaffold all four artifacts: meaningful code comments, DECISIONS.md, SCRATCHPAD.md, and a runbook-style README

### When returning to a project:
- Read SCRATCHPAD.md first to restore context
- Check DECISIONS.md before refactoring — the "weird" choice may have been deliberate

## Resources

### references/

Templates for the three documentation files:

- `references/DECISIONS_TEMPLATE.md` — Structure and example for the decision log
- `references/SCRATCHPAD_TEMPLATE.md` — Structure and example for the session journal
- `references/README_RUNBOOK_TEMPLATE.md` — Structure and guidance for the operational README
