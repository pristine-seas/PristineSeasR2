# light_gt.R --------------------------------------------------------------------
# The single, shared gt style for Pristine Seas pipeline notebooks
#
# Public API:
#   - light_gt(): compact, elegant gt style — thin header rule, subtle row
#     striping, ~20% smaller than gt's defaults — used for every table in a
#     report, from QA/QC diagnostics to headline summary tables, so a single
#     notebook doesn't mix multiple table looks

#' Apply the Pristine Seas Light, Compact gt Style to a Data Frame
#'
#' @description
#' Wraps `df` in [gt::gt()] with a compact, elegant style meant to be the
#' *one* table look used throughout a report — diagnostic tables (the rows a
#' QA/QC check prints when it flags something) and headline summary/reference
#' tables alike. No heavy borders, no per-table hand-tuned font sizes: just a
#' thin rule under the column headers, subtle row striping, column titles
#' sized to ~80% of gt's own defaults (16px font, 8px row padding), and row
#' text a further 20% smaller than that — so headers read as structure and
#' data rows read as dense, quiet detail. Row padding scales down to match.
#'
#' If you apply [gt::data_color()] (or any other cell-coloring call), chain it
#' *after* `light_gt()` — the color should be layered on top of this base
#' style, not the other way around.
#'
#' @param df A data frame to display.
#' @param ... Passed on to [gt::gt()] — e.g. `groupname_col` or `rowname_col`
#'   for a grouped table rather than a flat list.
#'
#' @return A `gt_tbl` object. Chain [gt::cols_label()], [gt::data_color()],
#'   etc. afterward to finish styling.
#'
#' @examples
#' \dontrun{
#' flagged_rows |>
#'   light_gt() |>
#'   gt::cols_label(ps_station_id = "Station")
#'
#' # grouped by region, with cell color layered on after the base style
#' site_biomass |>
#'   light_gt(groupname_col = "region") |>
#'   gt::data_color(columns = avg_biomass_gm2, palette = c("white", "#0b5d4a"))
#' }
#'
#' @export
light_gt <- function(df, ...) {
  df |>
    gt::gt(...) |>
    gt::tab_options(
      table.font.size                   = gt::px(12),
      column_labels.font.size           = "125%",
      table.border.top.style            = "hidden",
      table.border.bottom.style         = "hidden",
      column_labels.border.bottom.style = "solid",
      column_labels.border.bottom.width = gt::px(1),
      column_labels.border.bottom.color = "#dddddd",
      column_labels.padding             = gt::px(4),
      data_row.padding                  = gt::px(4),
      row_group.padding                 = gt::px(4),
      row_group.as_column               = TRUE
    ) |>
    gt::opt_row_striping()
}
