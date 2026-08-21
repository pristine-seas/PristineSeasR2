# Pristine Seas gt Theme for Summary Tables

A general-purpose `gt` style for tables that summarize survey effort or
results — region/subregion breakdowns, effort matrices, cover and
biomass compositions. The base look is a bold-headed, row-striped,
compact table with groups rendered as a column.

Every additional treatment is **opt-in via an argument**, so a single
flat table and an effort matrix with a total column and a heatmap fill
can share one function rather than each growing its own hand-tuned `gt`
pipeline.

## Usage

``` r
gt_theme_ps(
  data,
  ...,
  col_labels = NULL,
  spanners = NULL,
  total_col = NULL,
  heatmap_cols = NULL,
  heatmap_fill = c("#FFFFFF", "#407899"),
  grand_summary = FALSE,
  zero_dash = FALSE
)
```

## Arguments

- data:

  A data frame, already shaped for display.

- ...:

  Passed to [`gt::gt()`](https://gt.rstudio.com/reference/gt.html) —
  most often `groupname_col` and `rowname_col` for a grouped table.

- col_labels:

  Named character vector or list of column relabels, passed to
  [`gt::cols_label()`](https://gt.rstudio.com/reference/cols_label.html).
  `NULL` to skip.

- spanners:

  Named list; each element is a character vector of column names and the
  element's name is the spanner label shown above them. `NULL` to skip.

- total_col:

  Name of a column to set off with bold text and a left border — e.g. a
  row-wise `Total`. `NULL` to skip.

- heatmap_cols:

  Character vector of columns to fill on a sequential scale from 0 to
  their shared maximum. `NULL` to skip.

- heatmap_fill:

  Two-color gradient endpoints for `heatmap_cols`.

- grand_summary:

  Logical; add a bold, shaded grand-summary row summing `heatmap_cols`
  and `total_col` across all groups.

- zero_dash:

  Logical; render 0 as an en dash, so a matrix of mostly zeros reads as
  structure rather than noise.

## Value

A `gt_tbl`. Chain
[`gt::fmt_number()`](https://gt.rstudio.com/reference/fmt_number.html),
[`gt::tab_footnote()`](https://gt.rstudio.com/reference/tab_footnote.html),
etc. afterward to finish.

## Details

The arguments compose in a fixed order: relabel, then spanners, then
alignment, then the heatmap fill, then zero substitution, then the grand
summary, and finally the total column — which is set off last so its
bold text and left border also land on the grand-summary cell when both
are used.

`heatmap_cols` are colored on a shared scale running from 0 to the
maximum value across all of those columns, so a value is comparable
across the whole block rather than only within its own column.

## See also

[`gt_theme_ps_light()`](https://pristine-seas.github.io/PristineSeasR2/reference/gt_theme_ps_light.md)
for the plain, compact style used for diagnostic tables.

## Examples

``` r
if (FALSE) { # \dontrun{
# flat effort table
effort |>
  gt_theme_ps(groupname_col = "region", rowname_col = "subregion")

# cover matrix: relabelled, under a spanner, heat-filled, with a total column
cover_by_subregion |>
  gt_theme_ps(groupname_col = "region",
              rowname_col   = "subregion",
              col_labels    = grps_labels,
              spanners      = list(`% Cover by Functional Group` = cover_cols),
              heatmap_cols  = cover_cols,
              heatmap_fill  = c("white", "#0b5d4a"),
              zero_dash     = TRUE) |>
  gt::fmt_number(columns = dplyr::any_of(cover_cols), decimals = 1)
} # }
```
