# Fetch NOAA CRW DHW for an `sf` feature's bounding box

Convenience wrapper that:

1.  transforms the feature geometry to WGS84 (EPSG:4326),

2.  extracts its bounding box (xmin/xmax = lon, ymin/ymax = lat), and

3.  queries CRW DHW in yearly chunks via
    [`get_crw_dhw_bbox()`](https://pristine-seas.github.io/PristineSeasR2/reference/get_crw_dhw_bbox.md).

## Usage

``` r
get_crw_dhw_sf(
  feature,
  start = "2015-01-01",
  end = "2024-12-31",
  name_col = "atoll",
  out_col = "feature",
  summarise_daily = TRUE,
  timeout_sec = 300,
  pause_sec = 0.2,
  verbose = TRUE
)
```

## Arguments

- feature:

  A single-row `sf` object (one feature geometry).

- start, end:

  Date range (YYYY-MM-DD or Date).

- name_col:

  Name of the column in `feature` that holds the feature identifier.
  This column can have any name (e.g., `"atoll"`, `"name"`, `"site"`,
  `"reef"`, `"id"`).

- out_col:

  Name of the output column used to store the feature identifier.
  Default is `"feature"`. Set to `"atoll"` if you want an `atoll`
  column.

- summarise_daily:

  If TRUE (default), return daily mean DHW for the bbox. If FALSE,
  return raw gridded DHW values for the bbox.

- timeout_sec:

  Request timeout (seconds).

- pause_sec:

  Pause between yearly requests (seconds).

- verbose:

  If TRUE, prints progress messages (feature + year).

## Value

If `summarise_daily = TRUE`: tibble with columns `{out_col}`, `date`,
`avg_dhw`. If `summarise_daily = FALSE`: tibble with columns
`{out_col}`, `date`, `latitude`, `longitude`, `dhw`.

## Details

By default, returns a **daily mean DHW** across all grid points in the
bbox. Set `summarise_daily = FALSE` to return raw gridded values (one
row per grid cell per day).

## Examples

``` r
if (FALSE) { # \dontrun{
# AOIs is an sf object with a column identifying each feature.
# The identifier column does NOT need to be named "atoll".

# ---- Example: single feature ----
jemo <- AOIs[AOIs$name == "Jemo", ]

jemo_dhw <- get_crw_dhw_sf(
  jemo,
  start = "2015-01-01", end = "2024-12-31",
  name_col = "name",
  out_col  = "feature"
)

# ---- Example: two features ----
subset <- AOIs[AOIs$name %in% c("Jemo", "Taka"), ]

dhw_two <- purrr::map_dfr(seq_len(nrow(subset)), \(i)
  get_crw_dhw_sf(
    subset[i, ],
    start = "2015-01-01", end = "2024-12-31",
    name_col = "name",
    out_col  = "feature"
  )
)
} # }
```
