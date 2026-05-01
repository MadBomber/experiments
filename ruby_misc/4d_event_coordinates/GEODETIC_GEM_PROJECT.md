# Project: `geodetic` Ruby Gem

## Gem Name Candidates

| Name | Available | Rationale |
|------|-----------|-----------|
| **`geodetic`** | Yes | Clean, professional, describes the domain precisely. Geodetic = relating to geodesy, the science of measuring Earth's shape and positions on it. |
| `geodesy` | Likely | The science itself. Slightly broader than needed. |
| `coord_systems` | Likely | Descriptive but generic. |
| `geo_convert` | Likely | Action-oriented but undersells the library. |

**Recommended: `geodetic`** — short, memorable, accurate, and not taken on RubyGems.

## What It Is

A pure-Ruby library for converting between geodetic coordinate systems.
No C extensions, no external dependencies, no FFI. Every coordinate system
converts to every other coordinate system with high precision.

## Origin

Developed for US military projects including JISR (Joint Intelligence,
Surveillance, and Reconnaissance), TEBO (Theater Effects-Based Operations),
and Air & Missile Defense systems. Battle-tested coordinate math refined
over 20+ years.

## Coordinate Systems

| Class | System | Abbreviation | Primary Use |
|-------|--------|-------------|-------------|
| `Geodetic::LLA` | Latitude/Longitude/Altitude | LLA | GPS, mapping, GeoJSON |
| `Geodetic::ECEF` | Earth-Centered Earth-Fixed | ECEF | Satellite tracking, ballistics |
| `Geodetic::UTM` | Universal Transverse Mercator | UTM | Topographic maps, surveying |
| `Geodetic::MGRS` | Military Grid Reference System | MGRS | NATO military operations |
| `Geodetic::ENU` | East-North-Up (local tangent) | ENU | Radar tracking, local navigation |
| `Geodetic::NED` | North-East-Down (local tangent) | NED | Aviation, missile guidance |
| `Geodetic::WebMercator` | Web Mercator (EPSG:3857) | — | Google Maps, OSM, web tiles |
| `Geodetic::UPS` | Universal Polar Stereographic | UPS | Polar region mapping |
| `Geodetic::USNG` | US National Grid | USNG | US civilian MGRS equivalent |
| `Geodetic::StatePlane` | State Plane Coordinate System | SPCS | US state-level surveying |
| `Geodetic::BNG` | British National Grid | BNG | UK Ordnance Survey |

## Supporting Infrastructure

| Component | Purpose |
|-----------|---------|
| `Geodetic::Datum` | Geodetic ellipsoid definitions (WGS84, Clarke 1866, etc.) |
| `Geodetic::GeoidHeight` | Ellipsoidal ↔ orthometric height conversion (EGM96, EGM2008, GEOID18) |
| `Geodetic::CircleArea` | Point + radius containment testing |
| `Geodetic::PolygonArea` | Arbitrary polygon containment (winding number) |

## Key Design Principles

1. **Orthogonal conversions** — every type has `to_*` and `self.from_*` for
   every other type. No dead ends.
2. **Datum-aware** — all conversions accept an optional datum parameter
   (defaults to WGS84). Supports 14 geodetic ellipsoids.
3. **Pure Ruby** — no native extensions, no PROJ dependency, no FFI.
   Runs anywhere Ruby runs.
4. **Precision** — iterative algorithms with convergence thresholds.
   Round-trip errors < 1e-10 degrees for LLA, < 1e-6 meters for ECEF.
5. **Military heritage** — MGRS, NED, ENU are first-class citizens, not
   afterthoughts. These are the systems actually used in defense applications.

## API Design

