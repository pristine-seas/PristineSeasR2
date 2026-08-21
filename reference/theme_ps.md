# Pristine Seas chart theme

The house ggplot2 theme for charts. A warm pampas canvas, a horizontal
grid that carries the eye without competing with the data, no ticks, and
a title block aligned to the plot rather than the panel.

Shares its type scale, legend geometry, and title hierarchy with
[`theme_ps_map()`](https://pristine-seas.github.io/PristineSeasR2/reference/theme_ps_map.md),
so a chart and a map can sit side by side on one page and read as a
pair.

## Usage

``` r
theme_ps(base_size = 12, base_family = ps_font_default())
```

## Arguments

- base_size:

  Numeric. Base font size in points; every other size is a step from it.
  Default 12.

- base_family:

  Character. Base font family. Defaults to
  [`ps_font_default()`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_font_default.md)
  — Inter where it is installed, otherwise Helvetica.

## Value

A ggplot2 theme object.

## Axis labels

This theme does not rotate x-axis labels. Rotate where a particular
figure needs it, rather than everywhere:

    theme_ps() + theme(axis.text.x = element_text(angle = 45, hjust = 1))

## See also

[`theme_ps_map()`](https://pristine-seas.github.io/PristineSeasR2/reference/theme_ps_map.md)
for maps,
[`ps_ink()`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_ink.md)
for the palette behind both,
[`scale_fill_ps()`](https://pristine-seas.github.io/PristineSeasR2/reference/scale_fill_ps.md)
and
[`scale_color_ps()`](https://pristine-seas.github.io/PristineSeasR2/reference/scale_color_ps.md)
for data palettes.

## Examples

``` r
library(ggplot2)

ggplot(mpg, aes(class, hwy)) +
  geom_boxplot(fill = "#1F6F8B", colour = "#14181A", linewidth = 0.3) +
  labs(title    = "Fuel efficiency by car class",
       subtitle = "Highway miles per gallon",
       x = NULL, y = "MPG") +
  theme_ps()
```
