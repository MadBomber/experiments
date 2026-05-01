---
name: ruby-gem-announcer
description: This skill should be used when writing or editing public announcements of new versions for Ruby gems and command-line utilities. It provides structured guidance for crafting authentic release announcements that use honest facts instead of marketing hyperbole, ensuring readers trust the software's actual capabilities.
license: MIT
---

# Ruby Gem & CLI Announcer

## Purpose

This skill helps write credible, factual software version announcements for Ruby developers. Instead of superlatives and marketing claims, announcements focus on what the software actually does, demonstrates concrete usage, and honestly describes changes.

The result: announcements that developers find useful and believe.

## When to Use This Skill

Use this skill when:

- Writing a blog post or release notes announcing a new gem or CLI utility version
- Announcing breaking changes that require user migration
- Sharing feature additions with code examples and real use cases
- Explaining security fixes or performance improvements with concrete details
- Deciding what information belongs in an announcement and what doesn't

## How to Use This Skill

### Step 1: Understand What Actually Changed

Before writing, gather facts about the new release:

- **Version number and date** – State these clearly
- **Breaking changes** – List explicitly with before/after examples
- **New features** – Have actual code examples ready
- **Bug fixes / security improvements** – Know what was fixed and why it matters
- **Dependencies** – What changed in required gems, Ruby version, or other requirements?
- **Migration path** – Is there a tool to help? Manual steps?

This skill is most useful when you have these facts documented first. If you're still clarifying what changed, start there.

### Step 2: Structure the Announcement

Follow the structure in `references/announcement-structure.md`. The pattern:

1. **Opening**: Name, version, one sentence what-it-is, one sentence why readers should care
2. **Breaking Changes** (if any): Explicit list with before/after examples
3. **What's New**: Feature-by-feature with code and use cases
4. **Getting Started**: Install command, verify, requirements, docs link
5. **Personal Context** (optional): Your honest take on why you built/use this
6. **Resources**: Repo, docs, feedback channel

### Step 3: Avoid Hyperbole

Consult `references/hyperbole-patterns.md` when you catch yourself:

- Using superlatives ("revolutionary," "best-in-class," "powerful")
- Making unsubstantiated claims about speed or capability
- Using emotional language instead of technical description
- Being vague ("easier," "better") without concrete examples

**Replace with:**

- **Specific facts**: Version numbers, test counts, supported platforms, token costs
- **Code examples**: Show how developers actually use it
- **Use cases**: Real problems it solves (drawn from personal experience if possible)
- **Honest trade-offs**: "No mutexes" costs synchronization primitives; name both sides
- **Concrete numbers**: Benchmarks, limits, tested scales – not adjectives

### Step 4: Demonstrate with Examples

- Include actual code that runs
- Show command-line output as it appears
- Demonstrate before/after for breaking changes
- Use parameters and configurations that developers actually pass

## Writing Style

Write in **imperative/infinitive form** (verb-first instructions), not second person:

- **Better**: "To install, run `gem install my_gem`"
- **Avoid**: "You can install by running..."

Use **specific technical language**, not marketing:

- **Better**: "Fiber-based pub/sub message bus with explicit ACK/NACK delivery semantics"
- **Avoid**: "Revolutionary messaging solution"

**Be honest about limitations:**

- Not always, but often...
- Tested with X concurrent Y, bounded by...
- Compatible with Z, requires Ruby 3.0+...

**Focus on capability, not emotion:**

- Name what the software does
- Show how to use it
- Explain why that matters
- Don't claim credit for excellence – let the code speak

## Key References

- `references/hyperbole-patterns.md` – Specific patterns to replace with factual alternatives
- `references/announcement-structure.md` – Full template with examples from actual releases

Both files are loaded as-needed and intended to be consulted during writing, not memorized.

## Examples

See the author's blog at https://madbomber.github.io/blog/ for real announcements that follow this pattern:

- "What's New in AIA v1.0.0" – Large release with breaking changes
- "Introducing TypedBus" – New gem with features and use cases
- Both use concrete code examples, breaking changes clearly stated, and honest assessment of use cases
