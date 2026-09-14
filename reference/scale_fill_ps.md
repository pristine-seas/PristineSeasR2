# Discrete fill scale using Pristine Seas palettes

Convenience wrapper around
[`ggplot2::scale_fill_manual()`](https://ggplot2.tidyverse.org/reference/scale_manual.html)
that pulls colors from
[`ps_colors()`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_colors.md).

## Usage

``` r
scale_fill_ps(palette, drop = FALSE, ...)
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

A ggplot2 fill scale.

## See also

[`scale_color_ps()`](https://pristine-seas.github.io/PristineSeasR2/reference/scale_color_ps.md)
for color aesthetic,
[`ps_colors()`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_colors.md)
for raw palettes

## Examples

``` r
library(ggplot2)

# Benthic cover composition (stacked bar) - all functional groups

benthic <- data.frame(site             = rep(c("Site A", "Site B"), each = 11),
                     functional_group = factor(rep(names(ps_colors("benthic_cover")), 2),
                                               levels = rev(names(ps_colors("benthic_cover")))),
                     cover            = c(52, 20, 2, 4, 2, 3, 2, 1, 6, 7, 1,
                                          14, 8, 4, 4, 4, 5, 18, 2, 12, 23, 6))

ggplot(benthic,
       aes(x = site, y = cover, fill = functional_group)) +
  geom_col(position = "stack") +
  scale_fill_ps("benthic_cover") +
  labs(x = NULL, y = "Cover (%)", fill = "Functional group") +
  theme_ps()


# Fish biomass by trophic group (stacked bar)

fish_trophic <- data.frame(site = rep(c("Protected", "Fished"), each = 5),
                           trophic_group = factor(rep(names(ps_colors("trophic_group")), 2),
                                                  levels = rev(names(ps_colors("trophic_group")))),
                           biomass = c(45, 120, 180, 210, 95, 5, 35, 150, 190, 80) / 2)

ggplot(fish_trophic,
       aes(x = site, y = biomass, fill = trophic_group)) +
  geom_col(position = "stack") +
  scale_fill_ps("trophic_group") +
  labs(x = NULL, y = expression(Biomass~(g/m^2)), fill = "Trophic group") +
  theme_ps()
```
