# Get Pristine Seas shapes

Retrieve Pristine Seas point-shape palettes by name. The companion to
[`ps_colors()`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_colors.md)
for classes that are carried by form rather than hue.

## Usage

``` r
ps_shapes(palette = NULL)
```

## Arguments

- palette:

  Character. Name of the shape palette to retrieve. If `NULL`, returns
  the available palette names.

## Value

If `palette` is `NULL`, a character vector of palette names. Otherwise,
a named integer vector of R point shapes (see
[`graphics::points()`](https://rdrr.io/r/graphics/points.html)).

## Details

The `"habitat"` palette covers every level of the habitat vocabulary in
three tiers. The five zones sampled on most trips take the filled shapes
(21 to 25), which draw with a `fill` and an outline `colour`. Zones
sampled occasionally take the matching open shapes (0, 1, 2, 5, 6), and
zones rarely sampled take line shapes (3, 4, 8). On a map the convention
is that exposure fills the marker and habitat sets its shape.

## See also

[`scale_shape_ps()`](https://pristine-seas.github.io/PristineSeasR2/reference/scale_shape_ps.md),
[`ps_colors()`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_colors.md),
[`ps_habitat_colors()`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_habitat_colors.md)

## Examples

``` r
ps_shapes()             # list available shape palettes
#> [1] "habitat"
ps_shapes("habitat")    # named integer vector
#>     fore_reef     back_reef    patch_reef fringing_reef          bank 
#>            21            22            23            24            25 
#> pinnacle_reef     reef_flat          wall reef_pavement    rocky_reef 
#>             1             0             5             2             6 
#>  channel_pass   kelp_forest      seagrass 
#>             3             4             8 
```
