# Scratchpad

End-of-session brain dump. Eliminates the ramp-up tax when returning after days or weeks away.

## Template

```
## YYYY-MM-DD

### What I did
- Bullet points of what was accomplished this session

### Where I left off
- Exact state of work in progress (file, function, line if relevant)

### What's next
- Immediate next steps, in priority order

### Blockers / open questions
- Anything unresolved that needs investigation or a decision

### Notes to self
- Anything that felt fragile, surprising, or worth remembering
```

## Example

```
## 2026-02-28

### What I did
- Implemented the CSV import pipeline (parser + validator)
- Added error collection — invalid rows are logged, not fatal

### Where I left off
- `lib/importer/validator.rb` — the date format check works but doesn't handle timezone offsets yet

### What's next
1. Add timezone-aware date parsing (use `Time.zone.parse`)
2. Write tests for malformed CSV edge cases (empty rows, BOM headers)
3. Hook importer into the CLI command

### Blockers / open questions
- The upstream CSV files sometimes have trailing commas — need to confirm if that's intentional or a bug in their export

### Notes to self
- The `CSV.foreach` approach streams rows so memory stays flat even on large files — don't refactor to `CSV.read`
```
