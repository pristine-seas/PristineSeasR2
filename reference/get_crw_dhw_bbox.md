# Fetch NOAA CRW DHW (Degree Heating Week) for a bounding box (bbox)

Query NOAA CoastWatch ERDDAP for NOAA Coral Reef Watch (CRW) **Degree
Heating Week** (DHW; units = °C-weeks) daily values within a lat/lon
bounding box. Requests are chunked by year to keep responses manageable
and more reliable.

## Usage

``` r
get_crw_dhw_bbox(
  lat_min,
  lat_max,
  lon_min,
  lon_max,
  start = "2015-01-01",
  end = "2024-12-31",
  timeout_sec = 300,
  pause_sec = 0.2,
  verbose = TRUE
)
```

## Arguments

- lat_min, lat_max:

  Latitude bounds (decimal degrees, WGS84).

- lon_min, lon_max:

  Longitude bounds (decimal degrees, WGS84).

- start, end:

  Date range (YYYY-MM-DD or Date). `end` must be \>= `start`.

- timeout_sec:

  Request timeout (seconds).

- pause_sec:

  Pause between yearly requests (seconds).

- verbose:

  If TRUE, prints progress messages per year.

## Value

A tibble with columns: `date`, `latitude`, `longitude`, `dhw`.

## Details

Data source: ERDDAP dataset `noaacrwdhwDaily`, variable
`degree_heating_week`.

## Examples

``` r
if (FALSE) { # \dontrun{
dhw <- get_crw_dhw_bbox(
  lat_min = 10.0, lat_max = 10.2,
  lon_min = 169.4, lon_max = 169.7,
  start = "2015-01-01", end = "2015-12-31"
)
} # }
```
