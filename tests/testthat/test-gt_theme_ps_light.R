test_that("returns a gt_tbl object", {
  df <- tibble::tibble(a = 1:3, b = c("x", "y", "z"))
  out <- gt_theme_ps_light(df)
  expect_s3_class(out, "gt_tbl")
})

test_that("works with cols_label chained afterward", {
  df <- tibble::tibble(ps_station_id = "A", n = 1)
  out <- df |> gt_theme_ps_light() |> gt::cols_label(ps_station_id = "Station")
  expect_s3_class(out, "gt_tbl")
})

test_that("works with a single-row data frame", {
  df <- tibble::tibble(a = 1)
  expect_no_error(gt_theme_ps_light(df))
})

test_that("passes ... through to gt::gt(), e.g. groupname_col", {
  df <- tibble::tibble(region = c("Shefa", "Shefa", "Torba"),
                        subregion = c("North", "South", "North"),
                        avg_biomass_gm2 = c(1, 2, 3))
  expect_no_error(gt_theme_ps_light(df, groupname_col = "region"))
  out <- gt_theme_ps_light(df, groupname_col = "region")
  expect_s3_class(out, "gt_tbl")
})

test_that("light_gt() still works, and is the same function under another name", {
  df <- tibble::tibble(ps_station_id = c("A", "B"), region = c("N", "S"), avg_biomass_gm2 = c(1, 2))
  expect_no_error(light_gt(df))
  # the old name is called a few hundred times across the expedition pipelines,
  # so it has to keep returning exactly what the new one does — and silently
  expect_equal(light_gt(df), gt_theme_ps_light(df))
  expect_silent(light_gt(df))
})
