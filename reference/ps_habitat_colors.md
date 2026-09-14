# Assign the habitat palette to the habitats a trip sampled

The `"habitat"` palette has five slots, named by default for the zones
sampled on most expeditions (fore reef, back reef, patch reef, fringing
reef, bank). Trips that sample other habitats reassign the same five
colours, in order, to the habitats they have, so a figure always uses
the same well-separated set no matter which zones were surveyed.

## Usage

``` r
ps_habitat_colors(levels)
```

## Arguments

- levels:

  Character. Habitat names in the order they should take the palette
  slots, typically `levels(df$habitat)` or the habitats present in the
  data. At most five.

## Value

A named character vector of hex codes, one per level, in the order
given.

## See also

[`ps_colors()`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_colors.md),
[`ps_shapes()`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_shapes.md)
for the matching habitat shapes

## Examples

``` r
ps_habitat_colors(c("fore_reef", "pinnacle_reef", "wall"))
#>     fore_reef pinnacle_reef          wall 
#>     "#005F87"     "#DCA04F"     "#A5DBE0" 
```
