---
name: bttf
description: Use the bttf CLI for datetime arithmetic, formatting, timezone conversion, and duration calculation. Reach for this instead of doing date math mentally — LLMs are unreliable for datetime computation, especially across DST boundaries and leap years.
user-invocable: true
args:
  - name: task
    description: What datetime operation to perform (e.g. "how many days until 2026-01-01", "current time in Tokyo")
    required: false
---

# bttf — Command-line Datetime Tool

`bttf` (Back to the Future) is installed at `/opt/homebrew/bin/bttf`. Use it for **all non-trivial datetime work** — current time, arithmetic, timezone conversion, duration calculation, formatting. Do not do this math mentally.

> **When to reach for bttf:** anytime the user asks about the current time, a date in the past or future, how long until/since something, timezone conversion, or date formatting.

---

## Get the Current Time

```bash
bttf                                      # human-readable local time
bttf time fmt -f rfc3339 now             # ISO 8601 with offset
bttf time fmt -f rfc9557 now             # ISO 8601 with IANA timezone
bttf time fmt -f '%Y-%m-%d' now          # date only
bttf time fmt -f '%Y-%m-%d %H:%M:%S' now
bttf time fmt -f '%s' now               # unix timestamp
```

---

## Datetime Inputs — What bttf Accepts

Most subcommands take a `<datetime>` argument. Accepted forms:

