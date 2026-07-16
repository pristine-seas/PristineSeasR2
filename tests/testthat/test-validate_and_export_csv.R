test_that("writes a CSV when columns match the schema exactly", {
  local_mocked_bindings(bq_table_columns = function(...) c("a", "b", "c"))

  df  <- tibble::tibble(a = 1, b = 2, c = 3)
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp))

  out <- validate_and_export_csv(df, "ds.tbl", path = tmp, quiet = TRUE)

  expect_equal(out, tmp)
  expect_true(file.exists(tmp))
  expect_equal(names(readr::read_csv(tmp, show_col_types = FALSE)), c("a", "b", "c"))
})

test_that("reorders columns to match the table's schema order", {
  local_mocked_bindings(bq_table_columns = function(...) c("a", "b", "c"))

  df  <- tibble::tibble(c = 3, a = 1, b = 2)
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp))

  validate_and_export_csv(df, "ds.tbl", path = tmp, quiet = TRUE)

  expect_equal(names(readr::read_csv(tmp, show_col_types = FALSE)), c("a", "b", "c"))
})

test_that("errors and writes nothing when a column is missing", {
  local_mocked_bindings(bq_table_columns = function(...) c("a", "b", "c"))

  df  <- tibble::tibble(a = 1, b = 2)
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp))

  expect_error(validate_and_export_csv(df, "ds.tbl", path = tmp), "Missing columns: c")
  expect_false(file.exists(tmp))
})

test_that("errors and writes nothing when there's an extra column", {
  local_mocked_bindings(bq_table_columns = function(...) c("a", "b"))

  df  <- tibble::tibble(a = 1, b = 2, z = 9)
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp))

  expect_error(validate_and_export_csv(df, "ds.tbl", path = tmp), "Extra columns: z")
  expect_false(file.exists(tmp))
})

test_that("error message reports both missing and extra columns together", {
  local_mocked_bindings(bq_table_columns = function(...) c("a", "b", "c"))

  df <- tibble::tibble(a = 1, z = 9)

  expect_error(
    validate_and_export_csv(df, "ds.tbl", path = tempfile()),
    "Missing columns: b, c"
  )
  expect_error(
    validate_and_export_csv(df, "ds.tbl", path = tempfile()),
    "Extra columns: z"
  )
})

test_that("rejects a table_ref that isn't \"dataset.table\"", {
  df <- tibble::tibble(a = 1)

  expect_error(validate_and_export_csv(df, "not_a_valid_ref", path = tempfile()),
               "dataset.table")
  expect_error(validate_and_export_csv(df, "too.many.parts", path = tempfile()),
               "dataset.table")
})

test_that("label defaults to table_ref and appears in the success message", {
  local_mocked_bindings(bq_table_columns = function(...) c("a"))

  df  <- tibble::tibble(a = 1)
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp))

  expect_message(validate_and_export_csv(df, "ds.tbl", path = tmp), "ds.tbl")
})

test_that("quiet = TRUE suppresses the success message", {
  local_mocked_bindings(bq_table_columns = function(...) c("a"))

  df  <- tibble::tibble(a = 1)
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp))

  expect_no_message(validate_and_export_csv(df, "ds.tbl", path = tmp, quiet = TRUE))
})
