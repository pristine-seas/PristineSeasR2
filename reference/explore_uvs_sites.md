# Build the Interactive UVS Sites Map (Color-By Region/Subregion/Habitat/Exposure)

Builds the standard Pristine Seas UVS site map: one marker per site,
with a "Color by" toggle (top right) to recolor markers by region,
subregion, habitat, or exposure, a rich popup (location, habitat,
exposure, survey date, MPA status, notes), and a search box (top left)
to jump to a site by ID or name. This is the same map used across UVS
site reports, so calling it with the standard habitat/exposure palettes
reproduces the exact same look expedition to expedition.

## Usage

``` r
explore_uvs_sites(
  sites,
  region_palette,
  subregion_palette,
  habitat_palette = ps_colors("uvs_habitats"),
  exposure_palette = ps_colors("exposure"),
  title = NULL,
  subtitle = "National Geographic Pristine Seas",
  export_path = NULL
)
```

## Arguments

- sites:

  A site-level data frame (one row per site), such as the validated UVS
  sites table. Must include `ps_site_id`, `longitude`, `latitude`,
  `region`, `subregion`, `habitat`, and `exposure`. Optional columns
  used in the popup if present: `site_name`, `locality`, `date`, `time`,
  `in_mpa`, `mpa_notes`, `notes`.

- region_palette, subregion_palette:

  Named character vectors mapping each region/subregion name to a hex
  color. Expedition-specific (region and subregion names differ every
  expedition), so there's no default — define these once in the
  expedition's setup script.

- habitat_palette, exposure_palette:

  Named character vectors mapping each habitat/exposure category to a
  hex color. Default to
  [`ps_colors()`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_colors.md)'s
  `"uvs_habitats"` and `"exposure"` palettes, which are fixed taxonomies
  shared across every expedition. A level with no color in the supplied
  palette gets a generated fallback color (with a warning) rather than
  failing.

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
m <- explore_uvs_sites(
  sites             = uvs_sites,
  region_palette    = region_palette,
  subregion_palette = subregion_palette,
  title             = "Vanuatu 2025 Expedition — Underwater Visual Survey sites",
  export_path       = file.path(data_out, "dive_site_map.html")
)
m
} # }
```
