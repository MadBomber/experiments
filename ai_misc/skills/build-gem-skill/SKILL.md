---
name: build-gem-skill
description: "Generate, verify, cache, and link version-specific SKILL.md files for Ruby gems into ~/.gem/skills/<gem>/<version>/, the same way the gem-skill gem does but with Claude writing the skill instead of a separate LLM API call. Use when the user asks to build/generate/create a skill for a Ruby gem, build skills for every gem in a Gemfile.lock, refresh or verify gem skills, or list/purge the ~/.gem/skills cache."
argument-hint: "GEM [GEM...] | --bundle | --refresh | verify GEM... | list | purge GEM (VERSION|--all)  [--force] [--verify]"
---

# build-gem-skill

This skill does what the `gem-skill` gem (`gem skill …` / `bundle skill …`) does, with you as the LLM.
The deterministic parts go through the helper script, so the result is byte-compatible with
the gem: the same cache layout, frontmatter rules, `metadata.json`, and project symlinks. The
existing `ruby-gem-skills` router skill and `gem skill list` both read what this skill writes.

```
H=~/.claude/skills/build-gem-skill/scripts/gem_skill.rb   # every command prints JSON; errors go to stderr, exit 1
```

| Command | Purpose |
|---|---|
| `ruby $H resolve GEM [VERSION]` | installed version, `gem_dir`, whether it's already cached |
| `ruby $H sources GEM VERSION` | write the doc sources (metadata, README, CHANGELOG, examples) to a temp file |
| `ruby $H source-code GEM VERSION` | write `lib/**/*.rb` to a temp file for verification (`verifiable: false` if not installed) |
| `ruby $H store GEM VERSION DRAFT --model M --sources a,b` | strip wrapper fence, build frontmatter, write SKILL.md + metadata.json |
| `ruby $H apply-verify GEM VERSION FILE --model M` | diff-based "changed", rewrite if needed, record verification in metadata |
| `ruby $H apply-verify GEM VERSION --unverifiable --model M` | record "no installed source available" |
| `ruby $H link GEM VERSION [--project DIR]` | symlink `<project>/.claude/skills/<gem>` → cache dir |
| `ruby $H lockfile [PATH]` | direct dependencies `{name: version}` from Gemfile.lock |
| `ruby $H status [--project DIR]` | per lockfile gem: `cached`, `linked_current` |
| `ruby $H prune [--project DIR]` | remove dead skill symlinks |
| `ruby $H list` / `ruby $H purge GEM (VERSION\|--all)` | cache management |

Environment variables are the same as the gem's: `GEMSKILL_DIR` (cache root, default `~/.gem/skills`)
and `GEMSKILL_PROJECT_DIR` (default `.claude/skills`, e.g. `.agents` for Codex).
`--model` is the id **you** are running as (e.g. `claude-opus-5-5`). It's recorded in `metadata.json`.

## Modes (parse from the user's request / arguments)

| Request | Gem equivalent | Do |
|---|---|---|
| `GEM [GEM...]` | `gem skill install` | Single-gem procedure for each named gem |
| `--bundle` | `bundle skill install` | `ruby $H lockfile`, run the procedure for every direct dependency using the **locked** version |
| `--refresh` | `bundle skill refresh` | `ruby $H status`, then run the procedure only for gems where `linked_current` is false, then `ruby $H prune` |
| `verify GEM...` | `gem skill verify` | Verify procedure only. The gem must be installed and the skill already cached. Otherwise stop and say which command to run first |
| `list` | `gem skill list` | `ruby $H list`. Show `gem  version ✓` (✓ = verified) |
| `purge GEM VERSION` / `purge GEM --all` | `gem skill purge` | Confirm with the user first, then `ruby $H purge …` |

Flags: `--force` regenerates even when cached. `--verify` runs the verify pass after generating.

## Single-gem procedure

1. **Resolve.** `ruby $H resolve GEM [VERSION]`.
   - Named-gem mode: if `installed` is false, run `gem install GEM` (the gem auto-installs too),
     then resolve again. If the install fails, report it and skip this gem.
   - Bundle mode: use the lockfile version. Don't install anything. If the gem isn't in the
     active Ruby, the helper falls back to RubyGems/GitHub docs, and verification will be `--unverifiable`.
     In a project with its own Ruby, run the helper as `bundle exec ruby $H …` from the project root
     so Bundler's gem paths are visible (check with `ruby-version-manager` if unsure).
2. **Cached?** If `cached` is true and there's no `--force`, skip generation and go to step 5 (link),
   then step 6 if `--verify`.
3. **Gather.** `ruby $H sources GEM VERSION`, then Read the whole `path` it returns. Note the
   `sources` list. An error meaning "No documentation found" fails this gem.
4. **Generate.** Read `references/generate.md` and follow it exactly. Write the draft to a
   temp file (e.g. `$TMPDIR/build-gem-skill/GEM-VERSION-draft.md`), then:
   `ruby $H store GEM VERSION DRAFT --model <your-model-id> --sources <comma list from step 3>`
5. **Link.** If the current directory is a project (it has a Gemfile, `.git`, or `.claude/`),
   run `ruby $H link GEM VERSION`. The gem always links into the cwd. Skip linking only when the
   cwd is clearly not a project (e.g. `$HOME`), and say you skipped it.
6. **Verify** (only with `--verify` or in `verify` mode):
   `ruby $H source-code GEM VERSION`.
   - `verifiable: false` → `ruby $H apply-verify GEM VERSION --unverifiable --model <id>`, report "no source to verify".
   - Otherwise read `references/verify.md` and follow it: read the cached SKILL.md and the source file,
     write the full corrected skill to a temp file, and run `ruby $H apply-verify GEM VERSION FILE --model <id>`.
     Report `verified — fixed` or `verified — ok` from the helper's `changed` value.
7. Delete that gem's temp files under `$TMPDIR/build-gem-skill/`.

## Many gems

The gem generates skills concurrently. Do the same: when there are more than two gems to generate
or verify, launch one subagent per gem (general-purpose, in a single message, about 5 at a time).
Give each one the gem, version, mode, flags, and your model id, and tell it to follow
`~/.claude/skills/build-gem-skill/SKILL.md` "Single-gem procedure" and return one status line. This also
keeps several large README/source files out of your own context. For one or two gems, do the work yourself.

## Report

Finish with one line per gem, matching the gem's spinner states:
`rake 13.4.2 — done | already cached | verified — ok | verified — fixed | done (no source to verify) | failed: <reason>`,
plus the cache path. If any `--verify` applied fixes, say how many skills were corrected against source.
If this machine doesn't have the `ruby-gem-skills` router skill in `~/.claude/skills/`, mention that `gem skill setup`
installs it, so skills cached globally are discoverable outside linked projects.
