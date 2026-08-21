# gt_theme_ps.R ----------------------------------------------------------------
# The shared gt style for Pristine Seas *summary* tables
#
# Public API:
#   - gt_theme_ps(): the summary-table builder — a grouped, bold-headed style
#     plus the four treatments those tables keep needing (relabels, spanners,
#     a set-off total column, a heatmap fill), each opt-in via an argument so
#     one function serves a flat effort table and a full cover matrix alike
#
# Companion: gt_theme_ps_light() is the plain, compact style for diagnostic tables.
# Use that one for "here are the rows a QA/QC check flagged"; use this one for
# the headline tables a reader is meant to study.

#' Pristine Seas gt Theme for Summary Tables
#'
#' @description
#' A general-purpose `gt` style for tables that summarize survey effort or
#' results — region/subregion breakdowns, effort matrices, cover and biomass
#' compositions. The base look is a bold-headed, row-striped, compact table
#' with groups rendered as a column.
#'
#' Every additional treatment is **opt-in via an argument**, so a single flat
#' table and an effort matrix with a total column and a heatmap fill can share
#' one function rather than each growing its own hand-tuned `gt` pipeline.
#'
#' @details
#' The arguments compose in a fixed order: relabel, then spanners, then
#' alignment, then the heatmap fill, then zero substitution, then the grand
#' summary, and finally the total column — which is set off last so its bold
#' text and left border also land on the grand-summary cell when both are used.
#'
#' `heatmap_cols` are colored on a shared scale running from 0 to the maximum
#' value across all of those columns, so a value is comparable across the whole
#' block rather than only within its own column.
#'
#' @param data A data frame, already shaped for display.
#' @param ... Passed to [gt::gt()] — most often `groupname_col` and
#'   `rowname_col` for a grouped table.
#' @param col_labels Named character vector or list of column relabels, passed
#'   to [gt::cols_label()]. `NULL` to skip.
#' @param spanners Named list; each element is a character vector of column
#'   names and the element's name is the spanner label shown above them.
#'   `NULL` to skip.
#' @param total_col Name of a column to set off with bold text and a left
#'   border — e.g. a row-wise `Total`. `NULL` to skip.
#' @param heatmap_cols Character vector of columns to fill on a sequential
#'   scale from 0 to their shared maximum. `NULL` to skip.
#' @param heatmap_fill Two-color gradient endpoints for `heatmap_cols`.
#' @param grand_summary Logical; add a bold, shaded grand-summary row summing
#'   `heatmap_cols` and `total_col` across all groups.
#' @param zero_dash Logical; render 0 as an en dash, so a matrix of mostly
#'   zeros reads as structure rather than noise.
#'
#' @return A `gt_tbl`. Chain [gt::fmt_number()], [gt::tab_footnote()], etc.
#'   afterward to finish.
#'
#' @seealso [gt_theme_ps_light()] for the plain, compact style used for diagnostic
#'   tables.
#'
#' @examples
#' \dontrun{
#' # flat effort table
#' effort |>
#'   gt_theme_ps(groupname_col = "region", rowname_col = "subregion")
#'
#' # cover matrix: relabelled, under a spanner, heat-filled, with a total column
#' cover_by_subregion |>
#'   gt_theme_ps(groupname_col = "region",
#'               rowname_col   = "subregion",
#'               col_labels    = grps_labels,
#'               spanners      = list(`% Cover by Functional Group` = cover_cols),
#'               heatmap_cols  = cover_cols,
#'               heatmap_fill  = c("white", "#0b5d4a"),
#'               zero_dash     = TRUE) |>
#'   gt::fmt_number(columns = dplyr::any_of(cover_cols), decimals = 1)
#' }
#'
#' @export
gt_theme_ps <- function(data,
                        ...,
                        col_labels    = NULL,
                        spanners      = NULL,
                        total_col     = NULL,
                        heatmap_cols  = NULL,
                        heatmap_fill  = c("#FFFFFF", "#407899"),
                        grand_summary = FALSE,
                        zero_dash     = FALSE) {

  tbl <- gt::gt(data, ...) |>
    gt::opt_row_striping() |>
    gt::tab_options(row_group.as_column               = TRUE,
                    table.font.size                   = gt::px(11),
                    column_labels.font.size           = gt::px(12),
                    column_labels.font.weight         = "bold",
                    row_group.font.weight             = "bold",
                    data_row.padding                  = gt::px(5),
                    row_group.padding                 = gt::px(5),
                    column_labels.border.bottom.width = gt::px(2),
                    column_labels.border.bottom.color = "#333333",
                    stub.border.style                 = "none")

  if (!is.null(col_labels)) {
    tbl <- tbl |> gt::cols_label(.list = as.list(col_labels))
  }

  if (!is.null(spanners)) {
    for (lbl in names(spanners)) {
      tbl <- tbl |> gt::tab_spanner(label = lbl, columns = dplyr::any_of(spanners[[lbl]]))
    }
    tbl <- tbl |> gt::tab_style(style     = gt::cell_text(weight = "bold"),
                                locations = gt::cells_column_spanners())
  }

  align_cols <- c(heatmap_cols, total_col)
  if (!is.null(align_cols)) {
    tbl <- tbl |> gt::cols_align(align = "center", columns = dplyr::any_of(align_cols))
  }

  if (!is.null(heatmap_cols)) {
    max_val <- max(dplyr::select(data, dplyr::any_of(heatmap_cols)), na.rm = TRUE)
    tbl <- tbl |>
      gt::data_color(columns = dplyr::any_of(heatmap_cols),
                     palette = heatmap_fill,
                     domain  = c(0, max_val),
                     alpha   = 0.85)
  }

  if (isTRUE(zero_dash)) {
    tbl <- tbl |> gt::sub_zero(zero_text = "\u2013")
  }

  if (isTRUE(grand_summary)) {
    gs_cols <- c(heatmap_cols, total_col)
    tbl <- tbl |>
      gt::grand_summary_rows(columns = dplyr::any_of(gs_cols),
                             fns = list(Total = ~ sum(., na.rm = TRUE)),
                             fmt = ~ gt::fmt_number(., decimals = 0)) |>
      gt::tab_style(style     = list(gt::cell_text(weight = "bold"),
                                     gt::cell_fill(color = "#F2F2F2")),
                    locations = gt::cells_grand_summary())
  }

  # last, so the bold text and left border also reach the grand-summary cell
  if (!is.null(total_col)) {
    locs <- list(gt::cells_body(columns = dplyr::any_of(total_col)),
                 gt::cells_column_labels(columns = dplyr::any_of(total_col)))
    if (isTRUE(grand_summary)) {
      locs <- c(locs, list(gt::cells_grand_summary(columns = dplyr::any_of(total_col))))
    }
    tbl <- tbl |>
      gt::tab_style(style     = list(gt::cell_text(weight = "bold"),
                                     gt::cell_borders(sides = "left",
                                                      color = "#dddddd",
                                                      weight = gt::px(1))),
                    locations = locs)
  }

  tbl
}
