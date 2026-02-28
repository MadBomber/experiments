---
name: smart-review
description: Performs thorough code review on git changes. Analyzes diffs for bugs, security issues, performance problems, and design concerns. Produces actionable feedback organized by severity. Use when reviewing code, checking a PR, or when the user says /smart-review.
license: MIT
compatibility: Requires git
metadata:
  author: bmobot
  version: "1.0"
---

# Smart Code Review

Perform thorough, actionable code reviews on git changes. Catches real bugs and security issues, not just style nits.

## When to Activate

- User asks to review code changes
- User says `/smart-review` or "review my code" or "check this PR"
- User wants feedback before committing or merging

## Instructions

### Step 1: Determine Review Scope

Identify what to review based on user context:

```bash
# Option A: Review uncommitted changes
git diff --stat
git diff

# Option B: Review staged changes
git diff --cached --stat
git diff --cached

# Option C: Review branch vs base (PR review)
BASE_BRANCH="${1:-main}"
git log --oneline "$BASE_BRANCH"..HEAD
git diff --stat "$BASE_BRANCH"..HEAD
git diff "$BASE_BRANCH"..HEAD

# Option D: Review a specific commit
git show --stat <commit>
git show <commit>
```

If no changes are found, inform the user and stop.

For large diffs (>500 lines changed), read key files individually rather than relying solely on the diff — context from surrounding code matters.

### Step 2: Analyze for Issues

Review the diff systematically, checking each category:

#### Critical (Must Fix)
- **Bugs**: Logic errors, off-by-one, null/undefined access, race conditions, infinite loops
- **Security**: SQL injection, XSS, command injection, hardcoded secrets, path traversal, insecure deserialization
- **Data loss**: Destructive operations without confirmation, missing error handling on writes, uncaught exceptions that could corrupt state

#### Important (Should Fix)
- **Error handling**: Missing try/catch on I/O, swallowed errors, generic catch blocks that hide failures
- **Edge cases**: Empty arrays, null inputs, boundary values, concurrent access, timeout handling
- **API contracts**: Breaking changes to public interfaces, missing validation on inputs, inconsistent return types
- **Resource management**: Unclosed connections, memory leaks, missing cleanup in finally blocks

#### Suggestions (Consider)
- **Performance**: N+1 queries, unnecessary re-renders, large allocations in hot paths, missing indexes
- **Maintainability**: Complex conditionals that could be simplified, duplicated logic, unclear variable names
- **Testing**: Untested code paths, assertions that don't verify the right thing, flaky test patterns
- **Design**: Tight coupling, mixed responsibilities, patterns that will cause pain as the codebase grows

### Step 3: Read Surrounding Context

For each potential issue found in Step 2, read the full file to verify:

```bash
# Don't flag something as a bug if the surrounding code handles it
# Don't flag a "missing null check" if the caller guarantees non-null
# Don't flag a performance issue if the data set is always small
```

**Key principle**: Only flag issues you're confident about. A false positive wastes the developer's time and erodes trust. When in doubt, phrase it as a question rather than a finding.

### Step 4: Generate Review

Organize findings by severity. Use this template:

```markdown
## Code Review

**Scope**: [what was reviewed — branch, commits, or staged changes]
**Files**: [number] files, [additions] insertions(+), [deletions] deletions(-)

### Critical

> [file:line] **Issue title**
>
> [Explanation of the problem and its impact]
>
> ```diff
> - [current code]
> + [suggested fix]
> ```

### Important

> [file:line] **Issue title**
>
> [Explanation and suggestion]

### Suggestions

> [file:line] **Issue title**
>
> [Explanation and suggestion]

### What Looks Good

- [Positive callout — something done well]
- [Another positive callout]

### Summary

**Verdict**: Ready to merge / Needs minor fixes / Needs rework

[1-2 sentence overall assessment explaining the verdict]
```

### Step 5: Present and Discuss

1. Show the review to the user
2. Offer to fix any Critical or Important issues directly
3. If reviewing a PR, offer to post the review as a comment via `gh pr review`

## Review Principles

1. **Be specific**: "This could fail when X is null" > "Consider null checks"
2. **Explain impact**: "This SQL is injectable, allowing data exfiltration" > "Security issue"
3. **Suggest fixes**: Show code, not just descriptions. Make it easy to act on.
4. **Acknowledge good work**: Call out clean patterns, good test coverage, clever solutions
5. **Respect intent**: Understand what the developer was trying to do before suggesting alternatives
6. **Prioritize**: A review with 3 real issues beats one with 30 style nits
7. **Skip the obvious**: Don't flag formatting, naming conventions, or import ordering unless they cause actual confusion

## Severity Guide

| Severity | Criteria | Examples |
|----------|----------|---------|
| Critical | Will cause bugs, security holes, or data loss in production | SQL injection, uncaught exception in payment flow, race condition on shared state |
| Important | Could cause problems under certain conditions, or makes future bugs likely | Missing error handling on network call, breaking API change without migration |
| Suggestion | Improvement that would make the code better but isn't urgent | Extracting a helper function, adding an index, simplifying a conditional |

## Edge Cases

- **Trivial changes** (typos, formatting): Skip the formal review format, just confirm it looks good
- **Generated code** (migrations, lockfiles): Note that it's generated and focus only on the generator config
- **Dependency updates**: Check the changelog for breaking changes, verify version constraints
- **Large refactors**: Focus on the design rather than line-by-line — does the new structure make sense?
- **First contribution**: Be extra welcoming. Suggest improvements gently and acknowledge the effort
