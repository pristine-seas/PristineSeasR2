# Validate a Data Frame's Columns Against a BigQuery Table, Then Export to CSV

Before writing a pipeline's output to CSV for upload, this checks the
data frame's columns against the *live* schema of the BigQuery table
it's headed to — catching a renamed column upstream, a new field the
database doesn't know about yet, or a dropped column, at export time
rather than at upload time (or, worse, silently after upload).

If the columns match exactly (same names, any order), the data frame is
reordered to match the table's column order and written to `path`. If
they don't, nothing is written and the function errors with the specific
missing/extra column names.

## Usage

``` r
validate_and_export_csv(
  df,
  table_ref,
  path,
  label = table_ref,
  project = "pristine-seas",
  quiet = FALSE
)
```

## Arguments

- df:

  A data frame to validate and export.

- table_ref:

  BigQuery table reference in `"dataset.table"` form, e.g.
  `"uvs.lpi_stations"`.

- path:

  File path to write the CSV to.

- label:

  Short label used in messages and the error, e.g. `"Stations"`.
  Defaults to `table_ref`.

- project:

  BigQuery project ID. Defaults to `"pristine-seas"`.

- quiet:

  If `TRUE`, suppresses the confirmation message on success. Default
  `FALSE`.

## Value

The `path` the CSV was written to, invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
stations_csv <- validate_and_export_csv(
  df        = lpi_stations,
  table_ref = "uvs.lpi_stations",
  path      = file.path(data_out, paste0(exp_id, "_uvs_lpi_stations.csv")),
  label     = "Stations"
)
} # }
```
