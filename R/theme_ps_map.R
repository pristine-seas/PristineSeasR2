#' Pristine Seas map theme (ggplot2)
#'
#' Clean, publication-ready map theme with optional graticule/grid lines.
#'
#' @param default_font_family Character. Base font family (e.g., "Hind").
#' @param show_grid Logical. If TRUE, show major grid lines (useful for lon/lat graticules).
#' @param ... Additional arguments passed to `ggplot2::theme()`.
#'
#' @return A ggplot2 theme object.
#' @export
theme_ps_map <- function(default_font_family = "Hind",
                         show_grid           = TRUE,
                         ...) {

  # NOTE: avoid library() calls inside package functions.
  # Use explicit namespaces (ggplot2::, grid::) instead.

  # Text
  text_color_main    <- "#000000"
  text_color_axis    <- "#000000"
  text_color_caption <- "#222222"

  # Backgrounds
  background_color <- "#FFFFFF"

  # Grid
  grid_color <- "#CFCFC8"
  grid_size  <- 0.28

  # Sizes
  axis_text_size    <- 14
  title_size        <- 24
  subtitle_size     <- 16
  caption_size      <- 12
  legend_title_size <- 15
  legend_text_size  <- 14

  # Legend spacing
  legend_key_size_mm  <- 8
  legend_spacing_y_mm <- 5
  legend_spacing_x_mm <- 4

  ggplot2::theme_minimal(base_family = default_font_family) +
    ggplot2::theme(
      text = ggplot2::element_text(family = default_font_family,
                                   color  = text_color_main,
                                   face   = "plain"),

      # Axes
      axis.title = ggplot2::element_blank(),
      axis.text  = ggplot2::element_text(size  = axis_text_size,
                                         color = text_color_axis,
                                         face  = "plain"),
      axis.ticks = ggplot2::element_blank(),
      axis.line  = ggplot2::element_blank(),

      # Grid (graticules if you add coord_sf() labels / annotation)
      panel.grid.major = if (isTRUE(show_grid)) {
        ggplot2::element_line(color     = grid_color,
                              linewidth = grid_size)
      } else ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),

      # Backgrounds
      plot.background   = ggplot2::element_rect(fill  = background_color,
                                                color = NA),
      panel.background  = ggplot2::element_rect(fill  = background_color,
                                                color = NA),
      legend.background = ggplot2::element_rect(fill  = background_color,
                                                color = NA),
      legend.key        = ggplot2::element_blank(),

      # Margins / panel
      plot.margin  = grid::unit(c(1.0, 1.0, 0.8, 1.0), "cm"),
      panel.border = ggplot2::element_blank(),

      # Titles
      plot.title = ggplot2::element_text(size   = title_size,
                                         face   = "bold",
                                         color  = text_color_main,
                                         hjust  = 0,
                                         margin = ggplot2::margin(b = 10)),
      plot.subtitle = ggplot2::element_text(size   = subtitle_size,
                                            color  = text_color_main,
                                            hjust  = 0,
                                            margin = ggplot2::margin(b = 12)),

      # Caption
      plot.caption = ggplot2::element_text(size   = caption_size,
                                           hjust  = 1,
                                           color  = text_color_caption,
                                           margin = ggplot2::margin(t = 14)),

      # Legend
      legend.title = ggplot2::element_text(size  = legend_title_size,
                                           face  = "bold",
                                           color = text_color_main),
      legend.text = ggplot2::element_text(size  = legend_text_size,
                                          color = text_color_main),
      legend.key.size    = grid::unit(legend_key_size_mm, "mm"),
      legend.spacing.y   = grid::unit(legend_spacing_y_mm, "mm"),
      legend.spacing.x   = grid::unit(legend_spacing_x_mm, "mm"),
      legend.box.spacing = grid::unit(6, "mm"),

      ...
    )
}
