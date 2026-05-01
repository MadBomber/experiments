# TODO

## Complete state CSV files with elevation data

The CSV files for TX, OK, LA, and AR cities/towns/villages were generated from
the 2024 US Census Bureau Gazetteer. Elevation data was fetched from the
Open-Meteo Elevation API but rate limiting left many entries at 0.0 altitude.

### Status

| File | Total Places | Missing Altitude | Status |
|------|-------------|-----------------|--------|
| ar_places.csv | 625 | 0 | Complete |
| la_places.csv | 489 | 17 | Needs fix |
| ok_places.csv | 846 | 746 | Needs fix |
| tx_places.csv | 1863 | 1265 | Needs fix |

### To complete

Re-run elevation queries against the Open-Meteo API with smaller batch sizes
(50 per request) and longer delays (1.5s+ between batches) to avoid the
per-minute rate limit. The repair script at `/tmp/fix_elevations.rb` has the
logic ready — just needs to be run when the API quota resets.

### Data sources

- Census Gazetteer: https://www2.census.gov/geo/docs/maps-data/data/gazetteer/2024_Gazetteer/
- Open-Meteo Elevation API: https://open-meteo.com/en/docs/elevation-api