```ruby
require 'geodetic'

# Create from lat/lon/alt
tyler = Geodetic::LLA.new(32.3513, -95.3011, 166.0)

# Convert to any system
ecef = tyler.to_ecef                     # Earth-centered XYZ
utm  = tyler.to_utm                      # UTM easting/northing/zone
mgrs = tyler.to_mgrs                     # "14S NJ 93456 78123"
wm   = tyler.to_web_mercator             # Web Mercator for map tiles

# Local tangent frame (relative to a reference point)
radar_site = Geodetic::LLA.new(32.40, -95.25, 200.0)
ned = tyler.to_ned(radar_site)           # North/East/Down from radar
enu = tyler.to_enu(radar_site)           # East/North/Up from radar

# Bearing and distance in local frame
ned.bearing_from_origin                  # degrees (0-360)
ned.elevation_angle                      # degrees
ned.distance_to_origin                   # meters
ned.horizontal_distance_to_origin        # meters (ignoring altitude)

# DMS formatting and parsing
tyler.to_dms
#=> "32° 21' 4.68\" N, 95° 18' 3.96\" W, 166.00 m"
Geodetic::LLA.from_dms("32° 21' 4.68\" N, 95° 18' 3.96\" W, 166.00 m")

# Array and string interop
tyler.to_a                               # [32.3513, -95.3011, 166.0]
Geodetic::LLA.new([32.3513, -95.3011])   # from array

# Datum support
tyler_clarke = tyler.to_ecef(Geodetic::Datum.new('clarke_1866'))

# Geoid height / vertical datum
tyler.geoid_height                       # meters (EGM2008)
tyler.orthometric_height                 # MSL height
tyler.convert_height_datum('HAE', 'NAVD88')

# Area containment
circle = Geodetic::CircleArea.new(tyler, 50_000)  # 50km radius
circle.includes?(some_point)

polygon = Geodetic::PolygonArea.new([p1, p2, p3, p4])
polygon.includes?(some_point)

# Tile coordinates for web mapping
wm.to_tile_coordinates(12)              # [x_tile, y_tile, zoom]
wm.to_pixel_coordinates(12)             # [x_pixel, y_pixel, zoom]
```

## Existing Ruby Gems (Competitive Landscape)

