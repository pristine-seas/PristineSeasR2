# A small table in the shape of the UVS sites output: three atolls, one of
# them with two localities, and a site with no exposure.
make_map_sites <- function() {
  tibble::tibble(
    ps_site_id = c("A", "B", "C", "D"),
    region     = c("Bikar", "Bikar", "Bokak", "Bikini"),
    subregion  = c("Jabwelo", "Almani", "Sibylla", "Bikini"),
    habitat    = c("fore_reef", "patch_reef", "pinnacle_reef", "fore_reef"),
    exposure   = c("leeward", "lagoon", NA, "windward"),
    longitude  = c(170.09, 170.13, 168.95, 165.38),
    latitude   = c(12.29, 12.24, 14.62, 11.60)
  )
}

# Selection --------------------------------------------------------------------

test_that("selection keeps everything when neither region nor subregion is set", {
  expect_equal(nrow(uvs_map_selection(make_map_sites())), 4L)
})

test_that("selection filters by region, then subregion within it", {
  expect_equal(uvs_map_selection(make_map_sites(), region = "Bikar")$ps_site_id, c("A", "B"))
  expect_equal(uvs_map_selection(make_map_sites(), subregion = "Almani")$ps_site_id, "B")
  expect_equal(uvs_map_selection(make_map_sites(), region = c("Bikar", "Bokak"),
                                 subregion = c("Jabwelo", "Sibylla"))$ps_site_id,
               c("A", "C"))
})

test_that("an unknown region or subregion errors and lists what is available", {
  expect_error(uvs_map_selection(make_map_sites(), region = "Rongerik"),
               "Rongerik.*Available: Bikar, Bikini, Bokak")
  expect_error(uvs_map_selection(make_map_sites(), region = "Bokak", subregion = "Almani"),
               "Almani.*Available: Sibylla")
})

test_that("selection errors on missing columns", {
  expect_error(uvs_map_selection(dplyr::select(make_map_sites(), -habitat)), "habitat")
})

test_that("sites without coordinates are dropped with a warning", {
  sites <- make_map_sites()
  sites$latitude[2] <- NA
  expect_warning(sel <- uvs_map_selection(sites), "B")
  expect_equal(nrow(sel), 3L)
})

# Encoding ---------------------------------------------------------------------

test_that("encoding gives filled shapes a light outline and open shapes the exposure colour", {
  pts <- uvs_map_encode(uvs_map_selection(make_map_sites()), outline = "#EEF3F7")
  expect_s3_class(pts, "sf")
  expect_equal(pts$outline[pts$ps_site_id == "A"], "#EEF3F7")
  expect_equal(pts$outline[pts$ps_site_id == "C"], ps_colors("exposure")[["unknown"]])
  expect_equal(pts$exposure[pts$ps_site_id == "C"], "unknown")
})

test_that("values outside the vocabulary are an error naming them", {
  sel <- uvs_map_selection(make_map_sites())
  sel$habitat[1] <- "coral_garden"
  expect_error(uvs_map_encode(sel, "#EEF3F7"), "habitat: coral_garden")
})

test_that("the subtitle names the place and counts the sites", {
  sel <- uvs_map_selection(make_map_sites(), region = "Bikar")
  expect_equal(uvs_map_subtitle(sel, "Bikar", NULL), "Bikar · 2 sites")
  expect_equal(uvs_map_subtitle(sel, NULL, "Jabwelo"), "Jabwelo, Bikar · 2 sites")
  expect_equal(uvs_map_subtitle(uvs_map_selection(make_map_sites()), NULL, NULL),
               "Bikar, Bikini, Bokak · 4 sites")
})

test_that("site numbers are the trailing digits without leading zeros", {
  expect_equal(uvs_site_number(c("RMI_2023_uvs_007", "RMI_2023_uvs_120", "BKR-6", "Reef One", NA)),
               c("7", "120", "6", "Reef One", NA))
})

# Frame ------------------------------------------------------------------------