| Input | Meaning |
|---|---|
| `now` | Current instant |
| `today` | First instant of today |
| `yesterday` / `tomorrow` | First instant of prev/next day |
| `2025-03-15` | ISO date (local midnight) |
| `08:30` | Time today |
| `2025-03-15T10:23:00-04:00` | RFC 3339 |
| `2025-03-15T10:23:00-04:00[America/New_York]` | RFC 9557 |
| `-1d` | 1 day ago |
| `1w` | 1 week from now |
| `6mo` | 6 months from now |
| `1y1s` | Mixed units |
| `next saturday` | Next Saturday |
| `last friday` | Previous Friday |
| `this thurs` | This Thursday (or today if it's Thursday) |
| `5pm tomorrow` | 5pm tomorrow |
| `5pm next wed` | 5pm next Wednesday |
| `1 week ago` | Verbose relative form |

---

## `bttf time fmt` — Format / Convert Datetimes

```bash
bttf time fmt now                         # default: rfc9557
bttf time fmt -f rfc3339 now
bttf time fmt -f rfc2822 now
bttf time fmt -f rfc9110 now             # HTTP date format (UTC)
bttf time fmt -f '%B %d, %Y' now         # "June 15, 2026"
bttf time fmt -f '%Y-%m-%d' 2025-03-15
bttf time fmt -f '%A' 2026-07-04         # day of week: "Saturday"
bttf time fmt -f '%V' now               # ISO week number
bttf time fmt -f '%s' now               # unix timestamp
bttf time fmt -f '%c' now -1d 'next sat' # multiple datetimes at once
```

Named formats: `rfc9557` (default), `rfc3339`, `rfc2822`, `rfc9110`

---

## `bttf time parse` — Parse Datetimes from Non-Standard Formats

```bash
bttf time parse -f '%m/%d/%y' 03/15/25          # American date format
bttf time parse -f flexible '5pm next wednesday' # flexible relative form
bttf time parse -f '%s' 1736956800               # from unix timestamp
bttf time parse -i -f '%Y-%m-%d' invalid 2026-01-01  # ignore invalid
```

Options: `-f <format>` (default: rfc9557), `-i/--ignore-invalid`, `-r/--relative <datetime>`

---

## `bttf time relative` — Relative Descriptions Against a Reference

```bash
bttf time relative 'this monday' 2025-04-22     # first Monday on/after date
bttf time relative 'next friday' 2026-01-01
bttf time relative 'last day of month' now
```

Usage: `bttf time relative <relative-description> <datetime>...`

---

## `bttf time in` — Timezone Conversion

```bash
bttf time in America/New_York now
bttf time in Asia/Tokyo now
bttf time in UTC now
bttf time in Pacific/Honolulu now
# datetime first, timezone second — same result
bttf time in now America/Chicago
```

Usage: `bttf time in <time-zone> <datetime>...` or `bttf time in <datetime> <time-zone>...`

---

## `bttf time add` — Datetime Arithmetic

```bash
bttf time add 1w now                      # 1 week from now
bttf time add -1d now                     # yesterday
bttf time add 6mo now                     # 6 months from now
bttf time add 1y6mo now                   # 1 year 6 months from now
bttf time add 90d 2026-01-01              # 90 days after Jan 1
bttf time add '1 week, 12 hours ago' now
```

Usage: `bttf time add <span> <datetime>...` or `bttf time add <datetime> <span>...`

---

## `bttf time cmp` — Filter Datetimes by Comparison

Prints only datetimes satisfying the inequality — useful for filtering lists.

```bash
# Print only datetimes more recent than 2025-03-01
bttf time cmp gt 2025-03-01 2025-02-28 2025-03-02

# Filter from stdin
cat dates.txt | bttf time cmp le now      # only dates in the past
cat dates.txt | bttf time cmp ge 2026-01-01
```

Operators: `eq`, `ne`, `lt`, `gt`, `le`, `ge`
Usage: `bttf time cmp <op> <datetime> <datetime>...`

---

## `bttf time round` — Round Datetimes

Rounding only works for units of days or lower.

```bash
bttf time round -s minute now             # nearest minute
bttf time round -s hour now              # nearest hour
bttf time round -s day now               # nearest day
bttf time round -i 15 -s minute now      # nearest 15 minutes
bttf time round -m trunc -s hour now     # truncate to hour
```

Options: `-s/--smallest <unit>`, `-i/--increment <number>`, `-m/--mode <rounding-mode>` (e.g. `trunc`, `half-expand`)

---

## `bttf time start-of` / `bttf time end-of` — Snap to Period Boundaries

```bash
bttf time start-of year now
bttf time start-of month now
bttf time start-of week now
bttf time start-of day now
bttf time start-of hour now

bttf time end-of year now
bttf time end-of month now
bttf time end-of week now
bttf time end-of day now
```

Usage: `bttf time start-of <unit> <datetime>...`

---

## `bttf time sort` — Sort Datetimes

```bash
bttf time sort 2026-03-01 2025-11-15 2026-01-20   # ascending
bttf time sort -r 2026-03-01 2025-11-15 2026-01-20 # descending (newer first)
cat dates.txt | bttf time sort
cat dates.txt | bttf time sort -r
```

Also accepts tagged data from stdin (see tagging section).

---

## `bttf time seq` — Generate Datetime Sequences (RFC 5545 Recurrence)

```bash
# Every day for 7 occurrences
bttf time seq daily -c 7 now

# Every week until end of year
bttf time seq weekly --until 2026-12-31 now

# Every month for 12 occurrences
bttf time seq monthly -c 12 2026-01-01

# Every weekday (Mon-Fri)
bttf time seq daily -w mon,tue,wed,thu,fri -c 10 now

# Every 2 weeks
bttf time seq weekly -i 2 -c 5 now

# Every Friday the 13th for 3 years
bttf time seq monthly --until 3y -w fri -d 13
```

Frequencies: `daily`, `weekly`, `monthly`, `yearly`
Key options: `-c/--count <n>`, `--until <datetime>`, `-i/--interval <n>`,
`-w/--week-day`, `-d/--day`, `-m/--month`, `-H/--hour`, `-M/--minute`

---

## `bttf span since` / `bttf span until` — Duration Calculation

> Default largest unit is **hours**. Use `-l` to get calendar units.

```bash
# Hours by default
bttf span since 2025-01-20T12:00

# Calendar units
bttf span since 2025-01-20 -l year       # e.g. "3mo 18d 21h ..."
bttf span until 2027-01-01 -l year
bttf span until 2026-12-25 -l day

# Pipe into round for clean output
bttf span since 2025-01-20 | bttf span round -l day -s day
bttf span until 2026-12-25 | bttf span round -l day -s day

# Override the reference point (default: now)
bttf span since 2025-01-01 -r 2026-01-01
```

Options: `-l/--largest <unit>`, `-r/--relative <datetime>`

---

## `bttf span round` — Round Spans

```bash
bttf span round 2h30m10s -s minute         # nearest minute: "2h 30m"
bttf span round 2h30m10s -s minute -m expand  # round up: "2h 31m"
bttf span round 75y5mo22d -l year -s day   # largest=year, smallest=day
bttf span round 90m -s hour               # "2h"

# Pipe
bttf span since 2025-01-01 | bttf span round -l year -s day
```

Options: `-s/--smallest <unit>`, `-l/--largest <unit>`, `-i/--increment <n>`,
`-m/--mode` (`trunc`, `half-expand`, `expand`, etc.), `-r/--relative <datetime>`

---

## `bttf span balance` — Change Largest Non-Zero Unit

Converts units without rounding (full subsumption into target unit):

```bash
bttf span balance 2h30m10s -l seconds     # "9010s"
bttf span balance 75y5mo22d -l month      # collapse years into months
bttf span balance 90m -l hour            # "1h 30m"
```

Options: `-l/--largest <unit>`, `-r/--relative <datetime>`

---

## `bttf span fmt` — Format Spans (Verbose / Custom)

```bash
bttf span fmt '75y5mo22d' -s units-and-designators -d verbose --comma
# → "75 years, 5 months, 22 days"

bttf span fmt 2h30m -d verbose           # "2 hours 30 minutes"
bttf span fmt 2h30m --hms               # HH:MM:SS format
```

Options: `-d/--designator <kind>` (verbose), `-s/--spacing <kind>`,
`--comma`, `--hms`, `--precision <n>`, `--sign <kind>`, `-f/--fractional <unit>`

---

## `bttf span iso8601` — Format Spans as ISO 8601 Durations

```bash
bttf span iso8601 75y5mo22d5h30m12s      # "P75Y5M22DT5H30M12S"
bttf span iso8601 -l 2h30m              # lowercase: "P2DT2H30M"
bttf span since 2025-01-01 | bttf span iso8601
```

---

## `bttf tag` / `bttf untag` — Tagging Pipeline

bttf's tagging system associates datetimes with data items so they can be
sorted/filtered by time, then reconstructed with `untag`.

### `bttf tag exec` — Tag file paths via a command

```bash
# Tag each git-tracked file with its last commit datetime
git ls-files | bttf tag exec git log -n1 --format='%cI'

# Tag with file path substitution ({} = the file path)
find . -name '*.log' | bttf tag exec stat -f '%Sm' {}
```

Options: `-j/--threads <n>`

### `bttf tag lines` — Extract datetimes from log lines

```bash
# Extract and reformat timestamps from a Caddy log
bttf tag lines < access.log \
  | bttf time fmt -f '%B %-d, %Y at %H:%M:%S' \
  | bttf untag --substitute

# Custom regex
bttf tag lines -e '\d{4}-\d{2}-\d{2}' < logfile.txt
```

Options: `--auto <kind>`, `-e/--regex <pattern>`, `--all`

### `bttf tag files` — Extract datetimes from file contents

```bash
# Extract datetimes from PDFs
bttf tag files *.pdf

# Custom regex
bttf tag files -e 'YYYY-MM-DD pattern' report.txt
```

Options: `--auto`, `-e/--regex`, `--all`, `-j/--threads`, `--mmap/--no-mmap`

### `bttf tag stat` — Tag files with filesystem metadata

```bash
find ./ | bttf tag stat modified          # last modified time
find ./ | bttf tag stat created           # creation time
find ./ | bttf tag stat accessed          # last accessed time
```

### `bttf untag` — Reconstruct tagged output

```bash
# Default: strip tags, output data only
cat tagged.txt | bttf untag

# Custom format string
cat tagged.txt | bttf untag -f '{tag} {data}'

# Substitute tag back into original location in line
cat tagged.txt | bttf untag --substitute
```

Options: `-f/--format <string>`, `-s/--substitute`

---

## `bttf tz` — Timezone Commands

```bash
# List all available IANA timezones
bttf tz list
bttf tz list | grep -i tokyo

# Find compatible timezones for an RFC 3339 timestamp
bttf tz compatible '2025-03-09T17:00+10:30'

# Find the next DST transition in a timezone
bttf tz next America/New_York now
bttf tz next America/New_York now -c 3   # next 3 transitions

# Find the previous DST transition
bttf tz prev America/New_York now

# List upcoming DST transitions
bttf tz seq America/New_York -c 5
bttf tz seq Australia/Sydney -c 5

# Show past transitions
bttf tz seq America/New_York -p -c 5
```

---

## Piping Pattern

`bttf` is pipe-friendly — output of one command feeds into another:

```bash
# Convert to Bangkok time, then round to nearest 15 min
bttf time in Asia/Bangkok now | bttf time round -i 15 -s minute

# Get span since a date, then round to nearest day
bttf span since 2025-01-20 | bttf span round -l day -s day

# Format a computed datetime
bttf time add 6mo now | bttf time fmt -f '%B %d, %Y'

# Sort git files by last commit date, show datetime with path
git ls-files \
  | bttf tag exec git log -n1 --format='%cI' \
  | bttf time sort \
  | bttf untag -f '{tag} {data}'
```

---

## Common Recipes

```bash
# What day of the week is a date?
bttf time fmt -f '%A' 2026-07-04

# How many days until a date?
bttf span until 2026-12-25 | bttf span round -l day -s day

# How long ago was something?
bttf span since 2024-03-01 | bttf span round -l day -s day

# Current time in multiple timezones
for tz in America/New_York America/Chicago America/Los_Angeles; do
  echo -n "$tz: "; bttf time in $tz now | bttf time fmt -f '%H:%M %Z'
done

# ISO week number
bttf time fmt -f '%V' now

# Start and end of current month
bttf time start-of month now
bttf time end-of month now

# Filter a list of dates to only future ones
cat dates.txt | bttf time cmp gt now

# Next 5 Mondays
bttf time seq weekly -w mon -c 5 now

# Human-readable "time since" with commas
bttf span since 2025-01-01 -l year | bttf span fmt -d verbose --comma

# Unix timestamp to human readable
bttf time parse -f '%s' 1736956800 | bttf time fmt -f '%c'
```

---

## Tips

- `bttf` always has access to the real current time — use it instead of relying on the date in the system prompt.
- Set `BTTF_NOW` to override "now" for testing: `BTTF_NOW="2025-01-01T00:00:00" bttf`
- Set `BTTF_LOCALE` in your shell to enable locale-aware formats (`%c`, `%x`, `%X`).
- `TZ` env var overrides the system timezone: `TZ=UTC bttf time fmt now`
- `TZDIR` overrides the timezone database location.
- `bttf span since/until` default to **hours** as largest unit; use `-l year` etc. for calendar output.
- Exit code 0 = success; non-zero = parse/arithmetic error — check stderr on failure.
- Use `-h` for short help, `--help` for full docs with examples.
