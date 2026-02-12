# Discrete fill scale using Pristine Seas palettes

Convenience wrapper around
[`ggplot2::scale_fill_manual()`](https://ggplot2.tidyverse.org/reference/scale_manual.html)
that pulls colors from the Pristine Seas palette system via
[`ps_colors()`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_colors.md).

## Usage

``` r
scale_fill_ps(palette, ...)
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

A ggplot2 fill scale.

## Details

This is intended for discrete fill aesthetics where factor levels in
your data match the names of a palette (for example, `trophic_group`,
`functional_groups`, `uvs_habitats`, `region`, or `subregion`).

## Examples

``` r
if (FALSE) { # \dontrun{
library(ggplot2)
library(tibble)

df <- tibble(
  habitat = names(ps_colors("uvs_habitats")),
  value   = runif(length(habitat))
)

ggplot(df, aes(x = habitat, y = value, fill = habitat)) +
  geom_col() +
  scale_fill_ps("uvs_habitats") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
} # }
```
