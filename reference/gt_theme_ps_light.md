# The Light, Compact Pristine Seas gt Style

Wraps `df` in [`gt::gt()`](https://gt.rstudio.com/reference/gt.html)
with a compact, elegant style meant to be the *one* table look used
throughout a report — diagnostic tables (the rows a QA/QC check prints
when it flags something) and headline summary/reference tables alike. No
heavy borders, no per-table hand-tuned font sizes: just a thin rule
under the column headers, subtle row striping, column titles sized to
~80% of gt's own defaults (16px font, 8px row padding), and row text a
further 20% smaller than that — so headers read as structure and data
rows read as dense, quiet detail. Row padding scales down to match.

If you apply
[`gt::data_color()`](https://gt.rstudio.com/reference/data_color.html)
(or any other cell-coloring call), chain it *after*
`gt_theme_ps_light()` — the color should be layered on top of this base
style, not the other way around.

`light_gt()` is the original name for the same function, kept so the few
hundred existing calls across the expedition pipelines keep working. It
is a plain alias: no warning, no behaviour of its own. New code should
prefer `gt_theme_ps_light()`, which sits alphabetically beside
[`gt_theme_ps()`](https://pristine-seas.github.io/PristineSeasR2/reference/gt_theme_ps.md)
and says whose house style it is.

## Usage

``` r
gt_theme_ps_light(df, ...)

light_gt(df, ...)
```

## Arguments

- df:

  A data frame to display.

- ...:

  Passed on to [`gt::gt()`](https://gt.rstudio.com/reference/gt.html) —
  e.g. `groupname_col` or `rowname_col` for a grouped table rather than
  a flat list.

## Value

A `gt_tbl` object. Chain
[`gt::cols_label()`](https://gt.rstudio.com/reference/cols_label.html),
[`gt::data_color()`](https://gt.rstudio.com/reference/data_color.html),
etc. afterward to finish styling.

## See also

[`gt_theme_ps()`](https://pristine-seas.github.io/PristineSeasR2/reference/gt_theme_ps.md)
for the fuller summary-table style — bold headers, spanners, group
column — that this one is the plain counterpart to.

## Examples

``` r
if (FALSE) { # \dontrun{
flagged_rows |>
  gt_theme_ps_light() |>
  gt::cols_label(ps_station_id = "Station")

# grouped by region, with cell color layered on after the base style
site_biomass |>
  gt_theme_ps_light(groupname_col = "region") |>
  gt::data_color(columns = avg_biomass_gm2, palette = c("white", "#0b5d4a"))
} # }
```
