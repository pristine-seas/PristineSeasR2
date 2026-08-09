make_stations <- function() {
  tibble::tibble(
    ps_station_id   = c("A_10m", "A_20m", "B_10m"),
    ps_site_id      = c("A", "A", "B"),
    divers          = c("Jenn Caselle", "Jenn Caselle", "Tye Kindinger"),
    depth_strata    = c("shallow", "deep", "shallow"),
    depth_m         = c(10, 20, 10),
    n_taxa          = c(12, 8, 15),
    avg_density_m2  = c(0.5, 0.3, 0.8),
    avg_biomass_gm2 = c(20.5, 15.2, 30.1)
  )
}

make_sites <- function() {
  tibble::tibble(
    ps_site_id = c("A", "B"),
    region     = c("Shefa", "Torba"),
    subregion  = c("North", "South"),
    locality   = c("North Bay", "South Bay"),
    habitat    = c("fore_reef", "back_reef"),
    exposure   = c("windward", "leeward"),
    longitude  = c(168.1, 168.3),
    latitude   = c(-17.5, -17.7)
  )
}

test_that("returns a leaflet htmlwidget for valid input", {
  m <- explore_fish_biomass(make_stations(), make_sites())
  expect_s3_class(m, "leaflet")
  expect_s3_class(m, "htmlwidget")
})

test_that("errors when stations is missing a required column", {
  bad <- dplyr::select(make_stations(), -avg_biomass_gm2)
  expect_error(explore_fish_biomass(bad, make_sites()), "avg_biomass_gm2")
})

test_that("errors when sites is missing a required column", {
  bad <- dplyr::select(make_sites(), -exposure)
  expect_error(explore_fish_biomass(make_stations(), bad), "exposure")
})

test_that("errors when export_path is given without a title", {
  expect_error(
    explore_fish_biomass(make_stations(), make_sites(),
                         export_path = tempfile(fileext = ".html")),
    "title.*required"
  )
})

test_that("errors when a site in stations has no matching coordinates", {
  stations <- make_stations()
  sites    <- make_sites()[1, ]  # drop site B
  expect_error(explore_fish_biomass(stations, sites), "coordinates")
})

test_that("writes a standalone HTML file when export_path and title are given", {
  tmp <- tempfile(fileext = ".html")
  on.exit(unlink(tmp))

  m <- explore_fish_biomass(make_stations(), make_sites(),
                            title       = "Test Expedition — Fish survey results",
                            export_path = tmp)

  expect_true(file.exists(tmp))
  expect_s3_class(m, "leaflet")
})

test_that("works with a single site", {
  stations <- make_stations() |> dplyr::filter(ps_site_id == "A")
  sites    <- make_sites()[1, ]
  expect_no_error(explore_fish_biomass(stations, sites))
})

test_that("works when multiple stations share the same site", {
  # site A has two stations (10m + 20m), which must aggregate without error
  expect_no_error(explore_fish_biomass(make_stations(), make_sites()))
})
