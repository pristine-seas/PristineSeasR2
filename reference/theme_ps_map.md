# Pristine Seas map theme (ggplot2)

Clean, publication-ready map theme with optional graticule/grid lines.

## Usage

``` r
theme_ps_map(default_font_family = "Hind", show_grid = TRUE, ...)
```

## Arguments

- default_font_family:

  Character. Base font family (e.g., "Hind").

- show_grid:

  Logical. If TRUE, show major grid lines (useful for lon/lat
  graticules).

- ...:

  Additional arguments passed to
  [`ggplot2::theme()`](https://ggplot2.tidyverse.org/reference/theme.html).

## Value

A ggplot2 theme object.
