# Verifying a gem SKILL.md against source

This is the same brief as gem-skill's `Verifier`. It's a second pass that checks a cached
skill against the gem's **actual installed source code**.

## Inputs

- The cached skill: `~/.gem/skills/<gem>/<version>/SKILL.md` (or under `$GEMSKILL_DIR`).
- The source bundle written by `gem_skill.rb source-code` (all of `lib/**/*.rb`, whole files,
  capped at 150,000 chars). If `truncated` is true, open any other `lib/` files you need
  directly under `gem_dir`.

## Rules

The source code is the only source of truth. READMEs, changelogs, and docstrings are
frequently stale or wrong. When the SKILL.md disagrees with the source, the source wins.

Check every concrete claim against the source:

- method signatures, keyword vs positional arguments, default argument values
- public/private/protected visibility
- return values
- constant, class, and module names
- default option values
- described runtime behavior, including what arguments a yielded block actually receives

Then:

- Don't invent APIs, methods, or options that aren't in the source.
- Don't restructure, re-style, or "improve" content that's already correct.
  Keep correct text verbatim so the diff stays small.
- Only change what the source proves is wrong.

## Output

Write the **full** corrected SKILL.md (frontmatter optional, since it gets rebuilt) to a
file, even if you changed nothing, then run `apply-verify`. The helper decides `changed`
by diffing the files. Report that result, not your own opinion of whether you changed anything.

After applying, give the user a short list of what you corrected (e.g. "`Foo#bar` takes
`timeout:` as a keyword, not positional"). The gem doesn't keep this list in metadata,
so the chat is the only place it appears.
