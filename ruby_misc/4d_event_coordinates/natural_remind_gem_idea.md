# 4D Event Coordinates — Spacetime Event Modeling

## Origin (2001 — JISR and TEBO Projects)

### JISR — Joint Intelligence, Surveillance, and Reconnaissance

This problem space was first explored in 2001 during the **JISR** project
for the US military. [JISR](https://www.nato.int/en/what-we-do/deterrence-and-defence/joint-intelligence-surveillance-and-reconnaissance)
is NATO's integrated system for collecting, analyzing, and sharing
intelligence across the Alliance. It combines surveillance (persistent
monitoring), reconnaissance (targeted information-gathering), and intelligence
analysis to support military operations and decision-making.

JISR provides "decision-makers and action-takers with a better situational
awareness of the conditions on the ground, in the air, at sea, in space and
in the cyber domain." The system operates through collection assets gathering
raw data, intelligence analysts fusing and synthesizing from multiple sources,
and decision-makers applying finished intelligence to operational planning.

**The driving question**: how do you codify and reason about temporal
expressions like **"Expect an attack after Ramadan"** where the reference
is cultural, calendar-system-dependent, and fuzzy?

That expression requires:
1. Knowing what "Ramadan" is (Islamic calendar period, not a fixed Gregorian date)
2. Resolving it to a Gregorian date range for the relevant year
3. Understanding "after" means after the END of that range
4. Preserving the unbounded nature — we know the START but not the end

This is fundamentally different from date parsing. It's **temporal semantics**.

### TEBO — Theater Effects-Based Operations

The work expanded through the **TEBO (Theater Effects-Based Operations)**
project. [Effects-Based Operations (EBO)](https://bootcampmilitaryfitnessinstitute.com/2022/11/01/what-are-effects-based-operations/)
is a military methodology that emerged during the 1991 Persian Gulf War,
emphasizing desired strategic outcomes over force-on-force attrition.

EBO is defined as "a process for obtaining a desired strategic outcome or
effect on the enemy through the synergistic and cumulative application of
the full range of military and nonmilitary capabilities at all levels of
conflict." Rather than pursuing destruction as an end goal, EBO prioritizes
end-state objectives and works backward to identify optimal means.

**Core EBO concepts relevant to this model:**
- **System-of-Systems Analysis (SoSA)** — examining the totality of the
  system being acted upon, not isolated targets. Events don't exist in
  isolation; they cascade through interconnected systems.
- **Secondary and tertiary effects** — understanding that actions produce
  chains of consequences. Bombing a power grid doesn't just cut power;
  it disables hospitals, water treatment, communications, air defense.
- **Centre of Gravity analysis** — identifying philosophical (not physical)
  centers of gravity: leadership, infrastructure, population, military forces.
- **Lethal and non-lethal integration** — the same event model must handle
  kinetic strikes, psychological operations, civil affairs, and diplomatic
  actions within a unified framework.

TEBO was the Army-led Joint Capability Technology Demonstration that attempted
to build software implementing these concepts. It bundled Operational Network
Analysis (ONA) and SoSA with EBO concepts. The software development ultimately
failed, and in 2008 General James Mattis issued a memorandum directing USJFCOM
to "no longer use, sponsor or export the terms and concepts related to EBO."

However, the concepts persisted — Joint Publication 5-0 references effects-based
concepts 124 times, and the Air Force codified effects-based thinking in
official doctrine. The thinking survived even as the terminology was suppressed.

### Air and Missile Defense

The spatial-temporal modeling also connects to **Air and Missile Defense
systems** (Patriot, THAAD), where the core problem is:

1. **Detection** — Identify a launch event (spatiotemporal point)
2. **Track** — Follow the object's trajectory through 4D spacetime
3. **Predict** — Calculate the future trajectory (spatial path as a function
   of time, accounting for ballistic physics, atmospheric conditions, and
   potential maneuvering)
4. **Intercept** — Compute the optimal intercept point — a future spacetime
   coordinate where the interceptor and the threat will converge

This is the same 4D event model applied at millisecond precision and
supersonic velocities. The [THAAD system](https://missilethreat.csis.org/system/thaad/)
uses its AN/TPY-2 X-band radar to track projectile trajectories in real time,
feeding data into the Fire Control system which calculates exact intercept
points and assigns interceptors from the nearest launcher. The Patriot system's
AN/MSQ-104 Engagement Control Station automatically computes parameters that
ensure the highest probability of kill.

The trajectory prediction problem is fundamentally:
- A **moving spatial coordinate** (the missile's position changes continuously)
- Coupled to **temporal coordinates** (position is a function of time)
- With **decreasing uncertainty** (longer tracking = better prediction)
- Under **time pressure** (the intercept window is finite)
- With **cascading effects** if interception fails

## Rekindled (2026 — remadd.rb)

While building `~/scripts/remadd.rb` — a CLI tool that uses the Chronic gem
to parse natural language date/time expressions and generate remind(1) entries —
we hit the limits of regex-based pattern matching for remind's richer syntax.

The current `remadd.rb` handles ~15 patterns (daily, weekdays, weekends, monthly,
ordinal weekdays, "every other", "until", time ranges, durations, etc.) using
layered regexes with Chronic as the date parser. It works, but:

- Chronic is abandoned (last release: 2013-09-09)
- Regex patterns don't compose well — adding new patterns risks breaking existing ones
- Remind's full trigger syntax (SATISFY, SCANFROM, UNTIL, SKIP, BEFORE, AFTER,
  OMIT, OMITFUNC, computed expressions) is far richer than what regexes can
  comfortably handle
- The SATISFY expression block syntax is not intuitive for end users

## The Idea

A Ruby gem — working name `natural_remind` or `remind_lang` — that translates
plain English into valid remind(1) trigger syntax.

### Example Conversions

```
"every other friday at 2pm"
  → REM Fri AT 14:00 SATISFY [trigger(trigdate()) && ((coerce("INT", trigdate()) / 7) % 2) == 0]

"second thursday from 9:30am to 11:30am"
  → REM Thu 8 ++7 AT 09:30 DURATION 2:00

"third thursday in november at 9am for 2 hours"
  → REM Thu Nov 15 ++7 AT 09:00 DURATION 2:00

"every weekday at 9am until december 31"
  → REM Mon Tue Wed Thu Fri AT 09:00 UNTIL Dec 31 2026

"last friday of every month at 3pm"
  → REM Fri 25 ++7 AT 15:00

"daily except holidays at 8am"
  → (needs OMIT or OMITFUNC support)

"every 3 weeks on monday"
  → (needs SATISFY with week modulo arithmetic)
```

## Two Approaches Considered

### 1. EBNF-Based Parser

A formal grammar for the English input language, implemented with a parser gem
(Parslet, Treetop, or Racc).

**Pros:**
- Composable grammar — patterns combine naturally
- Better error messages (can point to where parsing failed)
- Self-documenting — the grammar IS the specification
- Deterministic, fast, works offline
- Handles remind's complex SATISFY expressions structurally

**Cons:**
- Significant upfront effort to define the grammar
- Harder to handle truly free-form English
- Brittleness with unexpected phrasings

**Best for:** A well-defined subset of English that maps cleanly to remind syntax.

### 2. LLM-Based Approach

Feed remind's syntax documentation and examples to an LLM, let it generate
the REM line from arbitrary English input.

**Pros:**
- Handles ambiguity and novel phrasings gracefully
- No grammar to maintain
- Can handle the full remind syntax without explicit rules
- Better UX for complex one-off expressions

**Cons:**
- Latency (API call per parse)
- Cost per invocation
- Occasional hallucinated syntax
- Requires network connectivity
- Non-deterministic output

**Best for:** Long-tail complex expressions that a parser can't handle.

### 3. Hybrid (Recommended)

Deterministic EBNF parser for common patterns (fast, predictable, offline).
LLM fallback for anything the parser can't handle. The parser gem gives you
the reliable foundation; the LLM handles "I don't know how to say this in
remind" cases.

```ruby
result = NaturalRemind.parse("every other friday at 2pm")
# Fast, deterministic, offline

result = NaturalRemind.parse("third business day after easter excluding good friday")
# Falls back to LLM if parser can't handle it
```

## Current remadd.rb Patterns Implemented (as of 2026-03-06)

These are working in `~/scripts/remadd.rb` using regex + Chronic:

| Input Pattern                              | Remind Output                                         |
|--------------------------------------------|-------------------------------------------------------|
| `daily at 9am`                             | `REM AT 09:00 MSG ...`                                |
| `weekdays at 9am`                          | `REM Mon Tue Wed Thu Fri AT 09:00 MSG ...`            |
| `weekends at 10am`                         | `REM Sat Sun AT 10:00 MSG ...`                        |
| `monthly on the 15th`                      | `REM 15 MSG ...`                                      |
| `every monday at 9am`                      | `REM Mon AT 09:00 MSG ...`                            |
| `every other friday at 2pm`                | `REM Fri AT 14:00 SATISFY [...] MSG ...`              |
| `second thursday at 0930`                  | `REM Thu 8 ++7 AT 09:30 MSG ...`                      |
| `second thursday from 0930 to 1130`        | `REM Thu 8 ++7 AT 09:30 DURATION 2:00 MSG ...`       |
| `second thursday at 0930 for 2 hours`      | `REM Thu 8 ++7 AT 09:30 DURATION 2:00 MSG ...`       |
| `third thursday in november at 9am`        | `REM Thu Nov 15 ++7 AT 09:00 MSG ...`                 |
| `next monday at 9am until december 31`     | `REM Mar 9 2026 AT 09:00 UNTIL Dec 31 2026 MSG ...`  |
| `tomorrow at 2pm`                          | `REM Mar 7 2026 AT 14:00 MSG ...`                     |
| `next friday at 10am`                      | `REM Mar 13 2026 AT 10:00 MSG ...`                    |
| `in 3 days`                                | `REM Mar 9 2026 MSG ...`                              |
| `-r "Thu 8 ++7 AT 09:30 MSG text %"`       | Raw passthrough (auto-prepends REM if missing)        |

### Ordinal-to-Day Mapping Used

```
first  → day 1   (1st of month)
second → day 8   (2nd week)
third  → day 15  (3rd week)
fourth → day 22  (4th week)
last   → day 25  (works via ++7 scanning)
```

### Remind Features NOT Yet Covered

- OMIT / OMITFUNC (skip holidays)
- SKIP / BEFORE / AFTER (holiday collision behavior)
- SCANFROM (look-ahead start date)
- PRIORITY
- TAG
- Complex SATISFY expressions beyond biweekly
- Hebrew calendar functions: hebdate(), hebday(), hebmon(), hebyear()
- Easter functions: easterdate()
- Computed date expressions in MSG using `[expression]`
- WARN (pre-trigger warnings distinct from advance notice)
- CAL / SPECIAL (calendar display modifiers)
- COLOR
- RUN (execute a command instead of displaying)

## Ruby Gems for Date/Time Parsing (Comprehensive List)

### Natural Language Date/Time Parsers

| Gem | Version | Last Release | Status | Description |
|-----|---------|-------------|--------|-------------|
| **chronic** | 0.10.2 | 2013-09-09 | Abandoned | The original NL date/time parser. 125M+ downloads. Handles "tomorrow", "next friday", "in 3 days", etc. Still works fine — the problem space hasn't changed. Used in current remadd.rb. github.com/mojombo/chronic |
| **chronic_duration** | 0.10.6 | 2014-09-08 | Abandoned | Parses elapsed time: "4 hours 30 minutes", "1 day 6 hrs". Companion to Chronic. github.com/hpoydar/chronic_duration |
| **chronic_between** | 0.5.0 | 2021-06-20 | Low activity | Parses time ranges: "between 9am and 5pm". github.com/jrobertson/chronic_between |
| **nickel** | 0.1.6 | 2014-07-15 | Abandoned | Parses natural language into date, time, AND message components. Interesting because it separates the message from the temporal expression — exactly what remadd needs. github.com/iainbeeston/nickel |
| **tickle** | 1.2.0 | 2020-09-18 | Low activity | Natural language parser specifically for **recurring events**. Built on top of Chronic. "every other day", "the 3rd of every month". github.com/yb66/tickle |
| **quando** | 0.0.8 | 2020-07-29 | Stale | Configurable date parser. github.com/kinkou/quando |
| **human_time** | 0.2.3 | 2016-08-25 | Abandoned | Human-readable time comparisons. github.com/allenan/human_time |
| **timeliness** | latest | 2025-05-13 | **Active** | Date/time parsing with strict format control. Not NL but highly configurable format definitions. github.com/adzap/timeliness |

### Recurrence / Scheduling Libraries

| Gem | Version | Last Release | Status | Description |
|-----|---------|-------------|--------|-------------|
| **ice_cube** | 0.17.0 | 2024-07-18 | **Active** | RFC 5545 (iCal) recurrence rules. Powerful but verbose API. "Every 2nd Tuesday", "weekly on Mon, Wed, Fri". The most complete recurrence library. ice-cube-ruby.github.io/ice_cube/ |
| **ice_cube_english** | 0.4 | 2012-06-12 | Abandoned | English parsing frontend for ice_cube. Interesting but dead. github.com/dlitz/ice_cube_english |
| **montrose** | 0.18.0 | 2025-01-25 | **Active** | Clean API for recurring events. `Montrose.weekly.on(:friday).at("9am")`. github.com/rossta/montrose |
| **fugit** | 1.12.1 | 2025-10-14 | **Active** | Cron expressions, durations, time points. Used by rufus-scheduler. Parses "every 5 minutes", cron strings, ISO 8601 durations. github.com/floraison/fugit |
| **recurrence** | 1.3.0 | 2014-04-21 | Abandoned | Simple recurring events. github.com/fnando/recurrence |

### Time Math / Utilities

| Gem | Version | Last Release | Status | Description |
|-----|---------|-------------|--------|-------------|
| **time_math2** | latest | 2019-03-15 | Stale | Time arithmetic: floor, ceil, sequences. github.com/zverok/time_math2 |
| **by_star** | 4.0.1 | 2023-01-18 | Maintained | ActiveRecord/Mongoid date scoping. "by_month", "by_week". github.com/radar/by_star |

### Remind-Specific

| Gem | Version | Last Release | Status | Description |
|-----|---------|-------------|--------|-------------|
| **gnu-remind** | 0.2.5 | 2024-07-12 | Low activity | Ruby wrapper for remind + ICS file integration. Could be useful as a foundation. github.com/xorgnak/remind |
| **remind** | 1.1.0 | 2009-11-01 | Dead | Growl notifications (unrelated to remind(1) the calendar tool) |

### Chronic Forks and Variants

| Gem | Description |
|-----|-------------|
| **aaronh-chronic** (0.3.9) | Early fork |
| **caleb-chronic** (0.3.0) | Fork |
| **chronic-mmlac** (0.10.2.1) | Minor patch fork |
| **chronic_2001** (0.1.5) | Y2K-era date handling variant |
| **chronic_2011** (0.1.0) | Date handling variant |
| **chronic_cron** (0.7.1) | Chronic + cron expression output |
| **chronic_tree** (1.0.1) | Parse tree output from Chronic |
| **anachronic** (0.44.0) | Alternative implementation |

### Parser Gems (for building the EBNF approach)

| Gem | Description |
|-----|-------------|
| **parslet** | PEG parser combinator — clean Ruby DSL for defining grammars |
| **treetop** | PEG parser generator — grammar files compiled to Ruby |
| **racc** | LALR parser generator — ships with Ruby stdlib |
| **citrus** | PEG parsing with grammar files |
| **rattler** | Parser generator for Ruby |

## Gems Most Relevant to This Idea

1. **tickle** — Already does NL → recurring events on top of Chronic. Could be
   extended or used as a model for the remind-specific layer.
2. **nickel** — Separates message from temporal expression. Exactly the pattern
   remadd uses.
3. **ice_cube** — Most complete recurrence model. Could serve as an intermediate
   representation between English and remind syntax.
4. **fugit** — Actively maintained. Cron + duration + time parsing. Could replace
   Chronic for the time-parsing layer.
5. **gnu-remind** — Already has some remind(1) integration. Could be a starting
   point or collaboration target.

## The Bigger Problem: Temporal Semantics

The remind(1) converter is one application. The deeper problem is a
**temporal semantics library** that can resolve any English temporal
reference to a coordinate (or range of coordinates) in time.

### Not All Temporal References Are Points

Most date parsers assume the output is a single datetime. But real temporal
expressions resolve to **ranges with varying precision**:

| Expression | Type | Resolution |
|---|---|---|
| "March 15 at 2:30pm" | Point | exact |
| "tomorrow morning" | Range | period (~6 hours) |
| "this spring" | Range | season (~3 months) |
| "after Ramadan" | Open range | cultural (start known, end unknown) |
| "around Christmas" | Fuzzy range | cultural + padding |
| "before sunrise" | Range | astronomical + location-dependent |
| "during Lent" | Range | cultural (computed from Easter) |
| "Q2 2026" | Range | quarter (3 months) |
| "someday" | Unbounded | no useful constraint |

### Temporal Reference Categories

#### 1. Calendar-System References (Cultural)
- **Islamic**: Ramadan, Eid al-Fitr, Hajj, Muharram
  - Purely lunar calendar (~354 days/year), shifts ~11 days/year
  - "After Ramadan" requires Hijri-to-Gregorian conversion
- **Jewish/Hebrew**: Passover, Sukkot, Hanukkah, Rosh Hashana
  - Lunisolar calendar with leap months
  - remind(1) has built-in `hebdate()` support
- **Christian**: Easter, Lent, Advent, Holy Week
  - Easter is computed (Meeus/Computus algorithm)
  - Most other dates derive from Easter
- **Secular/Cultural**: Thanksgiving, Labor Day, Black Friday
  - Floating dates (nth weekday of month)

#### 2. Seasonal References
- spring, summer, fall/autumn, winter
- **Hemisphere-dependent**: spring in Texas ≠ spring in Australia
- **Meteorological vs astronomical**: different boundary dates
- Fuzzy by nature — "early spring" vs "late spring"

#### 3. Time-of-Day Periods
- morning, afternoon, evening, night, predawn, dawn, dusk, midday
- **Culturally variable**: military morning starts at 0500, civilian at 0600
- **Composable**: "tomorrow morning", "Christmas evening", "Friday night"

#### 4. Astronomical References
- sunrise, sunset, civil twilight, nautical twilight
- **Location-dependent**: requires latitude/longitude
- **Date-dependent**: sunrise time changes daily
- Computed via NOAA solar position algorithm

#### 5. Relational References
- **after/before**: "after Ramadan", "before sunrise"
- **during**: "during Lent", "during the meeting"
- **around**: "around Christmas" (fuzzy expansion)
- **between**: "between Christmas and New Years"
- **until/since**: "until Easter", "since Labor Day"

#### 6. Event-Relative References
- "the day after my dentist appointment"
- "the Friday before Thanksgiving"
- Requires an event store to resolve the anchor

### The Intersection Problem

Real expressions often combine categories:

| Expression | Components |
|---|---|
| "tomorrow morning" | date + period |
| "every Friday evening during Ramadan" | recurrence + period + cultural range |
| "before sunrise on Easter" | relation + astronomical + cultural |
| "the morning of the day after Thanksgiving" | period + relation + cultural |
| "next spring" | seasonal + relative |

These are **intersections of temporal ranges**. The system must:
1. Resolve each component to a TemporalRange
2. Compute the intersection
3. Handle empty intersections (impossible combinations)
4. Preserve the resolution/fuzziness of the least-precise component

### Domain Model (Type Hierarchy)

```
TemporalRange (earliest, latest, resolution, label)
  │
  ├── Instant          — a single point (wraps a datetime)
  ├── Span             — between two references
  ├── Recurrence       — repeating pattern (daily, weekly, ordinal, etc.)
  │
  ├── NamedAnchor      — "christmas", "thanksgiving" → resolved via registry
  ├── EventRef         — reference to another event by name
  ├── RelativeAnchor   — offset from another reference (+3 days, next friday after)
  ├── RelativeToRange  — relation (after/before/during/around) to a range
  │
  ├── Season           — spring/summer/fall/winter (hemisphere-aware)
  ├── DayPeriod        — morning/afternoon/evening/night (context-aware)
  ├── SolarEvent       — sunrise/sunset (location-aware)
  ├── CulturalPeriod   — Ramadan/Lent/Passover (calendar-system-aware)
  │
  └── Intersection     — combination of multiple ranges
```

### Commitment Level — Fixed vs Tentative

Events carry a **commitment level** that reflects the speaker's intent:

| Level | Signal words | Example |
|---|---|---|
| **fixed** | "leaving", "booked", "will", direct statement | "I leave Dec 26" |
| **tentative** | "planning", "hoping", "want to" | "Planning a vacation in spring" |
| **proposed** | "might", "could", "maybe", "what if" | "We could visit Grandma for Easter" |
| **conditional** | "if", "assuming", "weather permitting" | "If the weather holds, hiking Saturday" |
| **deferred** | "rain check", "postponed", "push back" | "Rain check on Friday's lunch" |
| **cancelled** | "cancelled", "called off", "not happening" | "The conference has been cancelled" |

This affects output:
- **fixed/recurring** → active `REM` line
- **tentative/proposed/conditional** → commented-out `REM` with status prefix
- **cancelled** → commented-out, description only
- Commitment can **transition**: tentative → proposed → fixed → cancelled

The language itself carries these signals. A parser must detect intent words
before extracting the temporal expression.

### Key Design Principles

1. **Ranges, not points** — the fundamental type is a range with a resolution
2. **Preserve fuzziness** — don't force false precision. "After Ramadan" is
   genuinely unbounded on one end.
3. **Composable** — any reference can be combined with any other via intersection
4. **Context-aware** — location (for solar), hemisphere (for seasons), culture
   (for day periods), calendar system (for religious observances)
5. **Resolution tracking** — every result carries metadata about how precise it is

### Output Adapters

The temporal model is parser-agnostic AND output-agnostic:

```
                    ┌─── remind(1) syntax
                    │
TemporalRange ──────┼─── iCal (RFC 5545)
                    │
                    ├─── cron expression
                    │
                    ├─── human-readable English
                    │
                    └─── intelligence report format
```

## Architecture Sketch (Revised)

```
English input: "every Friday evening during Ramadan"
    │
    ▼
┌──────────────────┐
│  Tokenizer       │  Separate description from temporal expression
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│  Temporal Parser │  EBNF grammar OR LLM
│                  │  Produces TemporalRange objects
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│  Resolver        │  Resolves NamedAnchors, CulturalPeriods, SolarEvents
│                  │  Requires: location, calendar tables, date
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│  Compositor      │  Intersects/combines multiple ranges
│                  │  Handles recurrence expansion within bounded ranges
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│  Output Adapter  │  remind(1), iCal, cron, English, JSON, etc.
└──────────────────┘
```

## Extended Capabilities

Beyond the core 4D coordinate model, these capabilities naturally fit within
the same framework. They were part of the original JISR/TEBO/Air Defense work.

### 1. Causality and Event Chains

Events don't exist in isolation. They form directed graphs of cause and effect.

```
"After the meeting, we'll grab lunch"
  → temporal ordering + causal dependency (lunch depends on meeting)

"Because of the hurricane, the trip was cancelled"
  → one event causes a state change in another

"Bombing the power grid disabled the hospital"
  → cascading effects through interconnected systems (core EBO concept)
```

This is the **secondary and tertiary effects** problem from TEBO/EBO doctrine.
The model needs:
- Directed edges between events (cause → effect)
- Effect types: enables, prevents, degrades, destroys, transforms
- Cascade depth tracking (1st order, 2nd order, 3rd order effects)
- Probability propagation along causal chains

In personal use: "If the flight is delayed, we'll miss the connection, which
means we won't make the hotel check-in." Three events in a causal chain, each
with spatial and temporal coordinates that cascade.

### 2. Movement / Trajectories

Events can move through space over time. The spatial coordinate becomes a
function of the temporal coordinate.

```
"Driving from Tyler to Dallas" → path through spacetime
"Convoy moving through hostile territory" → spatial track with temporal markers
"Vacation itinerary: Rome → Florence → Venice" → sequence of spatial waypoints
"Ballistic missile trajectory" → continuous 4D curve under physical laws
```

A trajectory is:
- An ordered sequence of (spatial_point, time) pairs
- With interpolation between known points
- And extrapolation for prediction (the missile defense problem)
- Where you can query: "where were they at 2pm?" → point on the trajectory
- Or: "when did they cross the border?" → temporal intersection with a spatial boundary

This is exactly the Air and Missile Defense tracking problem, just at different
scales and velocities. A vacation itinerary and a ballistic track are the same
data structure with different physics.

### 3. Source Attribution and Confidence

Where did this information come from? How reliable is it?

The intelligence community uses a standardized assessment scale:

| Source Reliability | Meaning |
|---|---|
| A | Completely reliable |
| B | Usually reliable |
| C | Fairly reliable |
| D | Not usually reliable |
| E | Unreliable |
| F | Cannot be judged |

| Information Confidence | Meaning |
|---|---|
| 1 | Confirmed by other sources |
| 2 | Probably true |
| 3 | Possibly true |
| 4 | Doubtful |
| 5 | Improbable |
| 6 | Cannot be judged |

"B2" = usually reliable source, probably true information.
"E5" = unreliable source, improbable information.

In personal use, this maps to:
- "I read it on the official website" (A1)
- "My friend said they heard..." (C3)
- "Some random post online" (E4)

Source attribution affects how much weight you give to every coordinate
in the event.

### 4. Temporal Topology — Allen's Interval Algebra

Events have 13 possible temporal relationships, not just "before" and "after."
James F. Allen defined these interval relations:

| Relation | Example | Inverse |
|---|---|---|
| **before** | Meeting ends before lunch starts | after |
| **meets** | Meeting ends exactly when lunch starts | met-by |
| **overlaps** | Meeting runs over into lunch time | overlapped-by |
| **starts** | Keynote starts when conference starts | started-by |
| **during** | Power outage happened during the storm | contains |
| **finishes** | Dessert finishes when dinner finishes | finished-by |
| **equals** | The eclipse and the viewing party are simultaneous | equals |

This matters for:
- Conflict detection ("you have two meetings that overlap")
- Containment ("this sub-event is within the parent event")
- Sequencing ("A meets B meets C" — a schedule with no gaps)
- Concurrency ("A and B are during C" — parallel sub-events)

### 5. Hierarchical / Nested Events

Events contain sub-events that inherit the parent's spatiotemporal bounds.

```
Conference (Mon-Fri, Convention Center)
├── Keynote (Mon 9am, Main Hall)
├── Breakout Session A (Mon 2pm, Room 101)
├── Breakout Session B (Mon 2pm, Room 202)  ← concurrent with A
├── Lunch (Tue 12pm, Cafeteria)
└── Closing (Fri 4pm, Main Hall)

Military Operation (D-Day to D+30, Normandy region)
├── Phase 1: Air Superiority (D-7 to D-Day, overhead)
├── Phase 2: Beach Landings (D-Day, beaches)
│   ├── Omaha Beach assault
│   ├── Utah Beach assault
│   └── Gold/Juno/Sword Beach assaults
├── Phase 3: Breakout (D+7 to D+21, inland)
└── Phase 4: Exploitation (D+21 to D+30, deep)
```

Parent events constrain children:
- Children's temporal range must be within (or equal to) the parent's
- Children's spatial range should be within the parent's
- Deleting/cancelling a parent cascades to children

### 6. Conditional Branching

Events can fork based on conditions. The spatial and/or temporal coordinates
depend on a condition that hasn't resolved yet.

```
"If it rains, we'll meet inside at the café; otherwise, the park"
  → Two spatial branches, same temporal coordinate
  → Condition: weather
  → Both branches are PROPOSED until condition resolves

"If we get approval by Friday, we deploy Monday; otherwise, next sprint"
  → Two temporal branches, same spatial coordinate
  → Condition: external decision
  → Connects to commitment model (conditional → fixed)
```

This is the **decision tree** problem. In military planning, it's the
**branch plan**: "If the enemy does X, we execute Plan B." Each branch
has its own 4D event tree.

### 7. Pattern Detection / Spatiotemporal Clustering

Multiple events that form a pattern when viewed together:

```
"There have been three shootings within 2 miles of the school in the last month"
  → Spatial cluster (within radius of a named place)
  → Temporal cluster (within a time window)
  → Pattern: frequency + proximity

"IED attacks are increasing along Route Tampa on Fridays"
  → Spatial: along a trajectory (the route)
  → Temporal: day-of-week recurrence
  → Trend: increasing frequency
```

Pattern detection operates on collections of events:
- **Spatial clustering**: events within a radius of each other
- **Temporal clustering**: events within a time window
- **Spatiotemporal clustering**: both simultaneously
- **Trend detection**: frequency changes over time
- **Correlation**: events of type A tend to precede events of type B
  in the same spatial region

This is core to intelligence analysis (detecting threat patterns) and
also to civilian applications (crime hotspot mapping, disease outbreak
tracking, accident-prone intersections).

### 8. Impact Radius / Effect Zone

Events radiate outward from their coordinates:

```
Explosion at point X
  → Blast radius: 100m (immediate destruction)
  → Fragmentation radius: 500m (injury risk)
  → Noise/shockwave: 2km (window damage, hearing)
  → Psychological impact: city-wide

Road closure at point X
  → Direct: blocks the road
  → Traffic impact: 5km radius of congestion
  → Duration: 4 hours

Disease outbreak at location X
  → Initial: point source (a restaurant, a hospital)
  → Spread: expanding spatial range over time
  → Impact radius is a FUNCTION of time (temporal-spatial coupling)
```

The impact radius can be:
- **Fixed**: explosion blast radius
- **Time-dependent**: disease spread, traffic congestion growth
- **Directional**: flood following a river valley, not circular
- **Layered**: different effect types at different distances
- **Domain-crossing**: physical event → economic impact → political effect
  (the EBO cascading effects model)

### 9. Information Decay / Staleness

Intelligence gets stale. Coordinates lose reliability over time.

```
"Planning an attack" (reported today) → HIGH relevance
"Planning an attack" (reported 6 months ago) → relevance decayed
"Located at grid reference X" (reported 2 hours ago) → probably still there
"Located at grid reference X" (reported 3 weeks ago) → probably moved
```

Decay rates depend on:
- **Type of information**: locations decay faster than intentions;
  structural features (bridges, buildings) are stable for years
- **Subject mobility**: a person's location decays in hours;
  a base's location decays in months
- **Event type**: a planned event before it happens is time-sensitive;
  a historical event is permanently fixed
- **Temporal distance to event**: a tentative vacation plan becomes
  more actionable (or stale) as the date approaches

The model should track:
- When the information was collected
- When it was last confirmed/updated
- Expected half-life by information type
- Current confidence = f(original confidence, elapsed time, decay rate)

### 10. Observer / Perspective

The same event, described by different observers, produces different
relative references:

```
Observer A: "Two blocks from my house" → resolves to area near A's house
Observer B: "Across the street from the market" → resolves to area near the market
Observer C: "Sector 7, grid ref 33S NV 123 456" → absolute coordinates
```

All three may describe the same event. The system must:
- Track which observer produced which description
- Resolve relative references using each observer's anchor points
- Correlate multiple reports to determine if they describe the same event
- Handle contradictions (Observer A says "morning," Observer B says "afternoon")
- Weight by source reliability (see #3)

This is the **intelligence fusion** problem from JISR — multiple collection
assets reporting on the same target area, each with different perspectives,
and analysts must synthesize a unified picture.

### 11. Conflict Detection

Two events that overlap in spacetime for the same participant:

```
Schedule conflict:
  "You have a dentist appointment and a team meeting both at 2pm Tuesday"
  → temporal overlap + same participant → CONFLICT

Territorial conflict:
  "Patrol Alpha and Patrol Bravo both assigned to Sector 4, 0600-1200"
  → spatial + temporal overlap + mutual exclusion rule → CONFLICT

Resource conflict:
  "The conference room is booked for two events at 3pm"
  → spatial overlap (same room) + temporal overlap → CONFLICT
```

Conflict detection falls out naturally from intersection operations on
the coordinate model. It requires:
- Participant assignment to events
- Spatial intersection testing
- Temporal intersection testing (Allen's Interval Algebra)
- Mutual exclusion rules (one person can't be in two places)
- Priority/precedence rules for resolving conflicts

### 12. State Transformation

Events that change the world, altering the coordinate space for future events:

```
"The building was demolished"
  → Spatial anchor "the building" no longer exists
  → Future references to "the building" are invalid
  → But "where the building was" remains a valid (historical) reference

"She moved from Tyler to Dallas"
  → NamedPlace("her house") needs to be re-resolved
  → Events before the move resolve to Tyler
  → Events after the move resolve to Dallas
  → Temporal context determines which anchor to use

"The border was redrawn"
  → All spatial references to "inside country X" may have changed
  → Historical events retain old boundaries
  → Future events use new boundaries
```

State transformations create a **temporal versioning** problem:
- Spatial anchors have temporal validity ranges
- The same name resolves to different coordinates at different times
- The system must track when transformations occurred
- Queries must specify temporal context: "where was X as of date Y?"

This connects to the **effects cascade** from EBO: an event transforms
the state of the world, which changes the coordinates of future events,
which may trigger or prevent other events.

### 13. N-Dimensional Event Coordinates

The 4D model (3 spatial + 1 temporal) is a starting point, not the full picture.
Every measurable attribute of an event is a coordinate in some dimension, and
each dimension follows the same abstract pattern:

| Dimension | Point | Range | Named Reference |
|---|---|---|---|
| Spatial | 33.5°N 44.2°E | 50km radius | "Baghdad" |
| Temporal | 14:30 UTC | 4am-4:30am | "after Ramadan" |
| Spectral (EM) | 2.5 GHz | 2-4 GHz (S-band) | "fire control radar" |
| Altitude | 1200m ASL | FL250-FL350 | "ground level" |
| Network/Cyber | 10.0.0.1:443 | 10.0.0.0/24 | "the DMZ" |
| Acoustic | 440 Hz | 20-20000 Hz | "gunshot" |
| Chemical | 0.5 mg/m³ HD | >IDLH threshold | "mustard agent" |
| Financial | $1,247.50 | $1000-$5000 | "petty cash" |
| Velocity | Mach 2.3 | subsonic range | "sprint speed" |

Each dimension supports: points, ranges, named references, relative offsets,
precision/resolution tracking, knowledge states, and intersection operations.

**An event is a point in N-dimensional space where each dimension may be a
point, a range, or unknown.**

#### SIGINT Example

```
"Frequencies 2.5 GHz and 3 GHz became active between 4am and 4:30am yesterday.
 These signals were observed by listening station Bravo at a bearing of 32.5
 degrees and station Zed at a bearing of 12.6 degrees."
```

This sentence encodes coordinates in multiple dimensions:

- **Spectral**: Two points at 2.5 GHz and 3.0 GHz (both S-band)
- **Temporal**: Range 0400-0430 yesterday
- **Spatial**: Not directly stated — derived via **triangulation** from two
  bearing observations. Each bearing is a LINE from a known point; the
  intersection of two lines gives an AREA (with uncertainty proportional
  to the intersection angle and observer accuracy)
- **State**: "became active" — a transition event
- **Observers**: Two named collection assets with known positions

The bearing observations are spatial data that individually give you a ray,
not a point. The intersection angle between bearings determines fix quality:
- 90° intersection = optimal triangulation
- 30-60° = fair
- <30° = poor (elongated uncertainty ellipse)

#### Cyber Event

Network coordinates follow the same pattern:
- IP address = spatial point in network topology
- CIDR range = spatial area
- Port = another dimension
- Protocol = categorical coordinate
- "the DMZ" = named spatial reference
- Data volume, timing patterns = additional dimensions

#### CBRN (Chemical/Biological/Radiological/Nuclear)

Chemical detection adds:
- Substance identity (categorical)
- Concentration (scalar with threshold ranges: "above IDLH")
- Wind vector (directional, affects spatial propagation over time)
- Acoustic (presence or absence of detonation)
- Plume modeling = spatial range that expands as a function of time
  (coupled spatial-temporal dimension, like trajectory)

## Potential Gem Names

- `temporal` (probably taken)
- `temporal_semantics`
- `when_is` — "WhenIs.parse('after Ramadan')"
- `time_sense`
- `chronos` (probably taken)
- `temporal_range`
- `spacetime_event`
- `event_4d`
- `four_d`

## The Full 4D Model — Spacetime Events

The temporal coordinate is one dimension of 4D reality. Events also have
spatial coordinates (latitude, longitude, altitude) that follow the same
patterns as temporal ones:

| Temporal Concept | Spatial Equivalent |
|---|---|
| Instant (point in time) | SpatialPoint (lat/lon/alt) |
| TemporalRange (span) | SpatialRange (area, radius) |
| NamedAnchor ("christmas") | NamedPlace ("home", "the mosque") |
| RelativeAnchor ("day after") | RelativePlace ("two blocks north") |
| Resolution (exact → fuzzy) | Precision (GPS → "somewhere in East Texas") |
| Commitment (fixed/tentative) | Same — applies to the whole event |
| Cultural calendar (Ramadan) | Cultural geography ("the Green Zone") |

### Spatial Precision Hierarchy

| Level | Example | Radius |
|---|---|---|
| exact | GPS fix | ~1m |
| address | 123 Main St | ~10m |
| intersection | corner of Main and 5th | ~20m |
| block | the 400 block of Main St | ~100m |
| neighborhood | downtown | ~1km |
| city | in Tyler, TX | ~10km |
| county | in Smith County | ~50km |
| region | East Texas | ~200km |
| state | in Texas | ~800km |
| country | in Iraq | ~1000km |
| unbounded | somewhere | ∞ |

### Spatial References in Natural Language

Like temporal references, spatial references can be:

- **Absolute**: "33.315° N, 44.395° E" — GPS coordinates
- **Named**: "the mosque", "where I live", "the checkpoint"
- **Relative with compass**: "300 meters north of the checkpoint"
- **Relative without compass**: "two blocks down the street from home"
  (direction unknown → resolves to a ring, not a point)
- **Fuzzy regions**: "somewhere in East Texas", "near Fallujah"
- **Vertical**: "third floor", "basement", "rooftop", "at 30,000 feet"

### 4D Event Examples

```
"Two blocks down the street from where I live, a man was shot on Dec 24"
  Spatial:  RelativePlace(anchor: "home", distance: 200m, direction: unknown)
  Temporal: Instant(Dec 24)
  → Where: ~200m from home (precision: block)
  → When:  Dec 24 (precision: day)

"Expect an attack on the mosque after Ramadan"
  Spatial:  NamedPlace("the mosque") + 500m radius
  Temporal: RelativeToRange(Ramadan, relation: AFTER)
  → Where: vicinity of the mosque (precision: block)
  → When:  after Mar 19 2026 (precision: unbounded)
  → Commitment: TENTATIVE (intelligence assessment)

"Sniper fire from 300 meters north of the checkpoint"
  Spatial:  RelativePlace(anchor: checkpoint, 300m, bearing: 0°)
  Temporal: Instant(now)
  → Where: 300m N of checkpoint (precision: block, ~60m uncertainty)

"Shots fired from the third floor of the building at Haifa and 14th"
  Spatial:  NamedPlace(intersection) + altitude(3rd floor = ~41m ASL)
  Temporal: Instant(now)
  → Where: 3rd floor, Haifa & 14th (precision: address, 3D)
```

### Partial Knowledge and Explicit Uncertainty

"We don't know which countries we will be visiting other than Italy."

This sentence contains two critical pieces of information:
1. Italy is CONFIRMED (known sub-region)
2. Other countries are EXPLICITLY UNKNOWN — not missing data, but stated uncertainty

The system must distinguish four knowledge states:

| State | Meaning | Example |
|---|---|---|
| **known** | We have this information | "at 420 Rose Park Dr, Tyler TX" |
| **partially_known** | We know some parts | "Europe, definitely Italy" |
| **explicitly_unknown** | Source said they don't know | "we don't know which countries" |
| **missing** | Not mentioned, might learn later | (no location given at all) |

This distinction matters for intelligence analysis: "we don't know where" means
the source has been asked and cannot provide location. Missing location means
nobody asked yet. The follow-up actions are completely different.

### The "down the street" Problem

When the direction is unknown ("down the street", "nearby", "around the corner"),
the spatial reference resolves to a **ring** around the anchor — we know HOW FAR
but not WHICH DIRECTION. This is exactly analogous to "sometime in the spring"
in the temporal domain — we know the general bounds but not the specific point.

A known compass direction ("300m north") narrows it to a point with proportional
uncertainty. An unknown direction keeps the full ring.

## Exploration Files

- `temporal_event_model.rb` — Domain model sketch: Event, Instant, Span,
  Recurrence, NamedAnchor, RelativeAnchor, EventRef, AnchorRegistry
- `temporal_coordinate_types.rb` — Extended types: TemporalRange, Resolution,
  Seasons, DayPeriods, SolarEvents, CulturalPeriods, RelativeToRange,
  Intersection, GeoLocation
- `temporal_commitment.rb` — Commitment levels (fixed/tentative/proposed/
  conditional/deferred/cancelled), intent signal detection from natural
  language, commitment transitions with history, remind output by level
- `spatial_coordinate.rb` — Spatial dimension: SpatialPoint (with Haversine
  distance, bearing, offset), SpatialRange (radius/bounds), NamedPlace,
  RelativePlace (compass + contextual directions), PlaceRegistry,
  FuzzyRegions, VerticalRef (floors/altitude), SpaceTimeEvent (full 4D),
  Precision hierarchy (GPS → unbounded)
- `spacetime_event.rb` — Unified 4D model: KnowledgeState (known/partially_known/
  explicitly_unknown/missing), KnowledgeFact, SpatialRegion with known and
  unknown sub-regions, Participant with identity state, knowledge gradient
  comparison across events. Four worked examples: Europe vacation (partial
  spatial + seasonal temporal), shooting (relative spatial + fixed temporal),
  intel assessment (fuzzy both dimensions), quilt guild (fully known)
- `dimensional_attributes.rb` — N-dimensional event model: SpectralPoint/
  SpectralRange (EM frequency coordinates), SpectralBands (IEEE radar bands,
  WiFi, GPS, threat systems), BearingObservation (line from known observer),
  Triangulation (two-bearing fix with uncertainty and quality assessment),
  SignalEvent (spectral + temporal + spatial via triangulation),
  NetworkCoordinate (IP/port/protocol), AcousticCoordinate, ChemicalCoordinate,
  NDimensionalEvent (arbitrary dimension bag). Three worked examples: SIGINT
  report with triangulation, cyber exfiltration event, CBRN chemical detection

## Files Related to This Work

- `~/scripts/remadd.rb` — Current working CLI tool (regex + Chronic)
- `~/.bashrc__remind` — Shell integration, aliases, daemon control
- `~/Documents/reminders/` — Directory of .rem files
- `~/Documents/reminders/040-personal.rem` — Default target for remadd
