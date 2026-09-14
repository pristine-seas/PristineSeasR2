# PristineSeasR2 (development version)

## Data

* `rmi_2023_uvs_blt_stations` bundles the 104 fish belt-transect stations of
  the same expedition, a snapshot of `pristine-seas.uvs.blt_stations`, with
  survey effort, fish density and biomass, and the share of biomass in each
  trophic group, so the figures in the README and articles draw on real
  survey results.

* `rmi_2023_uvs_sites` bundles the 60 survey sites of the 2023 Marshall
  Islands expedition, a dated snapshot of `pristine-seas.uvs.sites` in
  BigQuery taken by the script in `data-raw/`, so examples, articles and tests
  have a real expedition to draw on without a database or Drive connection.

## Report maps

* `map_uvs_sites()` draws the survey sites of a region or subregion as a
  ggplot on one of four basemaps: Esri World Imagery by default, Mapbox
  Satellite with `basemap = "mapbox"` and a token in `MAPBOX_TOKEN`, or the
  Global Islands coastline drawn in the theme's land ink with
  `basemap = "coast"`, fetched live from UNEP-WCMC so nothing needs to be on
  disk, or the National Geographic World Map with `basemap = "natgeo"` for
  the regional view. On every one of them habitat sets each marker's shape, exposure its
  fill, the canvas is `theme_ps_map()`, and a scale bar and north arrow sit
  quietly in the corners, with a locator globe in the top right unless
  `locator = FALSE`. The frame fits the sites chosen, with a floor on how
  narrow it may be so a tight cluster still shows its reef; `expand` loosens
  or tightens it and `extent` sets it outright, and every map hands back the
  frame it drew as `attr(p, "extent")`. The static
  counterpart to `explore_uvs_sites()`. `label_sites = TRUE` numbers each
  marker with the digits that end its `ps_site_id`, placed by **ggrepel**.
  `export` writes the map to a file, a report-ready PDF through Cairo, sized
  to the frame's proportions. Needs **maptiles**, **tidyterra** and
  **ggspatial**, which it offers to install on first use.

## Colour system

The data palettes were redrawn as one coordinated system, measured with
CIEDE2000 under normal vision, the three dichromacies and greyscale. The
[colour system article](https://pristine-seas.github.io/PristineSeasR2/articles/colour-system.html)
on the package site shows every palette under each simulation, its
distinctiveness, and how the pieces sit together on a chart and on a map.

* `ps_colors()` now carries five palettes: `depth_strata`, `trophic_group`,
  `benthic_cover`, `exposure` and `habitat`. Keys match `allowed_vocab`, so a
  validated factor lands on its colour without a lookup.

* `ps_habitat_colors()` reassigns the five habitat slots, in order, to the
  habitats a trip sampled.

* `ps_shapes()` and `scale_shape_ps()` add the first shape palette. `habitat`
  covers every level of the vocabulary in three tiers: filled shapes for the
  zones sampled on most trips, open for the occasional ones, line for the
  rare. On a map, exposure fills the marker and habitat sets its shape.

## Drive paths

* `ps_science_paths()` is now the one way to find the shared SCIENCE folder,
  and it is built to be found by anyone on the team. It searches every Google
  Drive account on the machine, ngs.org or personal, looks in My Drive, Shared
  drives and the shortcuts Drive creates for folders shared with you, and works
  on macOS and Windows. A hit must actually hold `datasets`, `expeditions` or
  `projects`; ngs.org accounts win ties. When nothing is found it lists every
  location it searched and the three ways to fix it. `PS_SCIENCE_PATH` still
  overrides everything. `get_drive_paths()` is kept as a plain alias.

## Breaking

* The `functional_groups`, `uvs_habitats`, `trophic_group2`,
  `functional_groups2` and `invert_groups` palettes are gone. Use
  `benthic_cover` and `habitat`; the benthic keys now spell the algae the way
  the vocabulary does (`algae_erect`, not `erect_algae`). The invertebrate
  palette is kept as a comment in `R/colors.R` should it be revisited.

* `explore_uvs_sites()` defaults its `habitat_palette` to the new `habitat`
  palette. Pass `ps_habitat_colors(<habitats present>)` for a trip that sampled
  other zones.

# PristineSeasR2 0.2.0

## New

* `explore_s2_detections()` maps Global Fishing Watch Sentinel-2 vessel
  detections on satellite imagery, each popup opening the Sentinel-2 crop the
  detection was made from with its exact position ringed at the centre. Crops
  are rendered by Earth Engine, cached as PNGs and inlined into the page, so an
  exported map opens for anyone — no Earth Engine account, no credentials, only
  the basemap fetched live. Optionally shows several stretches side by side
  (`view = c("ocean", "nir")`) and gives the exported page a score-ordered
  thumbnail gallery linked to the map in both directions.

* `ee_connect()` opens the `rgee` connection those crops render through. It is
  only reached when a crop is not already cached, so a warm cache needs no
  credentials at all.

## Renamed

Both old names still work, as plain aliases with no warning. Nothing needs
updating; new code should prefer the new names.

* `light_gt()` is now `gt_theme_ps_light()`, so it sits beside `gt_theme_ps()`
  and follows the same shape as `theme_ps()` → `theme_ps_map()`.

* `ps_theme_colors()` is now `ps_ink()`. The old name read as a transposition of
  `theme_ps()` and was easily confused with `ps_colors()` — which returns
  categorical palettes for *data*, where `ps_ink()` returns the ink of the
  *canvas*: panel, grid, title, land, coast, eez.

## Fixes

* `ggsave()` to PDF no longer fails. `pdf()` matches font families against the
  PostScript font database rather than the system, and under grid an unknown
  family is a hard error, not a substitution — so any resolved family that is
  not a base PostScript name (Inter, Helvetica Neue) broke every PDF export.
  `ps_font_default()` now registers the family with `pdf()`, aliased onto
  Helvetica's metrics.

* Exporting a map no longer leaves a `<name>_files/` folder beside it. Every
  `explore_*` function had been shedding about a megabyte of unreferenced
  dependencies next to each self-contained HTML.

* `crw_dhw()` takes its columns from the data rather than from the calling
  environment, so a stray global of the same name can no longer shadow one.

# PristineSeasR2 0.1.0

* First versioned release.
