make_stations <- function() {
  tibble::tibble(
    ps_site_id = c("A", "A", "B"),
    region     = c("Shefa", "Shefa", "Torba"),
    subregion  = c("North", "North", "South"),
    locality   = c("Reef 1", "Reef 1", "Reef 2"),
    habitat    = c("fore_reef", "fore_reef", "back_reef"),
    exposure   = c("windward", "windward", "leeward"),
    divers     = c("Emma Cebrian", "Emma Cebrian", "Eric Brown"),
    pct_coral      = c(40, 30, 0),
    pct_soft_coral = c(5, 5, 0),
    pct_cca        = c(10, 10, 0),
    pct_rubble     = c(10, 15, 100),
    pct_other      = c(5, 5, 0)
  )
}

make_sites <- function() {
  tibble::tibble(
    ps_site_id = c("A", "B"),
    longitude  = c(168.1, 168.2),
    latitude   = c(-17.5, -17.6)
  )
}

test_that("returns a leaflet htmlwidget for a valid input", {
  m <- explore_benthic_cover(make_stations(), make_sites())
  expect_s3_class(m, "leaflet")
  expect_s3_class(m, "htmlwidget")
})

test_that("errors when stations is missing a required column", {
  bad <- dplyr::select(make_stations(), -habitat)
  expect_error(explore_benthic_cover(bad, make_sites()), "habitat")
})

test_that("errors when sites is missing longitude/latitude", {
  bad_sites <- dplyr::select(make_sites(), -latitude)
  expect_error(explore_benthic_cover(make_stations(), bad_sites), "longitude|latitude")
})

test_that("errors when a site in stations has no coordinate match", {
  sites_missing_b <- dplyr::filter(make_sites(), .data$ps_site_id != "B")
  expect_error(explore_benthic_cover(make_stations(), sites_missing_b), "no matching coordinates")
})

test_that("errors when export_path is given without a title", {
  expect_error(
    explore_benthic_cover(make_stations(), make_sites(), export_path = tempfile(fileext = ".html")),
    "title.*required"
  )
})

test_that("writes a standalone HTML file when export_path and title are given", {
  tmp <- tempfile(fileext = ".html")
  on.exit(unlink(tmp))

  m <- explore_benthic_cover(make_stations(), make_sites(),
                         title = "Test Expedition — Benthic composition",
                         export_path = tmp)

  expect_true(file.exists(tmp))
  expect_s3_class(m, "leaflet")
})

test_that("a cover column missing entirely is treated as 0, not an error", {
  stations_no_cca <- dplyr::select(make_stations(), -pct_cca)
  expect_no_error(explore_benthic_cover(stations_no_cca, make_sites()))
})

test_that("a functional group with zero cover everywhere doesn't error", {
  stations_no_soft_coral <- dplyr::mutate(make_stations(), pct_soft_coral = 0)
  expect_no_error(explore_benthic_cover(stations_no_soft_coral, make_sites()))
})

test_that("a custom cover_groups table is honored", {
  stations <- tibble::tibble(
    ps_site_id = "A", region = "Shefa", subregion = "North", locality = "Reef 1",
    habitat = "fore_reef", exposure = "windward", divers = "Emma Cebrian",
    pct_weird_group = 100
  )
  sites <- tibble::tibble(ps_site_id = "A", longitude = 168.1, latitude = -17.5)
  custom_groups <- tibble::tribble(
    ~group,        ~cols,             ~color,
    "Weird Group", "pct_weird_group", "#123456"
  )

  m <- explore_benthic_cover(stations, sites, cover_groups = custom_groups)
  expect_s3_class(m, "leaflet")
})

test_that("default_benthic_cover_groups() returns the expected structure", {
  groups <- default_benthic_cover_groups()

  expect_s3_class(groups, "tbl_df")
  expect_named(groups, c("group", "cols", "color"))
  expect_true(all(grepl("^#[0-9A-Fa-f]{6}$", groups$color)))
  expect_true("Hard coral" %in% groups$group)
})