| Gem | Downloads | What It Does | Gap |
|-----|-----------|-------------|-----|
| [rgeo](https://github.com/rgeo/rgeo) | 31.7M | OGC geometry operations, spatial queries | No ECEF, NED, ENU, MGRS. Requires GEOS C library for full functionality. |
| [geo_coord](https://github.com/zverok/geo_coord) | ~50K | Basic lat/lon class with Vincenty distance | Only LLA. No conversions to other systems. |
| [geoutm](https://github.com/tallakt/geoutm) | ~500K | LLA ↔ UTM conversion | UTM only. No ECEF, NED, ENU, MGRS, Web Mercator. |
| [coordinate-converter](https://rubygems.org/gems/coordinate-converter) | ~5K | UTM ↔ LLA | UTM only. Minimal. |
| [vincenty](https://rubygems.org/gems/vincenty) | ~100K | Vincenty distance/bearing | Distance only. No coordinate system conversions. |

**No existing gem provides the full conversion chain.** The closest equivalent
in other languages is Python's `pyproj` (wraps PROJ C library) or JavaScript's
`proj4js`. This gem would be the first pure-Ruby solution covering the full
military/aerospace coordinate stack.

## Source Code

The existing implementation lives at:
```
/Users/dewayne/lib/ruby/coordinates/
```

### Files to package

| File | Target Class | Status |
|------|-------------|--------|
| `lla_coordinate.rb` | `Geodetic::LLA` | Working, has tests |
| `ecef_coordinate.rb` | `Geodetic::ECEF` | Working |
| `utm_coordinate.rb` | `Geodetic::UTM` | Working |
| `mgrs_coordinate.rb` | `Geodetic::MGRS` | Working |
| `enu_coordinate.rb` | `Geodetic::ENU` | Working |
| `ned_coordinate.rb` | `Geodetic::NED` | Working |
| `web_mercator_coordinate.rb` | `Geodetic::WebMercator` | Working |
| `geo_datum.rb` | `Geodetic::Datum` | Working |
| `geoid_height.rb` | `Geodetic::GeoidHeight` | Working |
| `circle_area.rb` | `Geodetic::CircleArea` | Working (needs require fix) |
| `polygon_area.rb` | `Geodetic::PolygonArea` | Working (needs require fix) |
| `ups_coordinate.rb` | `Geodetic::UPS` | Needs review |
| `usng_coordinate.rb` | `Geodetic::USNG` | Needs review |
| `state_plane_coordinate.rb` | `Geodetic::StatePlane` | Needs review |
| `british_national_grid_coordinate.rb` | `Geodetic::BNG` | Needs review |
| `demo_conversions.rb` | — | Example script |
| `demo_all_coordinate_systems.rb` | — | Example script |
| `test/lla_coordinate_test.rb` | — | Existing test |

## Work Required

### Phase 1: Core Gem Structure
- [ ] Create gem skeleton (`bundle gem geodetic`)
- [ ] Wrap all classes in `Geodetic` module namespace
- [ ] Move global constants (`RAD_PER_DEG`, `WGS84`, etc.) into module
- [ ] Replace `$GeodesyEllipse` global hash with module constant
- [ ] Fix `require` statements to use `require_relative` within gem
- [ ] Rename classes: `LlaCoordinate` → `Geodetic::LLA`, etc.
- [ ] Write `geodetic.rb` entry point with autoloads

### Phase 2: Test Coverage
- [ ] Port existing `lla_coordinate_test.rb` to gem structure
- [ ] Add tests for ECEF (round-trip via LLA)
- [ ] Add tests for UTM (round-trip, zone edge cases)
- [ ] Add tests for MGRS (parsing, formatting, conversion)
- [ ] Add tests for ENU/NED (local frame, bearing, distance)
- [ ] Add tests for WebMercator (tile coords, pixel coords)
- [ ] Add tests for GeoidHeight (vertical datum conversions)
- [ ] Add tests for CircleArea and PolygonArea containment
- [ ] Chain conversion tests (LLA → ECEF → ENU → NED → ECEF → LLA)
- [ ] Known-point validation against external references (NGS data sheets)

### Phase 3: Review & Polish
- [ ] Review UPS, USNG, StatePlane, BNG implementations
- [ ] Validate MGRS grid letter assignment edge cases
- [ ] Ensure UTM zone boundary handling is correct
- [ ] Add `==`, `to_s`, `to_a`, `inspect` consistently to all classes
- [ ] Add `Comparable` where it makes sense (distance ordering)
- [ ] Freeze constants, mark appropriate methods as private

### Phase 4: Documentation & Release
- [ ] Write README with usage examples
- [ ] Add YARD documentation to all public methods
- [ ] Write CHANGELOG
- [ ] Set up GitHub Actions CI
- [ ] Publish v0.1.0 to RubyGems

### Phase 5: Integration
- [ ] Wire `Geodetic::LLA` into the 4D Event Coordinates `Geospatial` class
- [ ] Add `to_mgrs`, `to_utm`, `to_ned` methods to `Geospatial`
- [ ] Add `Geospatial.from_mgrs(string)` for military grid input
- [ ] Use `WebMercator` for libgd-gis tile rendering integration

## Gem Structure

```
geodetic/
├── lib/
│   ├── geodetic.rb                    # Entry point, autoloads
│   └── geodetic/
│       ├── version.rb
│       ├── datum.rb                   # GeoDatum → Geodetic::Datum
│       ├── geoid_height.rb
│       ├── lla.rb                     # LlaCoordinate → Geodetic::LLA
│       ├── ecef.rb
│       ├── utm.rb
│       ├── mgrs.rb
│       ├── enu.rb
│       ├── ned.rb
│       ├── web_mercator.rb
│       ├── ups.rb
│       ├── usng.rb
│       ├── state_plane.rb
│       ├── bng.rb
│       ├── circle_area.rb
│       └── polygon_area.rb
├── test/
│   ├── test_helper.rb
│   ├── lla_test.rb
│   ├── ecef_test.rb
│   ├── utm_test.rb
│   ├── mgrs_test.rb
│   ├── enu_test.rb
│   ├── ned_test.rb
│   ├── web_mercator_test.rb
│   ├── geoid_height_test.rb
│   ├── circle_area_test.rb
│   ├── polygon_area_test.rb
│   └── chain_conversion_test.rb
├── examples/
│   ├── basic_conversions.rb
│   └── all_coordinate_systems.rb
├── geodetic.gemspec
├── Gemfile
├── Rakefile
├── README.md
├── CHANGELOG.md
└── LICENSE
```

## gemspec Sketch

```ruby
Gem::Specification.new do |spec|
  spec.name     = "geodetic"
  spec.version  = Geodetic::VERSION
  spec.authors  = ["Dewayne VanHoozer"]
  spec.email    = ["dvanhoozer@gmail.com"]
  spec.summary  = "Pure-Ruby geodetic coordinate system conversions"
  spec.description = "Convert between LLA, ECEF, UTM, MGRS, NED, ENU, " \
                     "Web Mercator, and more. Supports 14 geodetic datums, " \
                     "geoid height models, and area containment testing. " \
                     "No C extensions or external dependencies."
  spec.homepage = "https://github.com/madbomber/geodetic"
  spec.license  = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.files = Dir["lib/**/*.rb", "LICENSE", "README.md", "CHANGELOG.md"]
  spec.require_paths = ["lib"]
end
```
