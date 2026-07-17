make_sites <- function() {
  tibble::tibble(
    ps_site_id = c("A", "B", "C"),
    site_name  = c("Reef One", NA, "Reef Three"),
    locality   = c("North Bay", "South Bay", "East Point"),
    region     = c("Shefa", "Shefa", "Torba"),
    subregion  = c("North", "North", "South"),
    habitat    = c("fore_reef", "back_reef", "fore_reef"),
    exposure   = c("windward", "leeward", "windward"),
    longitude  = c(168.1, 168.2, 168.3),
    latitude   = c(-17.5, -17.6, -17.7),
    date       = as.Date(c("2025-10-01", "2025-10-02", "2025-10-03")),
    time       = c("08:30:00", "09:15:00", NA),
    in_mpa     = c(TRUE, FALSE, NA),
    mpa_notes  = c("core zone", NA, NA),
    notes      = c(NA, "strong current", NA)
  )
}

region_pal    <- c(Shefa = "#F4C95D", Torba = "#EE8434")
subregion_pal <- c(North = "#4EA5D9", South = "#E0503D")

test_that("returns a leaflet htmlwidget for valid input", {
  m <- explore_uvs_sites(make_sites(), region_pal, subregion_pal)
  expect_s3_class(m, "leaflet")
  expect_s3_class(m, "htmlwidget")
})

test_that("errors when sites is missing a required column", {
  bad <- dplyr::select(make_sites(), -exposure)
  expect_error(explore_uvs_sites(bad, region_pal, subregion_pal), "exposure")
})

test_that("errors when export_path is given without a title", {
  expect_error(
    explore_uvs_sites(make_sites(), region_pal, subregion_pal,
                export_path = tempfile(fileext = ".html")),
    "title.*required"
  )
})

test_that("writes a standalone HTML file when export_path and title are given", {
  tmp <- tempfile(fileext = ".html")
  on.exit(unlink(tmp))

  m <- explore_uvs_sites(make_sites(), region_pal, subregion_pal,
                    title       = "Test Expedition — UVS sites",
                    export_path = tmp)

  expect_true(file.exists(tmp))
  expect_s3_class(m, "leaflet")
})

test_that("warns and falls back when a habitat/exposure level has no color", {
  sites <- make_sites()
  sites$habitat[1] <- "totally_new_habitat"

  expect_warning(
    explore_uvs_sites(sites, region_pal, subregion_pal),
    "totally_new_habitat"
  )
})

test_that("works with an unnamed (positional) palette", {
  unnamed_region_pal <- c("#F4C95D", "#EE8434")
  expect_no_error(explore_uvs_sites(make_sites(), unnamed_region_pal, subregion_pal))
})

test_that("works with a single site", {
  one_site <- make_sites()[1, ]
  expect_no_error(explore_uvs_sites(one_site, region_pal, subregion_pal))
})

test_that("works when optional popup columns are absent entirely", {
  minimal_sites <- dplyr::select(
    make_sites(),
    ps_site_id, region, subregion, habitat, exposure, longitude, latitude
  )
  expect_no_error(explore_uvs_sites(minimal_sites, region_pal, subregion_pal))
})
