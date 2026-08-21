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
