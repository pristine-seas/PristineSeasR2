# The Ink Behind The Themes

The ink behind
[`theme_ps()`](https://pristine-seas.github.io/PristineSeasR2/reference/theme_ps.md)
and
[`theme_ps_map()`](https://pristine-seas.github.io/PristineSeasR2/reference/theme_ps_map.md).
Use it when a figure needs to draw something the theme does not supply —
an EEZ hairline, a text halo, a reference line, land polygons under a
raster — and that mark has to sit in the same key as the canvas around
it.

`"chart"` returns the paper palette; `"map"` returns the water palette
plus the geography colors (`land`, `coast`, `eez`, `shelf`) that a
hand-built basemap needs.

`ps_theme_colors()` is the original name for the same function. It is
kept as a plain alias — no warning, no behaviour of its own — because it
is called across the expedition pipelines. New code should prefer
`ps_ink()`, which does not read as a transposition of
[`theme_ps()`](https://pristine-seas.github.io/PristineSeasR2/reference/theme_ps.md)
and is not mistaken for
[`ps_colors()`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_colors.md),
the categorical palettes for data rather than for canvas.

## Usage

``` r
ps_ink(theme = c("chart", "map"))

ps_theme_colors(theme = c("chart", "map"))
```

## Arguments

- theme:

  Either `"chart"` (default) or `"map"`.

## Value

A named character vector of hex codes. Names common to both: `canvas`,
`panel`, `grid`, `strip`, `title`, `body`, `muted`.

## See also

[`ps_colors()`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_colors.md)
for the *data* palettes — trophic groups, habitats, functional groups —
which encode categories rather than chrome.

## Examples

``` r
ps_ink("chart")
#>    canvas     panel      grid     strip     title      body     muted 
#> "#F4F1EA" "#F4F1EA" "#DDD7CA" "#E8E3D8" "#14181A" "#3C4145" "#6B7376" 
ps_ink("map")[["eez"]]
#> [1] "#7E97AC"

if (FALSE) { # \dontrun{
ink <- ps_ink("map")

ggplot() +
  geom_spatvector(data = eez, fill = NA, colour = ink[["eez"]], linetype = "22") +
  geom_spatvector(data = land, fill = ink[["land"]], colour = ink[["coast"]]) +
  theme_ps_map()
} # }
```
