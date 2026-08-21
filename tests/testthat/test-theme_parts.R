test_that("ps_font_default returns a single usable family", {

  fam <- ps_font_default()

  expect_type(fam, "character")
  expect_length(fam, 1L)
  expect_true(nzchar(fam))
})

test_that("ps_font_default caches its answer", {

  expect_identical(ps_font_default(), ps_font_default())
})

test_that("the chosen family can render bold as a distinct face", {

  # The whole type hierarchy in both themes is built on weight. A variable font
  # registered under one family name resolves bold back to the same file and
  # index, which would silently flatten every title.
  skip_if_not_installed("systemfonts")

  fam <- ps_font_default()
  skip_if(fam == "sans", "no preferred family installed")

  expect_true(PristineSeasR2:::.ps_font_carries_bold(fam))
})

test_that("ps_ink returns both palettes with the shared names", {

  shared <- c("canvas", "panel", "grid", "strip", "title", "body", "muted")

  chart <- ps_ink("chart")
  map   <- ps_ink("map")

  expect_true(all(shared %in% names(chart)))
  expect_true(all(shared %in% names(map)))

  # Maps additionally carry the geography a hand-built basemap needs
  expect_true(all(c("land", "coast", "eez", "shelf") %in% names(map)))

  expect_identical(ps_ink(), chart)
  expect_error(ps_ink("nautical"))
})

test_that("chart and map inks are genuinely inverted", {

  luminance <- function(hex) {
    channels <- grDevices::col2rgb(hex)[, 1] / 255
    channels <- ifelse(channels <= 0.03928,
                       channels / 12.92,
                       ((channels + 0.055) / 1.055)^2.4)
    sum(channels * c(0.2126, 0.7152, 0.0722))
  }

  chart <- ps_ink("chart")
  map   <- ps_ink("map")

  # Chart canvas is light and its title dark; the map is the other way round
  expect_gt(luminance(chart[["canvas"]]), 0.6)
  expect_lt(luminance(chart[["title"]]),  0.1)

  expect_lt(luminance(map[["canvas"]]), 0.1)
  expect_gt(luminance(map[["title"]]),  0.6)
})

test_that("both themes build and are ggplot2 themes", {

  expect_s3_class(theme_ps(),     "theme")
  expect_s3_class(theme_ps_map(), "theme")

  # The signature theme_ps() has always had, still honoured
  expect_s3_class(theme_ps(base_size = 14, base_family = "Helvetica"), "theme")
  expect_s3_class(theme_ps_map(base_size = 16, graticule = FALSE), "theme")
})

test_that("the two themes share one type scale", {

  base <- 12
  chart <- theme_ps(base_size = base)
  map   <- theme_ps_map(base_size = base)

  expect_equal(chart$plot.title$size,    base + 6)
  expect_equal(map$plot.title$size,      base + 6)
  expect_equal(chart$plot.subtitle$size, map$plot.subtitle$size)
  expect_equal(chart$plot.caption$size,  map$plot.caption$size)

  expect_equal(chart$plot.title$face, "bold")
  expect_equal(map$plot.title$face,   "bold")

  # ...and one legend geometry
  expect_equal(chart$legend.position, map$legend.position)
  expect_equal(chart$legend.title.position, map$legend.title.position)
})

test_that("each theme paints its own canvas", {

  chart <- theme_ps()
  map   <- theme_ps_map()

  expect_equal(chart$plot.background$fill,  ps_ink("chart")[["canvas"]])
  expect_equal(chart$panel.background$fill, ps_ink("chart")[["panel"]])

  expect_equal(map$plot.background$fill,  ps_ink("map")[["canvas"]])
  expect_equal(map$panel.background$fill, ps_ink("map")[["panel"]])
})

test_that("theme_ps does not impose axis rotation", {

  # Rotation is a per-figure decision; baking it into the theme forced every
  # chart with short x labels to override it.
  chart <- theme_ps()

  expect_true(is.null(chart$axis.text.x) || is.null(chart$axis.text.x$angle))
})

