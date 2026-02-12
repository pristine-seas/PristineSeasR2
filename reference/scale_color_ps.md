# Discrete color scale using Pristine Seas palettes

Convenience wrapper around
[`ggplot2::scale_color_manual()`](https://ggplot2.tidyverse.org/reference/scale_manual.html)
that pulls colors from
[`ps_colors()`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_colors.md).

## Usage

``` r
scale_color_ps(palette, drop = FALSE, ...)
```

## Arguments

- palette:

  Character. Palette name passed to
  [`ps_colors()`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_colors.md).

- drop:

  Logical. Passed to
  [`ggplot2::scale_color_manual()`](https://ggplot2.tidyverse.org/reference/scale_manual.html).
  Default `FALSE` to preserve palette order even if levels are unused.

- ...:

  Additional arguments passed to
  [`ggplot2::scale_color_manual()`](https://ggplot2.tidyverse.org/reference/scale_manual.html).

## Value

A ggplot2 color scale.

## Details

Intended for discrete color aesthetics where factor levels match palette
names.

## See also

[`scale_fill_ps()`](https://pristine-seas.github.io/PristineSeasR2/reference/scale_fill_ps.md)
for fill aesthetic,
[`ps_colors()`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_colors.md)
for raw palettes

## Examples

``` r
library(ggplot2)

# Species diversity by habitat (points with error bars)
diversity <- data.frame(habitat = factor(c("fore_reef", "back_reef", "patch_reef"),
                                         levels = names(ps_colors("uvs_habitats"))),
                        species_richness = c(42, 35, 20),
                        se = c(10, 8, 9))

ggplot(diversity,
       aes(x = species_richness, y = habitat, color = habitat)) +
  geom_point(size = 4) +
  geom_errorbar(aes(xmin = species_richness - se, xmax = species_richness + se), width = 0.2) +
  scale_color_ps("uvs_habitats", drop = TRUE) +
  labs(x = "Species richness", y = NULL) +
  theme_ps()

```
