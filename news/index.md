# Changelog

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