test_that("graticule can be switched off on maps", {

  expect_s3_class(theme_ps_map(graticule = TRUE)$panel.grid.major,  "element_line")
  expect_s3_class(theme_ps_map(graticule = FALSE)$panel.grid.major, "element_blank")
})

test_that("themes render cleanly through ragg", {

  # ragg is the device these themes are documented to be drawn through; the base
  # pdf device has no access to system fonts and warns about the family alone,
  # which says nothing about the theme.
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("ragg")

  df <- data.frame(x = 1:5, y = c(2, 4, 3, 5, 4))

  png <- withr::local_tempfile(fileext = ".png")
  ragg::agg_png(png, width = 5, height = 4, units = "in", res = 72)
  on.exit(if (grDevices::dev.cur() > 1L) grDevices::dev.off(), add = TRUE)

  for (thm in list(theme_ps(), theme_ps_map())) {
    p <- ggplot2::ggplot(df, ggplot2::aes(x, y)) +
      ggplot2::geom_line() +
      ggplot2::labs(title = "T", subtitle = "S", caption = "C") +
      thm

    expect_silent(print(p))
  }

  grDevices::dev.off()
  expect_true(file.exists(png))
})

test_that("guide_ps_colourbar orients its long axis to the position", {

  horiz <- guide_ps_colourbar(length = 8, thickness = 0.35, position = "bottom")
  vert  <- guide_ps_colourbar(length = 8, thickness = 0.35, position = "right")

  h <- horiz$params$theme
  v <- vert$params$theme

  expect_equal(as.numeric(h$legend.key.width),  8)
  expect_equal(as.numeric(h$legend.key.height), 0.35)

  # Vertical swaps them, so the bar runs down rather than across
  expect_equal(as.numeric(v$legend.key.width),  0.35)
  expect_equal(as.numeric(v$legend.key.height), 8)
})

test_that("guide_ps_colourbar renders on both themes", {

  skip_if_not_installed("ragg")

  png <- withr::local_tempfile(fileext = ".png")
  ragg::agg_png(png, width = 6, height = 5, units = "in", res = 72)
  on.exit(if (grDevices::dev.cur() > 1L) grDevices::dev.off(), add = TRUE)

  p <- ggplot2::ggplot(ggplot2::faithfuld, ggplot2::aes(waiting, eruptions, fill = density)) +
    ggplot2::geom_raster() +
    ggplot2::scale_fill_viridis_c(guide = guide_ps_colourbar()) +
    theme_ps_map()

  expect_silent(print(p))
})


test_that("resolving the font registers it with pdf(), which cannot see system fonts", {
  fam <- ps_font_default()
  skip_if(fam %in% c("sans", "serif", "mono"), "no named family to register")
  expect_true(fam %in% names(grDevices::pdfFonts()))
})

test_that("a themed plot draws on pdf(), the device R opens by default", {
  skip_if_not_installed("ggplot2")
  f <- withr::local_tempfile(fileext = ".pdf")

  # Before the fix this was an "invalid font type" error, which took out every
  # PDF export and every example R CMD check ran.
  expect_no_error({
    grDevices::pdf(f)
    on.exit(grDevices::dev.off(), add = TRUE)
    print(
      ggplot2::ggplot(data.frame(x = 1:3, y = 1:3), ggplot2::aes(x, y)) +
        ggplot2::geom_point() +
        ggplot2::labs(title = "Bold title, regular body") +
        theme_ps_map()
    )
  })
})

test_that("registering is a no-op for a family pdf() already knows", {
  expect_false(PristineSeasR2:::.ps_register_device_font("Helvetica"))
  expect_false(PristineSeasR2:::.ps_register_device_font("sans"))
})

test_that("ps_theme_colors() still works, and is the same function under another name", {
  # called across the expedition pipelines, so it has to keep returning exactly
  # what the new name does \u2014 and silently
  expect_equal(ps_theme_colors("chart"), ps_ink("chart"))
  expect_equal(ps_theme_colors("map"),   ps_ink("map"))
  expect_equal(ps_theme_colors(),        ps_ink())
  expect_silent(ps_theme_colors("map"))
})
