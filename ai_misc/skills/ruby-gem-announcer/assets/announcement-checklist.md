# Release Announcement Checklist

Use this checklist before publishing a release announcement for a Ruby gem or CLI utility.

## Pre-Writing

- [ ] **Version number determined** – What's the new version? When was it released?
- [ ] **Change list compiled** – Breaking changes? New features? Fixes? Dependencies?
- [ ] **Code examples ready** – Can you show actual working code for each major change?
- [ ] **Migration plan clear** – Do users need to migrate? Have you tested the migration?
- [ ] **Target audience defined** – Who is this gem/CLI for? Who will be affected by changes?

## Structure

- [ ] **Opening paragraph includes:**
  - [ ] Software name and version number
  - [ ] One sentence: "What is this?" (not what it aspires to be)
  - [ ] Clarity on scope: "This release focuses on..."
  - [ ] What the reader will learn: "This post covers..."

- [ ] **Breaking changes section (if any):**
  - [ ] Listed explicitly in the announcement, near the top
  - [ ] Before/after code examples for each breaking change
  - [ ] Migration tool or step-by-step instructions provided
  - [ ] Old features explicitly named with replacement (if any)
  - [ ] Rationale: Why was the break necessary?

- [ ] **New features/improvements:**
  - [ ] Each has a clear heading
  - [ ] One sentence problem-statement or capability
  - [ ] Actual code example showing real usage
  - [ ] Explanation of why developers would use this
  - [ ] Any limitations or edge cases named

- [ ] **Getting started section:**
  - [ ] Install command: `gem install X` or `brew install X`
  - [ ] Verify command with expected output
  - [ ] Ruby version requirement stated
  - [ ] Required dependencies listed
  - [ ] Link to full documentation

- [ ] **Resources section at end:**
  - [ ] GitHub repository URL
  - [ ] Documentation site (if separate)
  - [ ] How to report issues/feedback
  - [ ] Changelog link (if separate from announcement)

## Language & Tone

- [ ] **No hyperbole:**
  - [ ] "Revolutionary" or "game-changing"? Replace with what it actually does
  - [ ] "Best-in-class"? State the specific capability instead
  - [ ] "Powerful"? Show the power with examples
  - [ ] "Unlimited"? State actual tested limits
  - [ ] "Always"? Qualify with "usually" or "often enough that..."

- [ ] **Specific over vague:**
  - [ ] "Easier"? → "Can now do X with Y syntax instead of Z"
  - [ ] "Faster"? → "Measured X% improvement on benchmark Z with setup A"
  - [ ] "Better"? → "Now handles case X, previously crashed"
  - [ ] Numbers, versions, limits included where claimed

- [ ] **Code examples actual:**
  - [ ] Are examples copy-pasteable and runnable?
  - [ ] Do they show realistic parameters?
  - [ ] Do they include realistic output?
  - [ ] For CLI tools, shown with actual command-line formatting?

- [ ] **Trade-offs named:**
  - [ ] Architectural choices explained: "X costs Y but gains Z"
  - [ ] Performance: What got better? What got trade-offs?
  - [ ] Compatibility: What versions of Ruby/gems/systems supported?
  - [ ] Honest limitations acknowledged: "Not always, but often..."

## Personal Voice (Optional)

- [ ] If included, "Why I use it" section:
  - [ ] Speaks from actual personal experience
  - [ ] Names real problems solved
  - [ ] Acknowledges that not all use cases fit
  - [ ] No marketing language

## Final Read-Through

- [ ] **Read as a developer seeing this for the first time:**
  - [ ] Can I understand what this software does?
  - [ ] What breaks from my current version?
  - [ ] How do I actually use the new features?
  - [ ] What does it cost me (in terms of migration, dependencies, breaking changes)?
  - [ ] Where do I go for help?

- [ ] **Tone check:**
  - [ ] Does it feel honest?
  - [ ] Would I believe these claims?
  - [ ] Are facts supported by examples or numbers?
  - [ ] Any claims I wouldn't make about competing software?

- [ ] **Proofread:**
  - [ ] Code examples syntax-correct
  - [ ] Version numbers consistent throughout
  - [ ] Links working (test before publishing)
  - [ ] Before/after examples aligned

## After Publishing

- [ ] **Announce in appropriate channels:**
  - [ ] GitHub releases
  - [ ] RubyGems.org (automatically if using GitHub Actions)
  - [ ] Ruby newsletter / community forum (if significant release)
  - [ ] Social media (LinkedIn, Twitter) with link
  - [ ] Your blog/personal site

- [ ] **Link bidirectionally:**
  - [ ] Blog post links to gem on RubyGems
  - [ ] GitHub release links to blog post
  - [ ] GitHub README links to announcement for major version
