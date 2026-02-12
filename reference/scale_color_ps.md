# Discrete color scale using Pristine Seas palettes

Convenience wrapper around
[`ggplot2::scale_color_manual()`](https://ggplot2.tidyverse.org/reference/scale_manual.html)
that pulls colors from the Pristine Seas palette system via
[`ps_colors()`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_colors.md).

## Usage

``` r
scale_color_ps(palette, ...)
```

## Arguments

- palette:

  Character. Palette name passed to
  [`ps_colors()`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_colors.md).
  Should return a named vector (not the hierarchical `regions` list).

- ...:

  Additional arguments passed to
  [`ggplot2::scale_color_manual()`](https://ggplot2.tidyverse.org/reference/scale_manual.html).

## Value

A ggplot2 color scale.

## Details

This is intended for discrete color aesthetics where factor levels in
your data match the names of a palette (for example, `trophic_group`,
`functional_groups`, `region`, or `subregion`).

## Examples

``` r
if (FALSE) { # \dontrun{
library(ggplot2)
library(tibble)

df <- tibble(
  trophic_group = names(ps_colors("trophic_group")),
  x             = seq_along(trophic_group),
  y             = runif(length(trophic_group))
)

ggplot(df, aes(x = x, y = y, color = trophic_group)) +
  geom_point(size = 3) +
  scale_color_ps("trophic_group") +
  theme_minimal()
} # }
```
