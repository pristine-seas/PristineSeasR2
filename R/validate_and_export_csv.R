# validate_and_export_csv.R -----------------------------------------------------
# Schema-checked CSV export for tables headed to BigQuery
#
# Public API:
#   - validate_and_export_csv(): compares a data frame's columns against a live
#     BigQuery table's schema, then writes it to CSV only if they match exactly
#
# Internal helpers (not exported / not documented):
#   - bq_table_columns()

#' Validate a Data Frame's Columns Against a BigQuery Table, Then Export to CSV
#'
#' @description
#' Before writing a pipeline's output to CSV for upload, this checks the data
#' frame's columns against the *live* schema of the BigQuery table it's headed
#' to — catching a renamed column upstream, a new field the database doesn't
#' know about yet, or a dropped column, at export time rather than at upload
#' time (or, worse, silently after upload).
#'
#' If the columns match exactly (same names, any order), the data frame is
#' reordered to match the table's column order and written to `path`. If they
#' don't, nothing is written and the function errors with the specific
#' missing/extra column names.
#'
#' @param df A data frame to validate and export.
#' @param table_ref BigQuery table reference in `"dataset.table"` form, e.g.
#'   `"uvs.lpi_stations"`.
#' @param path File path to write the CSV to.
#' @param label Short label used in messages and the error, e.g. `"Stations"`.
#'   Defaults to `table_ref`.
#' @param project BigQuery project ID. Defaults to `"pristine-seas"`.
#' @param quiet If `TRUE`, suppresses the confirmation message on success.
#'   Default `FALSE`.
#'
#' @return The `path` the CSV was written to, invisibly.
#'
#' @examples
#' \dontrun{
#' stations_csv <- validate_and_export_csv(
#'   df        = lpi_stations,
#'   table_ref = "uvs.lpi_stations",
#'   path      = file.path(data_out, paste0(exp_id, "_uvs_lpi_stations.csv")),
#'   label     = "Stations"
#' )
#' }
#'
#' @export
validate_and_export_csv <- function(df, table_ref, path, label = table_ref,
                                     project = "pristine-seas", quiet = FALSE) {

  parts <- strsplit(table_ref, ".", fixed = TRUE)[[1]]
  if (length(parts) != 2 || any(!nzchar(parts))) {
    stop("`table_ref` must be in the form \"dataset.table\", got: \"", table_ref, "\"",
         call. = FALSE)
  }

  ref_cols <- bq_table_columns(project, parts[1], parts[2])

  missing <- setdiff(ref_cols, names(df))
  extra   <- setdiff(names(df), ref_cols)

  if (length(missing) > 0 || length(extra) > 0) {
    stop(
      sprintf("Schema mismatch for %s (%s):", label, table_ref), "\n",
      if (length(missing)) sprintf("  Missing columns: %s\n", paste(missing, collapse = ", ")),
      if (length(extra))   sprintf("  Extra columns: %s\n",   paste(extra,   collapse = ", ")),
      "Fix the data frame's columns (or the BigQuery schema) before exporting.",
      call. = FALSE
    )
  }

  out <- dplyr::select(df, dplyr::all_of(ref_cols))
  readr::write_csv(out, path)

  if (!quiet) cli::cli_alert_success("{label} written to {.path {path}}")

  invisible(path)
}

bq_table_columns <- function(project, dataset, table) {
  bq_tbl <- bigrquery::bq_table(project = project, dataset = dataset, table = table)
  vapply(bigrquery::bq_table_fields(bq_tbl), `[[`, character(1), "name")
}
