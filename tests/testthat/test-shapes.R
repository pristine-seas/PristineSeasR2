test_that("the habitat shape palette covers the vocabulary in three tiers", {

  shp <- ps_shapes("habitat")

  expect_identical(ps_shapes(), "habitat")
  expect_type(shp, "integer")
  expect_setequal(names(shp), allowed_vocab$uvs_habitats)

  filled <- shp[shp >= 21]
  open   <- shp[shp %in% c(0, 1, 2, 5, 6)]
  line   <- shp[shp %in% c(3, 4, 8)]

  expect_length(filled, 5L)
  expect_length(open,   5L)
  expect_length(line,   3L)
  expect_length(c(filled, open, line), length(shp))

  # the filled tier is exactly the colour palette's five default slots
  expect_setequal(names(filled), names(ps_colors("habitat")))
})

test_that("ps_shapes rejects bad input", {

  expect_error(ps_shapes("exposure"), "Unknown shape palette")
  expect_error(ps_shapes(""), "single non-empty")
})

test_that("scale_shape_ps maps levels to palette shapes", {

  skip_if_not_installed("ggplot2")

  df <- data.frame(x = 1:3, h = c("fore_reef", "wall", "seagrass"))
  p <- ggplot2::ggplot(df, ggplot2::aes(x, x, shape = h)) +
    ggplot2::geom_point() +
    scale_shape_ps("habitat")

  shapes <- ggplot2::layer_data(p)$shape
  expect_setequal(shapes, unname(ps_shapes("habitat")[df$h]))
})
