# Development Guidelines

## Philosophy

- **Incremental progress** — small changes that compile and pass tests
- **Learn before implementing** — study existing patterns, find 3 similar features
- **Pragmatic over dogmatic** — adapt to project reality
- **Clear intent over clever code** — boring and obvious wins
- **Ask when uncertain** — if confidence < 100%, ask clarifying questions before coding

### Core Principles

| Principle | Meaning                         | Violation Sign                     |
| --------- | ------------------------------- | ---------------------------------- |
| **KISS**  | Simplest solution that works    | "Let me explain how this works..." |
| **YAGNI** | Build only what's needed now    | "We might need this later..."      |
| **DRY**   | Single source of truth          | Copy-pasting with minor changes    |
| **SOLID** | Modular, replaceable components | God classes, tight coupling        |

**Anti-overengineering checklist:**

- Can this be solved without a new abstraction?
- Am I building for today's requirements or imaginary future?
- Would a junior understand this in 5 minutes?

## Process

### Planning

Break complex work into 3-5 stages. Document in `IMPLEMENTATION_PLAN.md`:

```
## Stage N: [Name]
Goal: [Specific deliverable]
Success Criteria: [Testable outcomes]
Status: [Not Started|In Progress|Complete]
```

### Implementation: Red-Green-Refactor

**CRITICAL CHECKPOINT** — Before writing ANY production code, ask yourself:
"Do I have a failing test for this behavior?"
If NO → Write the test FIRST. No exceptions.

Strict TDD cycle for every change:

1. **Red** — write failing test that defines expected behavior
2. **Green** — write minimal code to pass (no more)
3. **Refactor** — improve structure with tests green

Do not skip steps. Do not write production code without a failing test.

**VIOLATION TRIGGERS** (these actions REQUIRE a failing test first):

- Creating new controller/model/service → TEST FIRST
- Adding new method to existing class → TEST FIRST
- Fixing a bug → Write failing test that reproduces bug FIRST
- Any "приступи к разработке" / "start implementing" → means "start with tests"

### Handoff for Review

After implementation is complete, present work for human review:

1. **Summary** — what was done and why
2. **Changes list** — files modified/created/deleted
3. **Test results** — confirmation all tests pass
4. **Open questions** — if any remain

After human approves, provide:

1. **Changelog entry** — user-facing description of changes
2. **Commit message** — conventional format: `<type>: <description>`

Human commits code to repository.

### When Stuck (Max 3 Attempts)

After 3 failed attempts, STOP and:

1. Document what failed and specific errors
2. Research 2-3 alternative approaches
3. Question fundamentals: right abstraction? simpler approach?
4. Try different angle or remove abstraction

## Technical Standards

### Architecture

- Composition over inheritance
- Interfaces over singletons
- Explicit over implicit
- Dependencies injected, not hardcoded

### Git Conventions

- **Rebase-first**: rebase feature onto master, then fast-forward merge
- **Squash on completion**: single commit per feature
- **Conventional commits**: `<type>: <description>` (feat/fix/docs/refactor/test/chore)

### Quality Gates (All Must Pass Before Review)

- All tests pass
- Linter: 0 offenses
- Security scanner: no warnings
- No missing translations (if applicable)
- No dependency vulnerabilities

### Code Quality

Every change must:

- Compile successfully
- Pass all existing tests
- Include tests for new functionality
- Follow project conventions

### Naming

Never use numbered variables. Use descriptive, role-based, or context-based names.

### Error Handling

- Fail fast with descriptive messages
- Include context for debugging
- Handle at appropriate level
- Never silently swallow exceptions

## Decision Framework

When multiple approaches exist, prioritize:

1. **Testability** — can I easily test this?
2. **Readability** — understandable in 6 months?
3. **Consistency** — matches project patterns?
4. **Simplicity** — simplest solution that works?
5. **Reversibility** — how hard to change later?

## Definition of Done

- [ ] Tests written and passing
- [ ] Code follows project conventions
- [ ] No linter warnings
- [ ] Implementation matches plan
- [ ] No TODOs without issue references
- [ ] Changes presented for human review
- [ ] Changelog and commit message prepared

## Rules

**NEVER**: `--no-verify`, disable tests, commit code directly, assume without verifying, build for imaginary requirements, write production code before failing test

**ALWAYS**: ask if unsure, present work for review, update documentation, learn from existing code, stop after 3 failures, prefer deletion over addition, **TDD by default** (unless explicitly told otherwise)

Use relative paths. Comments in English.
