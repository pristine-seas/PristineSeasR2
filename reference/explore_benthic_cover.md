# Build the Interactive Benthic Cover Map (Pie Charts by Site)

Builds the standard Pristine Seas per-site benthic cover map:
station-level percent cover is averaged up to one site, then shown as a
pie chart on a satellite basemap, with a rich popup (location, habitat,
exposure, station count, dive team) and a legend of functional-group
colors. This is the same map used across UVS/LPI benthic reports, so
calling it with the default `cover_groups` reproduces the exact same
groups, colors, and layout expedition to expedition.

## Usage

``` r
explore_benthic_cover(
  stations,
  sites,
  title = NULL,
  subtitle = "National Geographic Pristine Seas",
  export_path = NULL,
  cover_groups = default_benthic_cover_groups()
)
```

## Arguments

- stations:

  A station-level data frame (one row per station), such as
  `lpi_stations`. Must include `ps_site_id`, `region`, `subregion`,
  `locality`, `habitat`, `exposure`, `divers`, and the percent-cover
  columns referenced by `cover_groups$cols`. A cover column that's
  missing entirely is treated as 0 for that group, so a protocol that
  doesn't track every group still works.

- sites:

  A site-level data frame with `ps_site_id`, `longitude`, and `latitude`
  — such as the validated UVS sites table — used to attach coordinates.
  Every site referenced in `stations` must have a match here.

- title:

  Map title shown in the banner on the *exported* standalone map only
  (see `export_path`) — not shown on the version this function returns,
  since an inline report already has its own section heading. Required
  if `export_path` is supplied.

- subtitle:

  Small text under the title in the exported map's banner. Set to `""`
  to hide it. Default `"National Geographic Pristine Seas"`.

- export_path:

  If supplied, a self-contained standalone HTML copy of the map (with
  the title banner) is saved to this path via
  [`htmlwidgets::saveWidget()`](https://rdrr.io/pkg/htmlwidgets/man/saveWidget.html).
  If `NULL` (the default), nothing is saved.

- cover_groups:

  A data frame with columns `group` (display name), `cols` (one or more
  `stations` column names, comma-separated, summed into this group), and
  `color` (hex color for the pie slice/legend). Defaults to
  [`default_benthic_cover_groups()`](https://pristine-seas.github.io/PristineSeasR2/reference/default_benthic_cover_groups.md);
  override only if a protocol's cover columns genuinely differ from the
  LPI standard.

## Value

A `leaflet` htmlwidget (without the title banner) — print it directly to
display it, e.g. as the last expression in a report chunk.

## Examples

``` r
if (FALSE) { # \dontrun{
m <- explore_benthic_cover(
  stations    = lpi_stations,
  sites       = uvs_sites,
  title       = "Vanuatu 2025 Expedition — Benthic composition",
  export_path = file.path(data_out, "lpi_results_map.html")
)
m
} # }
```
