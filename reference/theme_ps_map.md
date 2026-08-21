# Pristine Seas map theme

The house ggplot2 theme for maps: deep water, a barely-there graticule,
a hairline panel frame, and no axis titles. The dark canvas is the
working part of the design — the layers Pristine Seas maps carry are
sparse and log-distributed (fishing effort, thermal stress, habitat
suitability), and on a light ground they wash out. Here the data is the
only bright thing on the page.

Shares its type scale, legend geometry, and title hierarchy with
[`theme_ps()`](https://pristine-seas.github.io/PristineSeasR2/reference/theme_ps.md),
so a map and a chart can sit side by side on one page and read as a
pair.

## Usage

``` r
theme_ps_map(base_size = 12, base_family = ps_font_default(), graticule = TRUE)
```

## Arguments

- base_size:

  Numeric. Base font size in points; every other size is a step from it.
  Default 12. Large-format maps usually want 13–16.

- base_family:

  Character. Base font family. Defaults to
  [`ps_font_default()`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_font_default.md)
  — Inter where it is installed, otherwise Helvetica.

- graticule:

  Logical. Draw longitude/latitude grid lines. Default `TRUE`.

## Value

A ggplot2 theme object.

## Drawing on it

The theme paints the canvas; the geography is yours to draw. Take its
colors from
[`ps_ink()`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_ink.md)
so they land in the same key:

    ink <- ps_ink("map")

    ggplot() +
      geom_spatraster(data = effort) +
      geom_spatvector(data = land, fill = ink[["land"]], colour = ink[["coast"]]) +
      geom_spatvector(data = eez,  fill = NA, colour = ink[["eez"]], linetype = "22") +
      theme_ps_map()

A continuous fill wants a wide, thin bar along the bottom; a categorical
key reads better stacked at the right. In ggplot2 3.5 and later each
guide can choose for itself, so the two need not compete for one strip:

    guide_colourbar(position = "bottom")
    guide_legend(position = "right", direction = "vertical")

## Exporting

Nothing special is required. The theme paints an opaque
`plot.background` over the whole plot, and
[`ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html) reads
that fill when its own `bg` is unset — so a saved map carries its canvas
without being told:

    ggsave("map.png", p, width = 11, height = 10, dpi = 400)

Passing `bg` only changes anything if `plot.background` has been blanked
or made transparent. See
[`ps_font_default()`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_font_default.md)
for the one device caveat that does matter —
[`pdf()`](https://rdrr.io/r/grDevices/pdf.html), which cannot see system
fonts and is handled by aliasing the family onto Helvetica rather than
by failing.

## See also

[`theme_ps()`](https://pristine-seas.github.io/PristineSeasR2/reference/theme_ps.md)
for charts,
[`ps_ink()`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_ink.md)
for the palette behind both.

## Examples

``` r
library(ggplot2)

ink <- ps_ink("map")

ggplot(faithfuld, aes(waiting, eruptions, fill = density)) +
  geom_raster() +
  scale_fill_viridis_c(option = "inferno", name = "Density") +
  labs(title    = "A dark canvas for sparse layers",
       subtitle = "The data is the only bright thing on the page") +
  theme_ps_map()
```
