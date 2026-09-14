test_that("ps_colors lists the five palettes and returns valid hex", {

  expect_identical(ps_colors(),
                   c("depth_strata", "trophic_group", "benthic_cover",
                     "exposure", "habitat"))

  for (pal in ps_colors()) {
    cols <- ps_colors(pal)
    expect_type(cols, "character")
    expect_false(is.null(names(cols)), info = pal)
    expect_true(all(nzchar(names(cols))), info = pal)
    expect_true(all(grepl("^#[0-9A-F]{6}$", cols)), info = pal)
    expect_false(anyDuplicated(names(cols)) > 0, info = pal)
  }
})

test_that("palette keys match the vocabulary they colour", {

  expect_true(all(names(ps_colors("benthic_cover")) %in%
                    allowed_vocab$functional_groups))
  expect_setequal(names(ps_colors("exposure")), allowed_vocab$exposure)
  expect_true(all(names(ps_colors("habitat")) %in% allowed_vocab$uvs_habitats))
  expect_length(ps_colors("habitat"), 5L)
})

test_that("ps_colors rejects bad input", {

  expect_error(ps_colors("functional_groups"), "Unknown palette")
  expect_error(ps_colors(""), "single non-empty")
  expect_error(ps_colors(c("exposure", "habitat")), "single non-empty")
})

test_that("ps_habitat_colors assigns the slots in order", {

  out <- ps_habitat_colors(c("wall", "fore_reef", "seagrass"))

  expect_identical(names(out), c("wall", "fore_reef", "seagrass"))
  expect_identical(unname(out), unname(ps_colors("habitat")[1:3]))

  expect_error(ps_habitat_colors(character()), "at least one")
  expect_error(ps_habitat_colors(allowed_vocab$uvs_habitats), "5 slots")
})

test_that("the ggplot2 scales map levels to palette colours", {

  skip_if_not_installed("ggplot2")

  df <- data.frame(x = 1:2, g = c("shark", "planktivore"))
  p <- ggplot2::ggplot(df, ggplot2::aes(x, x, fill = g)) +
    ggplot2::geom_col() +
    scale_fill_ps("trophic_group")

  fills <- ggplot2::layer_data(p)$fill
  expect_setequal(fills, unname(ps_colors("trophic_group")[c("shark", "planktivore")]))
})
