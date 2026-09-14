# Discrete shape scale using Pristine Seas shape palettes

Convenience wrapper around
[`ggplot2::scale_shape_manual()`](https://ggplot2.tidyverse.org/reference/scale_manual.html)
that pulls shapes from
[`ps_shapes()`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_shapes.md),
the way
[`scale_fill_ps()`](https://pristine-seas.github.io/PristineSeasR2/reference/scale_fill_ps.md)
pulls colours from
[`ps_colors()`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_colors.md).

## Usage

``` r
scale_shape_ps(palette, drop = FALSE, ...)
```

## Arguments

- palette:

  Character. Shape palette name passed to
  [`ps_shapes()`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_shapes.md).

- drop:

  Logical. Passed to
  [`ggplot2::scale_shape_manual()`](https://ggplot2.tidyverse.org/reference/scale_manual.html).
  Default `FALSE` to preserve palette order even if levels are unused.

- ...:

  Additional arguments passed to
  [`ggplot2::scale_shape_manual()`](https://ggplot2.tidyverse.org/reference/scale_manual.html).

## Value

A ggplot2 shape scale.

## Details

Filled shapes (21 to 25) take their interior from the `fill` aesthetic
and their outline from `colour`, so a site map that sets
`fill = exposure` and `shape = habitat` needs both
`scale_fill_ps("exposure")` and this scale. Open and line shapes draw
entirely in `colour` and ignore `fill`.

## Examples

``` r
library(ggplot2)

# Sites on a map: exposure fills the marker, habitat sets its shape
sites <- data.frame(
  lon      = c(-171.2, -171.1, -171.3, -171.0, -171.15),
  lat      = c(-13.9, -13.8, -13.85, -13.95, -13.75),
  habitat  = c("fore_reef", "back_reef", "patch_reef", "wall", "channel_pass"),
  exposure = c("windward", "lagoon", "sheltered", "exposed", "channel")
)

ggplot(sites, aes(lon, lat, shape = habitat, fill = exposure)) +
  geom_point(size = 4, colour = ps_ink("map")[["title"]], stroke = 0.6) +
  scale_shape_ps("habitat", drop = TRUE) +
  scale_fill_ps("exposure", drop = TRUE) +
  guides(fill = guide_legend(override.aes = list(shape = 21))) +
  theme_ps_map()

```
