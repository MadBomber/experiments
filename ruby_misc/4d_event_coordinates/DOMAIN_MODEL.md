# Domain Model — Event Coordinates

## Core Abstraction

An **EVENT** has a description and one or more **COORDINATES**.

A **COORDINATE** may be tentative, carrying a confidence level that
expresses how certain the coordinate is.

A **COORDINATE** is either **TEMPORAL** or **GEOSPATIAL**.

**COORDINATES** may reference one or more **EVENTs** as a way to
establish a starting or ending point.

A **TEMPORAL** coordinate is either a single point in time or a
range of date/time.

A **GEOSPATIAL** coordinate is either a single point in 2D or 3D.
A **GEOSPATIAL** coordinate could also be an area or a volume.

---

## Type Definitions

```
EVENT
  ├── description : Text
  └── coordinates : [COORDINATE]  (one or more)

COORDINATE
  ├── confidence  : Float (0.0..1.0) or nil (certain)
  ├── references  : [EVENT]  (zero or more, for anchoring)
  └── type        : TEMPORAL | GEOSPATIAL

TEMPORAL < COORDINATE
  └── value       : INSTANT | TIMERANGE

  INSTANT
    └── datetime  : DateTime

  TIMERANGE
    ├── start     : DateTime | EVENT reference
    └── end       : DateTime | EVENT reference

GEOSPATIAL < COORDINATE
  └── value       : POINT | AREA | VOLUME

  POINT
    ├── latitude   : Float
    ├── longitude  : Float
    └── altitude   : Float (optional — 2D vs 3D)

  AREA
    ├── boundary   : [POINT] or center + radius
    └── type       : polygon | circle

  VOLUME
    ├── base       : AREA
    ├── floor      : Float (altitude)
    └── ceiling    : Float (altitude)
```

---

## Relationships

```
EVENT ──has──▶ COORDINATE (1..*)

COORDINATE ──references──▶ EVENT (0..*)
  "the day after Christmas"
    → TEMPORAL coordinate references the EVENT "Christmas"
  "two blocks from where the shooting happened"
    → GEOSPATIAL coordinate references the EVENT "shooting"

COORDINATE ──has──▶ confidence (0.0..1.0)
  1.0  = certain ("I leave on Dec 26")
  0.7  = likely ("probably next spring")
  0.3  = uncertain ("maybe in Europe")
  nil  = not assessed
```

---

## Key Properties

1. **An EVENT can have multiple COORDINATES**
   - "Vacation in Europe in the spring" has one TEMPORAL and one GEOSPATIAL
   - "Drove from Tyler to Dallas on Tuesday" has two GEOSPATIAL and one TEMPORAL
   - "The meeting ran from 9 to 11 in the conference room" has one TEMPORAL range and one GEOSPATIAL point

2. **COORDINATES can reference EVENTs for anchoring**
   - This creates a graph, not a tree
   - "After Ramadan" → TEMPORAL referencing the EVENT "Ramadan"
   - "Between Christmas and New Years" → TEMPORAL range where start references EVENT "Christmas" and end references EVENT "New Years"
   - Circular references must be prevented or detected

3. **Confidence is per-COORDINATE, not per-EVENT**
   - "We ARE going to Europe (0.9) sometime in the spring (0.5)"
   - The spatial coordinate is more certain than the temporal one
   - An EVENT's overall certainty is the minimum of its coordinate confidences

4. **TEMPORAL values**
   - INSTANT: a single point (2026-03-15T14:30:00)
   - TIMERANGE: start and end, either or both can be:
     - A specific datetime
     - A reference to another EVENT's temporal coordinate
     - Open (unbounded): "after Ramadan" has a start but no end

5. **GEOSPATIAL values**
   - POINT (2D): latitude, longitude
   - POINT (3D): latitude, longitude, altitude
   - AREA: bounded region on a surface (circle, polygon)
   - VOLUME: bounded region in 3D space (area + floor/ceiling)
   - Precision varies: GPS point vs "somewhere in Europe"

---

## Examples

### Simple event
```
EVENT: "Dentist appointment"
  TEMPORAL: INSTANT(2026-03-15 14:30)  confidence: 1.0
  GEOSPATIAL: POINT(32.35, -95.30)     confidence: 1.0
```

### Event-referenced temporal
```
EVENT: "Vacation"
  TEMPORAL: TIMERANGE(
    start: references EVENT("Christmas") + 1 day,
    end:   references EVENT("New Years") → first Monday after
  )  confidence: 1.0
  GEOSPATIAL: AREA(Europe, ~2500km radius)  confidence: 0.3
```

### Fuzzy both dimensions
```
EVENT: "Expected attack"
  TEMPORAL: TIMERANGE(
    start: references EVENT("Ramadan").end,
    end:   nil  (open/unbounded)
  )  confidence: 0.4
  GEOSPATIAL: AREA(Anbar Province, ~150km radius)  confidence: 0.3
```

### Multiple coordinates
```
EVENT: "Road trip"
  TEMPORAL: TIMERANGE(2026-07-10, 2026-07-17)  confidence: 0.7
  GEOSPATIAL: POINT(32.35, -95.30)  confidence: 1.0   # departure
  GEOSPATIAL: POINT(29.76, -95.37)  confidence: 1.0   # destination
  GEOSPATIAL: AREA(route, ~50km corridor)  confidence: 0.5  # path
```

### Volume
```
EVENT: "Restricted airspace"
  TEMPORAL: TIMERANGE(2026-03-10 06:00, 2026-03-10 18:00)  confidence: 1.0
  GEOSPATIAL: VOLUME(
    base: AREA(center: 33.3N 44.4E, radius: 50km),
    floor: 0m,
    ceiling: 10000m
  )  confidence: 1.0
```

---

## Design Decisions

### Movement is a derived attribute, not a coordinate type

Bearing, velocity, and acceleration are computed from multiple
GEOSPATIAL + TEMPORAL coordinate pairs across a sequence of EVENTs.
They are not a primitive coordinate type.

A vehicle "heading north at 60mph" observed at a single point has:
- GEOSPATIAL: the observed position (POINT)
- TEMPORAL: the observation time (INSTANT)
- Description: heading and velocity (attributes of what was observed)

A tracked object (missile, convoy, vehicle) is a sequence of EVENTs,
each with GEOSPATIAL + TEMPORAL coordinates. Trajectory, velocity,
and predicted intercept points are analysis performed on the sequence —
derived from the model, not stored in it.

Only TEMPORAL and GEOSPATIAL are primitive coordinate types.
