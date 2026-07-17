# Standard Benthic Cover Groups for `explore_benthic_cover()`

The default `group` / `cols` / `color` mapping used by
[`explore_benthic_cover()`](https://pristine-seas.github.io/PristineSeasR2/reference/explore_benthic_cover.md).
Returned as data so you can start from it when building a custom
`cover_groups` table (e.g.
[`dplyr::filter()`](https://dplyr.tidyverse.org/reference/filter.html)
out a group, or
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
in a different color) rather than writing one from scratch.

## Usage

``` r
default_benthic_cover_groups()
```

## Value

A tibble with columns `group` (display name), `cols` (one or more source
column names, comma-separated), and `color` (hex color).

## See also

[`explore_benthic_cover()`](https://pristine-seas.github.io/PristineSeasR2/reference/explore_benthic_cover.md)