test_that("the frame pads the bounding box and never falls under min_span", {
  pts <- sf::st_as_sf(make_map_sites()[1:2, ], coords = c("longitude", "latitude"), crs = 4326)
  bb  <- sf::st_bbox(sf::st_transform(pts, 3857))

  lim  <- frame_from_sites(pts, expand = 0.25, min_span = 3)
  side <- max(bb[["xmax"]] - bb[["xmin"]], bb[["ymax"]] - bb[["ymin"]])
  expect_equal(lim[["xmin"]], bb[["xmin"]] - 0.25 * side)
  expect_equal(lim[["ymax"]], bb[["ymax"]] + 0.25 * side)

  # a single site still gets a frame, and it is min_span across on the ground
  one <- frame_from_sites(pts[1, ], min_span = 3)
  lat <- unname(sf::st_coordinates(pts[1, ])[, 2])
  expect_equal((one[["xmax"]] - one[["xmin"]]) * cos(lat * pi / 180), 3000)
  expect_equal((one[["ymax"]] - one[["ymin"]]) * cos(lat * pi / 180), 3000)
})

test_that("sites on both sides of the antimeridian are refused with a clear message", {
  pts <- sf::st_as_sf(data.frame(x = c(179.5, -179.5), y = c(-8, -8)),
                      coords = c("x", "y"), crs = 4326)
  expect_error(frame_from_sites(pts), "antimeridian")
})

test_that("a caller's extent becomes the frame, and comes back in degrees", {
  deg <- c(170.05, 12.15, 170.15, 12.30)
  lim <- frame_from_extent(deg)
  expect_named(lim, c("xmin", "ymin", "xmax", "ymax"))
  expect_equal(unname(frame_to_degrees(lim)), deg, tolerance = 1e-4)

  # an sf bbox in another projection lands in the same place
  bb <- sf::st_bbox(sf::st_transform(sf::st_as_sfc(sf::st_bbox(
    c(xmin = 170.05, ymin = 12.15, xmax = 170.15, ymax = 12.30), crs = 4326)), 32659))
  expect_equal(unname(frame_to_degrees(frame_from_extent(bb))), deg, tolerance = 1e-3)

  # a named vector is read by name, whatever its order
  named <- frame_from_extent(c(ymax = 12.30, xmin = 170.05, ymin = 12.15, xmax = 170.15))
  expect_equal(named, lim)

  expect_error(frame_from_extent(c(170.15, 12.15, 170.05, 12.30)), "xmin < xmax")
  expect_error(frame_from_extent("Bikar"), "degrees")
})

test_that("tile zoom gives a frame about the pixel width asked for", {
  # 32 km square: zoom 13 tiles are 4892 m / 256 px, so 1675 px, nearest 2000
  bb <- c(xmin = 0, ymin = 0, xmax = 32000, ymax = 32000)
  expect_equal(tile_zoom(bb), 13L)
  expect_equal(tile_zoom(bb, px = 4000), 14L)
  # sized on the longer side: a frame six times taller than wide rounds to 11
  expect_equal(tile_zoom(c(xmin = 0, ymin = 0, xmax = 32000, ymax = 192000)), 11L)
})

# Corners ----------------------------------------------------------------------

lim_10k <- c(xmin = 0, ymin = 0, xmax = 10000, ymax = 10000)
at      <- function(x, y) sf::st_sfc(sf::st_point(c(x, y)), crs = 3857)

test_that("the globe takes the first free corner", {
  free <- place_globe(lim_10k, at(5000, 5000))
  expect_equal(free$corner, "tr")
  expect_equal(free$x, 10000 - 300 - 1000)
  expect_equal(free$r, 1000)

  expect_equal(place_globe(lim_10k, at(8800, 8800))$corner, "tl")   # a site top right
  expect_equal(place_globe(lim_10k, c(at(8800, 8800), at(1200, 8800)))$corner, "br")
})

test_that("the rose takes the first free corner the globe left", {
  expect_equal(place_rose(lim_10k, at(5000, 5000)), "tr")
  expect_equal(place_rose(lim_10k, at(5000, 5000), taken = "tr"), "tl")
  expect_equal(place_rose(lim_10k, at(1000, 9000), taken = "tr"), "br")
})

