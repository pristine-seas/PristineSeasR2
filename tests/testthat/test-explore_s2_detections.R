make_detections <- function() {
  tibble::tibble(
    detect_id        = c("S2A_MSIL1C_20250203T232211_N0511_R044_T59PLQ_20250204T005724;169.87;12.95",
                         "S2B_MSIL1C_20250108T232209_N0511_R044_T58PGU_20250109T002400;167.78;11.97"),
    detect_timestamp = as.POSIXct(c("2025-02-03 23:22:11", "2025-01-08 23:23:05"), tz = "UTC"),
    detect_lat       = c(12.95, 11.97),
    detect_lon       = c(169.87, 167.78),
    scene_id         = c("S2A_MSIL1C_20250203T232211_N0511_R044_T59PLQ_20250204T005724",
                         "S2B_MSIL1C_20250108T232209_N0511_R044_T58PGU_20250109T002400"),
    ssvid            = c("412345678", NA),
    length_m_inferred = c(63.2, 24.1),
    presence_score   = c(0.94, 0.58),
    cloud_score      = c(0.006, 0.013)
  )
}

# Crops are the only thing that needs Earth Engine, so pre-seeding the cache
# with the files the function would have downloaded exercises everything else —
# popups, palette, lightbox payload, export — with no network and no credentials.
seed_cache <- function(detections, dir, buffer_m = 500, view = "ocean") {
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  px  <- as.integer(ceiling(2 * buffer_m / 10))
  png <- system.file("img", "Rlogo.png", package = "png")
  if (!nzchar(png)) png <- file.path(R.home("doc"), "html", "logo.jpg")
  for (v in view) {
    for (f in s2_thumb_path(detections$detect_id, dir, buffer_m, px, v)) file.copy(png, f)
  }
  dir
}

test_that("returns a leaflet htmlwidget when every crop is cached", {
  d <- make_detections()
  m <- explore_s2_detections(d, cache_dir = seed_cache(d, withr::local_tempdir()))
  expect_s3_class(m, "leaflet")
  expect_s3_class(m, "htmlwidget")
})

test_that("errors when detections is missing a required column", {
  bad <- dplyr::select(make_detections(), -presence_score)
  expect_error(explore_s2_detections(bad), "presence_score")
})

test_that("errors when detections has no rows", {
  expect_error(explore_s2_detections(make_detections()[0, ]), "no rows")
})

test_that("errors when exporting without a title", {
  expect_error(
    explore_s2_detections(make_detections(), export_path = tempfile(fileext = ".html")),
    "`title` is required"
  )
})

test_that("crops are inlined, so the exported map carries no expiring links", {
  d   <- make_detections()
  dir <- seed_cache(d, withr::local_tempdir())
  m   <- explore_s2_detections(d, cache_dir = dir)
  js  <- m$jsHooks$render[[length(m$jsHooks$render)]]$code
  expect_match(js, "data:image/png;base64,", fixed = TRUE)
  expect_false(grepl("earthengine.googleapis.com", js, fixed = TRUE))
})

test_that("a matched detection carries its MMSI into popup and caption", {
  d   <- make_detections()
  dir <- seed_cache(d, withr::local_tempdir())
  m   <- explore_s2_detections(d, cache_dir = dir)

  popups <- m$x$calls[[which(vapply(m$x$calls, function(c) c$method, "") == "addCircleMarkers")]]$args
  popups <- unlist(popups)[grepl("s2-pop", unlist(popups))]

  # the matched row names its vessel, in both places the reader can look
  expect_match(popups[1], "412345678")
  expect_match(popups[1], "<b>AIS:</b> Matched")
  # the unmatched row says so, and names nobody
  expect_match(popups[2], "<b>AIS:</b> Not matched")
  expect_false(grepl("MMSI", popups[2]))

  js <- m$jsHooks$render[[length(m$jsHooks$render)]]$code
  expect_match(js, "412345678")
})

test_that("an ssvid that arrives as a double is not shown in scientific notation", {
  d <- make_detections()
  d$ssvid <- c(412345678, NA)                      # numeric, as read_csv delivers it
  dir <- seed_cache(d, withr::local_tempdir())
  m   <- explore_s2_detections(d, cache_dir = dir)
  js  <- m$jsHooks$render[[length(m$jsHooks$render)]]$code
  expect_match(js, "412345678", fixed = TRUE)
  expect_false(grepl("4.12345678e+08", js, fixed = TRUE))
})

test_that("ssvid becomes the AIS split when `matched` is absent", {
  d   <- make_detections()
  dir <- seed_cache(d, withr::local_tempdir())
  m   <- explore_s2_detections(d, cache_dir = dir)
  js  <- m$jsHooks$render[[length(m$jsHooks$render)]]$code
  expect_match(js, "Matched to AIS")
  expect_match(js, "Not matched to AIS")
})

test_that("a detection id is truncated in the middle, so both ends survive", {
  long <- paste0(strrep("a", 40), "|", strrep("b", 40))
  out  <- trunc_middle(long, 21)
  expect_equal(nchar(out), 21)
  expect_true(startsWith(out, "aaaa"))
  expect_true(endsWith(out, "bbbb"))
  expect_equal(trunc_middle("short", 21), "short")
})

