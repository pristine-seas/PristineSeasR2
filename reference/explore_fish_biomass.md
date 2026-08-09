# Build the Interactive Fish Survey Results Map (Metric Toggle by Site)

Builds the standard Pristine Seas per-site fish survey map:
station-level taxa richness, density, and biomass are averaged up to one
circle marker per site, with both marker size and color driven by
whichever metric is active. A layer control (top right) toggles between
the three metrics, swapping the color ramp and the gradient legend
(bottom right) to match. This is the same map used across UVS/BLT fish
reports, so calling it reproduces the exact same metrics, colors, and
layout expedition to expedition.

## Usage

``` r
explore_fish_biomass(
  stations,
  sites,
  title = NULL,
  subtitle = "National Geographic Pristine Seas",
  export_path = NULL
)
```

## Arguments

- stations:

  A station-level data frame (one row per station), such as
  `station_summary`. Must include `ps_site_id`, `divers`,
  `depth_strata`, `depth_m`, `n_taxa`, `avg_density_m2`, and
  `avg_biomass_gm2`.

- sites:

  A site-level data frame with `ps_site_id`, `longitude`, `latitude`,
  `region`, `subregion`, `locality`, `habitat`, and `exposure` — such as
  the validated UVS sites table — used to attach coordinates and
  metadata. Every site referenced in `stations` must have a match here.

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

## Value

A `leaflet` htmlwidget (without the title banner) — print it directly to
display it, e.g. as the last expression in a report chunk.

## Examples

``` r
if (FALSE) { # \dontrun{
m <- explore_fish_biomass(
  stations    = station_summary,
  sites       = uvs_sites,
  title       = "Vanuatu 2025 Expedition — Fish survey results",
  export_path = file.path(data_out, "blt_results_map.html")
)
m
} # }
```
