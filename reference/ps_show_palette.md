# Preview a Pristine Seas palette

Quick visualization helper to inspect palettes at a glance.

## Usage

``` r
ps_show_palette(palette, show_labels = TRUE, ncol = NULL)
```

## Arguments

- palette:

  Character. Palette name passed to
  [`ps_colors()`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_colors.md).

- show_labels:

  Logical. Whether to display category labels. Default `TRUE`.

- ncol:

  Integer. Number of columns for the swatch grid. Default `NULL` (auto).

## Value

A ggplot object if ggplot2 is available; otherwise invisibly returns
`NULL` after plotting.

## Details

If ggplot2 is installed, returns a ggplot swatch plot. Otherwise, draws
a simple base R swatch plot.

## Examples

``` r
if (FALSE) { # \dontrun{
ps_show_palette("trophic_group")
ps_show_palette("functional_groups", ncol = 3)
} # }
```
