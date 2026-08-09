test_that("returns a gt_tbl object", {
  df <- tibble::tibble(a = 1:3, b = c("x", "y", "z"))
  out <- light_gt(df)
  expect_s3_class(out, "gt_tbl")
})

test_that("works with cols_label chained afterward", {
  df <- tibble::tibble(ps_station_id = "A", n = 1)
  out <- df |> light_gt() |> gt::cols_label(ps_station_id = "Station")
  expect_s3_class(out, "gt_tbl")
})

test_that("works with a single-row data frame", {
  df <- tibble::tibble(a = 1)
  expect_no_error(light_gt(df))
})

test_that("passes ... through to gt::gt(), e.g. groupname_col", {
  df <- tibble::tibble(region = c("Shefa", "Shefa", "Torba"),
                        subregion = c("North", "South", "North"),
                        avg_biomass_gm2 = c(1, 2, 3))
  expect_no_error(light_gt(df, groupname_col = "region"))
  out <- light_gt(df, groupname_col = "region")
  expect_s3_class(out, "gt_tbl")
})
