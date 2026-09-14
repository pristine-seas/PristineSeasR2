# Changelog

## PristineSeasR2 (development version)

### Data

- `rmi_2023_uvs_sites` bundles the 60 survey sites of the 2023 Marshall
  Islands expedition, a dated snapshot of `pristine-seas.uvs.sites` in
  BigQuery taken by the script in `data-raw/`, so examples, articles and
  tests have a real expedition to draw on without a database or Drive
  connection.

### Report maps

- [`map_uvs_sites()`](https://pristine-seas.github.io/PristineSeasR2/reference/map_uvs_sites.md)
  draws the survey sites of a region or subregion as a ggplot on one of
  four basemaps: Esri World Imagery by default, Mapbox Satellite with
  `basemap = "mapbox"` and a token in `MAPBOX_TOKEN`, or the Global
  Islands coastline drawn in the theme’s land ink with
  `basemap = "coast"`, fetched live from UNEP-WCMC so nothing needs to
  be on disk, or the National Geographic World Map with
  `basemap = "natgeo"` for the regional view. On every one of them
  habitat sets each marker’s shape, exposure its fill, the canvas is
  [`theme_ps_map()`](https://pristine-seas.github.io/PristineSeasR2/reference/theme_ps_map.md),
  and a scale bar and north arrow sit quietly in the corners, with a
  locator globe in the top right unless `locator = FALSE`. The frame
  fits the sites chosen, with a floor on how narrow it may be so a tight
  cluster still shows its reef; `expand` loosens or tightens it and
  `extent` sets it outright, and every map hands back the frame it drew
  as `attr(p, "extent")`. The static counterpart to
  [`explore_uvs_sites()`](https://pristine-seas.github.io/PristineSeasR2/reference/explore_uvs_sites.md).
  `label_sites = TRUE` numbers each marker with the digits that end its
  `ps_site_id`, placed by **ggrepel**. Needs **maptiles**, **tidyterra**
  and **ggspatial**, which it offers to install on first use.

### Colour system

The data palettes were redrawn as one coordinated system, measured with
CIEDE2000 under normal vision, the three dichromacies and greyscale. The
[colour system
article](https://pristine-seas.github.io/PristineSeasR2/articles/colour-system.html)
on the package site shows every palette under each simulation, its
distinctiveness, and how the pieces sit together on a chart and on a
map.

- [`ps_colors()`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_colors.md)
  now carries five palettes: `depth_strata`, `trophic_group`,
  `benthic_cover`, `exposure` and `habitat`. Keys match `allowed_vocab`,
  so a validated factor lands on its colour without a lookup.

- [`ps_habitat_colors()`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_habitat_colors.md)
  reassigns the five habitat slots, in order, to the habitats a trip
  sampled.

- [`ps_shapes()`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_shapes.md)
  and
  [`scale_shape_ps()`](https://pristine-seas.github.io/PristineSeasR2/reference/scale_shape_ps.md)
  add the first shape palette. `habitat` covers every level of the
  vocabulary in three tiers: filled shapes for the zones sampled on most
  trips, open for the occasional ones, line for the rare. On a map,
  exposure fills the marker and habitat sets its shape.

### Drive paths

- [`ps_science_paths()`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_science_paths.md)
  is now the one way to find the shared SCIENCE folder, and it is built
  to be found by anyone on the team. It searches every Google Drive
  account on the machine, ngs.org or personal, looks in My Drive, Shared
  drives and the shortcuts Drive creates for folders shared with you,
  and works on macOS and Windows. A hit must actually hold `datasets`,
  `expeditions` or `projects`; ngs.org accounts win ties. When nothing
  is found it lists every location it searched and the three ways to fix
  it. `PS_SCIENCE_PATH` still overrides everything.
  [`get_drive_paths()`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_science_paths.md)
  is kept as a plain alias.

### Breaking

- The `functional_groups`, `uvs_habitats`, `trophic_group2`,
  `functional_groups2` and `invert_groups` palettes are gone. Use
  `benthic_cover` and `habitat`; the benthic keys now spell the algae
  the way the vocabulary does (`algae_erect`, not `erect_algae`). The
  invertebrate palette is kept as a comment in `R/colors.R` should it be
  revisited.

- [`explore_uvs_sites()`](https://pristine-seas.github.io/PristineSeasR2/reference/explore_uvs_sites.md)
  defaults its `habitat_palette` to the new `habitat` palette. Pass
  `ps_habitat_colors(<habitats present>)` for a trip that sampled other
  zones.

## PristineSeasR2 0.2.0

### New

- [`explore_s2_detections()`](https://pristine-seas.github.io/PristineSeasR2/reference/explore_s2_detections.md)
  maps Global Fishing Watch Sentinel-2 vessel detections on satellite
  imagery, each popup opening the Sentinel-2 crop the detection was made
  from with its exact position ringed at the centre. Crops are rendered
  by Earth Engine, cached as PNGs and inlined into the page, so an
  exported map opens for anyone — no Earth Engine account, no
  credentials, only the basemap fetched live. Optionally shows several
  stretches side by side (`view = c("ocean", "nir")`) and gives the
  exported page a score-ordered thumbnail gallery linked to the map in
  both directions.

- [`ee_connect()`](https://pristine-seas.github.io/PristineSeasR2/reference/ee_connect.md)
  opens the `rgee` connection those crops render through. It is only
  reached when a crop is not already cached, so a warm cache needs no
  credentials at all.

### Renamed

Both old names still work, as plain aliases with no warning. Nothing
needs updating; new code should prefer the new names.

- [`light_gt()`](https://pristine-seas.github.io/PristineSeasR2/reference/gt_theme_ps_light.md)
  is now
  [`gt_theme_ps_light()`](https://pristine-seas.github.io/PristineSeasR2/reference/gt_theme_ps_light.md),
  so it sits beside
  [`gt_theme_ps()`](https://pristine-seas.github.io/PristineSeasR2/reference/gt_theme_ps.md)
  and follows the same shape as
  [`theme_ps()`](https://pristine-seas.github.io/PristineSeasR2/reference/theme_ps.md)
  →
  [`theme_ps_map()`](https://pristine-seas.github.io/PristineSeasR2/reference/theme_ps_map.md).

- [`ps_theme_colors()`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_ink.md)
  is now
  [`ps_ink()`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_ink.md).
  The old name read as a transposition of
  [`theme_ps()`](https://pristine-seas.github.io/PristineSeasR2/reference/theme_ps.md)
  and was easily confused with
  [`ps_colors()`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_colors.md)
  — which returns categorical palettes for *data*, where
  [`ps_ink()`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_ink.md)
  returns the ink of the *canvas*: panel, grid, title, land, coast, eez.

### Fixes

- [`ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html) to
  PDF no longer fails. [`pdf()`](https://rdrr.io/r/grDevices/pdf.html)
  matches font families against the PostScript font database rather than
  the system, and under grid an unknown family is a hard error, not a
  substitution — so any resolved family that is not a base PostScript
  name (Inter, Helvetica Neue) broke every PDF export.
  [`ps_font_default()`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_font_default.md)
  now registers the family with
  [`pdf()`](https://rdrr.io/r/grDevices/pdf.html), aliased onto
  Helvetica’s metrics.

- Exporting a map no longer leaves a `<name>_files/` folder beside it.
  Every `explore_*` function had been shedding about a megabyte of
  unreferenced dependencies next to each self-contained HTML.

- `crw_dhw()` takes its columns from the data rather than from the
  calling environment, so a stray global of the same name can no longer
  shadow one.

## PristineSeasR2 0.1.0

- First versioned release.
