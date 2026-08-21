# gt_theme_ps_light.R -----------------------------------------------------------
# The single, shared gt style for Pristine Seas pipeline notebooks
#
# Public API:
#   - gt_theme_ps_light(): compact, elegant gt style — thin header rule, subtle
#     row striping, ~20% smaller than gt's defaults — used for every table in a
#     report, from QA/QC diagnostics to headline summary tables, so a single
#     notebook doesn't mix multiple table looks
#   - light_gt(): the name this had before it was brought in line with
#     gt_theme_ps(). Kept, and kept silent, because it is called a few hundred
#     times across the expedition pipelines

#' The Light, Compact Pristine Seas gt Style
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
#' *after* `gt_theme_ps_light()` — the color should be layered on top of this base
#' style, not the other way around.
#'
#' @param df A data frame to display.
#' @param ... Passed on to [gt::gt()] — e.g. `groupname_col` or `rowname_col`
#'   for a grouped table rather than a flat list.
#'
#' @seealso [gt_theme_ps()] for the fuller summary-table style — bold headers,
#'   spanners, group column — that this one is the plain counterpart to.
#'
#' @return A `gt_tbl` object. Chain [gt::cols_label()], [gt::data_color()],
#'   etc. afterward to finish styling.
#'
#' @examples
#' \dontrun{
#' flagged_rows |>
#'   gt_theme_ps_light() |>
#'   gt::cols_label(ps_station_id = "Station")
#'
#' # grouped by region, with cell color layered on after the base style
#' site_biomass |>
#'   gt_theme_ps_light(groupname_col = "region") |>
#'   gt::data_color(columns = avg_biomass_gm2, palette = c("white", "#0b5d4a"))
#' }
#'
#' @export
gt_theme_ps_light <- function(df, ...) {
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

#' @rdname gt_theme_ps_light
#'
#' @description
#' `light_gt()` is the original name for the same function, kept so the few
#' hundred existing calls across the expedition pipelines keep working. It is a
#' plain alias: no warning, no behaviour of its own. New code should prefer
#' `gt_theme_ps_light()`, which sits alphabetically beside [gt_theme_ps()] and
#' says whose house style it is.
#'
#' @export
light_gt <- function(df, ...) {
  gt_theme_ps_light(df, ...)
}