test_that("disc points fill the globe's footprint and nothing outside it", {
  pts <- disc_points(list(x = 0, y = 0, r = 1000))
  xy  <- sf::st_coordinates(sf::st_transform(pts, 3857))
  expect_true(all(xy[, 1]^2 + xy[, 2]^2 <= 1000^2 + 1))
  expect_gt(length(pts), 40L)
  expect_equal(sf::st_crs(pts)$epsg, 4326)
})

# Basemap ----------------------------------------------------------------------

test_that("basemap sources: mapbox needs a token, natgeo is light and capped, coast has no tiles", {
  expect_error(basemap_source("mapbox", ""), "MAPBOX_TOKEN")
  expect_true(basemap_source("natgeo")$light)
  expect_lt(basemap_source("natgeo")$auto_max, basemap_source("natgeo")$max_zoom)
  expect_null(basemap_source("coast")$provider)
  expect_match(basemap_source("esri")$credit, "Esri")
})

test_that("the coast basemap fetches Global Islands land for an area", {
  skip_if_offline()
  skip_on_cran()

  bikar <- sf::st_as_sfc(sf::st_bbox(c(xmin = 170.05, ymin = 12.15, xmax = 170.16, ymax = 12.31),
                                     crs = 4326))
  land <- global_islands(bikar)
  expect_s3_class(land, "sf")
  expect_gte(nrow(land), 1L)
  expect_equal(sf::st_crs(land)$epsg, 4326)

  ocean <- sf::st_as_sfc(sf::st_bbox(c(xmin = -140, ymin = -30, xmax = -139.9, ymax = -29.9),
                                     crs = 4326))
  expect_equal(nrow(global_islands(ocean)), 0L)
})

# Insets -----------------------------------------------------------------------

test_that("the locator globe is a bare ggplot centred on the frame", {
  skip_if_not_installed("rnaturalearth")
  skip_if_not_installed("rnaturalearthdata")

  g <- locator_globe(frame_from_extent(c(170.0, 12.2, 170.2, 12.3)), ps_ink("map"))
  expect_s3_class(g, "ggplot")
  expect_length(g$layers, 4L)
  expect_match(sf::st_crs(g$coordinates$crs)$proj4string, "lon_0=170.1")
})

test_that("the compass rose is a grob of eight points", {
  g <- north_rose("#C6D2DC")
  expect_s3_class(g, "gTree")
  expect_length(g$children, 12L)   # 4 open intercardinals + 4 cardinals in 2 halves
})

# Map --------------------------------------------------------------------------

test_that("bad frame settings are refused before any work is done", {
  expect_error(map_uvs_sites(rmi_2023_uvs_sites, expand = -1), "expand")
  expect_error(map_uvs_sites(rmi_2023_uvs_sites, min_span = 0), "min_span")
})

test_that("the bundled expedition selects and encodes cleanly", {
  sel <- uvs_map_selection(rmi_2023_uvs_sites, region = "Bikar")
  expect_equal(nrow(sel), 15L)
  pts <- uvs_map_encode(sel, outline = "#EEF3F7")
  expect_true(all(pts$outline == "#EEF3F7"))     # every Bikar habitat is a filled shape
})

test_that("returns a ggplot with the title block and the frame it drew", {
  skip_if_not_installed("maptiles")
  skip_if_not_installed("tidyterra")
  skip_if_not_installed("ggspatial")
  skip_if_offline()
  skip_on_cran()

  p <- map_uvs_sites(rmi_2023_uvs_sites, region = "Bikar", zoom = 9)
  expect_s3_class(p, "ggplot")
  expect_equal(p$labels$subtitle, "Bikar · 15 sites")
  expect_equal(p$labels$caption, "Imagery: Esri World Imagery")
  expect_named(attr(p, "extent"), c("xmin", "ymin", "xmax", "ymax"))

  # the frame it drew, handed back, reproduces the same frame
  q <- map_uvs_sites(rmi_2023_uvs_sites, region = "Bikar", zoom = 9, extent = attr(p, "extent"))
  expect_equal(attr(q, "extent"), attr(p, "extent"), tolerance = 1e-3)

  expect_match(map_uvs_sites(rmi_2023_uvs_sites, region = "Bikar", basemap = "coast")$labels$caption,
               "Global Islands")
})
