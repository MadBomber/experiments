# Structure for Software Version Announcements

This reference provides a tested structure for announcing new Ruby gem and CLI utility versions that readers will actually find useful and believable.

## Opening Paragraph

**Formula:**
- State the software name and version clearly
- One sentence describing *what* it is (not what it aspires to be)
- One sentence about the origin or journey (if substantive)
- One sentence stating purpose: "This post covers..."

**Example:**
> AIA (AI Assistant) hit version 1.0.0 on February 22, 2026. It started in 2023 as a Ruby script called aip.rb that piped prompts into mods. Three years later, it talks to hundreds of models across dozens of providers, runs multiple models concurrently, and connects to MCP servers for tool access. This post covers what changed, what's new, and how to migrate.

**Rationale:** Readers immediately know: name, version number, concrete scope, and what they'll learn.

## Quick Summary (Optional)
If the announcement is complex, provide a one-paragraph summary of key facts before diving into details.

## Breaking Changes (If Any)

**Always come early and be explicit.** Users need to know before investing time in reading.

**Structure:**
1. Summarize what changed in one sentence
2. Show before/after comparisons when helpful
3. Provide migration tools or step-by-step guides
4. Include example of the migration tool in action
5. List removed features clearly with why

**Example:**
> Prompts are now .md files with YAML front matter instead of .txt files with sidecar .json metadata.

## What's New

**Structure for each new feature/capability:**
1. Clear feature name (heading)
2. Problem it solves or capability it enables (1-2 sentences)
3. Code example showing actual usage
4. Explanation of what the code does and why you'd use it
5. Any relevant configuration or limitations

**Avoid:**
- Saying "this is cool" or "we're excited about"
- Comparing to competitors
- Claiming this is obvious or standard (if it was, you wouldn't need to explain it)

**Include:**
- Real command line usage or code
- What you can actually do with it
- Edge cases that matter
- Performance characteristics when relevant

## Security, Performance, or Quality Improvements

**For each improvement:**
1. What was fixed or improved
2. Why it matters (impact statement, not emotion)
3. If it changes user behavior, give the concrete change

**Example:**
> v1.0.0 fixes real security problems: backtick shell interpolation is replaced with safe array-form process execution, tempfile handling for audio is hardened, exception rescues are narrowed, and critical dependencies are pinned.

## Installation / Getting Started

**Always include:**
- Exact command: `gem install X`
- Version verification command and expected output
- Ruby version requirements
- Any dependencies
- Link to full documentation

**Example:**
```
gem install aia

# Verify
aia --version
# 1.0.0

# Requirements
Requires: ruby >= 3.0, async gem
```

## Why I Use It (Personal Motivation)

This section is optional but highly credible. Speaking from personal experience as a developer using the software builds trust.

**Structure:**
1. What problem led to building this
2. How you actually use it
3. What surprised you in actual use
4. Honest trade-offs or caveats

**Example:**
> For personal use, I replaced browser search. I keep an AIA chat session in a terminal tab. No ads, no sponsored results, no clicking through five SEO-optimized pages to find a one-line answer. I just ask.

## Related Resources

**Always include at end:**
- GitHub repository link
- Full documentation site (if separate)
- Direct install command
- Changelog or migration guide link
- Communication channel for feedback (issues, email, etc.)

## Tone Guidelines

1. **Write in imperative/infinitive form:** "To do X, do Y" not "You should do X"
2. **Use "I" only when sharing personal experience:** Not "I think this is great" but "I use this daily for..."
3. **Be specific with numbers, versions, and limits:** No "faster" without benchmarks
4. **Acknowledge trade-offs:** Name both sides of architectural choices
5. **Let the software speak through examples:** More code, fewer adjectives
6. **Avoid exclamation marks except after commands:** "Run `gem install aia`!"

## For Different Software Types

### Ruby Gems
- Lead with what the gem does (library functionality)
- Show API changes prominently
- Include dependency version requirements
- Explain any C extensions or native requirements

### CLI Utilities
- Lead with new commands or flags
- Show example terminal sessions
- Include `--help` output if significantly changed
- Explain environment variable changes

### Both
- State minimum Ruby version required
- Link to installation from the announcement (not just docs)
- Explain upgrade path (in-place safe, requires migration, breaking changes)