test_that("two views give every detection two crops, side by side", {
  d   <- make_detections()
  dir <- seed_cache(d, withr::local_tempdir(), view = c("ocean", "nir"))
  m   <- explore_s2_detections(d, cache_dir = dir, view = c("ocean", "nir"))
  js  <- m$jsHooks$render[[length(m$jsHooks$render)]]$code

  # both panels are named, and every detection carries a url for each
  expect_match(js, "Ocean stretch")
  expect_match(js, "Near-infrared")
  items <- jsonlite::fromJSON(sub('.*var items = (\\[.*?\\]), views.*', "\\1", js),
                              simplifyVector = FALSE)
  expect_length(items, nrow(d))
  expect_true(all(vapply(items, function(it) length(it$urls) == 2L, logical(1))))

  # the popup link says so
  popups <- unlist(m$x$calls[[which(vapply(m$x$calls, function(c) c$method, "") ==
                                      "addCircleMarkers")]]$args)
  expect_match(popups[grepl("s2-pop", popups)][1], "View Sentinel-2 crops")
})

test_that("a single view still renders one panel and reads as a thumbnail", {
  d   <- make_detections()
  dir <- seed_cache(d, withr::local_tempdir())
  m   <- explore_s2_detections(d, cache_dir = dir)
  js  <- m$jsHooks$render[[length(m$jsHooks$render)]]$code
  items <- jsonlite::fromJSON(sub('.*var items = (\\[.*?\\]), views.*', "\\1", js),
                              simplifyVector = FALSE)
  expect_true(all(vapply(items, function(it) length(it$urls) == 1L, logical(1))))
  popups <- unlist(m$x$calls[[which(vapply(m$x$calls, function(c) c$method, "") ==
                                      "addCircleMarkers")]]$args)
  expect_match(popups[grepl("s2-pop", popups)][1], "View Sentinel-2 thumbnail")
})

test_that("an unrecognised view is rejected", {
  expect_error(explore_s2_detections(make_detections(), view = "thermal"))
})

test_that("no line of the viewer's JS ends in `return`", {
  # Automatic semicolon insertion turns `return` at end of line into `return;`,
  # which once left every crop panel undefined and the viewer empty. The tests
  # above still passed, because the panel markup was present in the source.
  d   <- make_detections()
  dir <- seed_cache(d, withr::local_tempdir(), view = c("ocean", "nir"))
  m   <- explore_s2_detections(d, cache_dir = dir, view = c("ocean", "nir"))
  js  <- strsplit(m$jsHooks$render[[length(m$jsHooks$render)]]$code, "\n")[[1]]
  expect_false(any(grepl("\\breturn\\s*$", js)))
})

test_that("the gallery is added to the export, never to the returned widget", {
  d    <- make_detections()
  dir  <- seed_cache(d, withr::local_tempdir())
  out  <- withr::local_tempfile(fileext = ".html")

  m <- explore_s2_detections(d, cache_dir = dir, title = "t", export_path = out)

  # what the caller prints is the plain map — one hook, the crop viewer
  hooks <- vapply(m$jsHooks$render, function(h) grepl("s2-dash", h$code), logical(1))
  expect_false(any(hooks))

  # the exported page is the dashboard
  html <- paste(readLines(out, warn = FALSE), collapse = "\n")
  expect_match(html, "s2-dash", fixed = TRUE)
  expect_match(html, "by detection score", fixed = TRUE)
})

test_that("gallery = FALSE exports the map on its own", {
  d   <- make_detections()
  dir <- seed_cache(d, withr::local_tempdir())
  out <- withr::local_tempfile(fileext = ".html")
  explore_s2_detections(d, cache_dir = dir, gallery = FALSE, title = "t", export_path = out)
  html <- paste(readLines(out, warn = FALSE), collapse = "\n")
  # the stylesheet ships either way — it is the gallery's *code* that must be
  # absent, so assert on a string only the gallery script writes
  expect_false(grepl("by detection score", html, fixed = TRUE))
})

test_that("the viewer and the gallery run in score order, highest first", {
  d <- make_detections()                      # row 1 scores 0.94, row 2 scores 0.58
  dir <- seed_cache(d, withr::local_tempdir())
  m   <- explore_s2_detections(d, cache_dir = dir)
  js  <- m$jsHooks$render[[length(m$jsHooks$render)]]$code
  items <- jsonlite::fromJSON(sub('.*var items = (\\[.*?\\]), views.*', "\\1", js),
                              simplifyVector = FALSE)
  expect_equal(vapply(items, function(it) it$score, numeric(1)), c(0.94, 0.58))
})

test_that("exporting leaves one file and no dependency folder beside it", {
  d   <- make_detections()
  dir <- seed_cache(d, withr::local_tempdir())
  out_dir <- withr::local_tempdir()
  out <- file.path(out_dir, "map.html")

  explore_s2_detections(d, cache_dir = dir, title = "t", export_path = out)

  # saveWidget stages its dependencies next to the output and does not reliably
  # tidy up; the export must not leave that behind
  expect_equal(list.files(out_dir), "map.html")
  expect_false(dir.exists(file.path(out_dir, "map_files")))
})

test_that("a cold cache without an Earth Engine project fails by saying so", {
  d <- make_detections()                       # nothing seeded: every crop is missing
  expect_error(
    explore_s2_detections(d, cache_dir = withr::local_tempdir()),
    "pass `ee_project`", fixed = TRUE
  )
})

test_that("ee_connect refuses an empty project rather than passing it on", {
  expect_error(ee_connect(), "`project` is required", fixed = TRUE)
  expect_error(ee_connect(project = ""), "`project` is required", fixed = TRUE)
})
