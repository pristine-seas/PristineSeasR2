# Build the Interactive Recruit Density Map (Circle Markers by Site)

Builds the standard Pristine Seas per-site coral recruit map:
station-level recruit density is averaged up to one circle marker per
site, with both marker size and color driven by mean density
(recruits/m²). Taxa richness, quadrat effort, and total recruit count
are shown as informational rows in every popup, independent of the
color/size encoding. This is the same map used across UVS/recruits
reports, so calling it reproduces the exact same metric, colors, and
layout expedition to expedition.

## Usage

``` r
explore_recruit_density(
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
  `recruits_stations`. Must include `ps_site_id`, `divers`,
  `depth_strata`, `depth_m`, `n_taxa`, `n_quadrats`, `total_count`, and
  `avg_density_m2`.

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
m <- explore_recruit_density(
  stations    = recruits_stations,
  sites       = uvs_sites,
  title       = "Vanuatu 2025 Expedition — Recruit survey results",
  export_path = file.path(data_out, "recruits_results_map.html")
)
m
} # }
```
