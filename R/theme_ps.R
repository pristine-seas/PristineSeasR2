#' Pristine Seas ggplot2 theme
#'
#' A clean, publication-ready ggplot2 theme
#'
#' @param base_size Numeric. Base font size. Default is 12.
#' @param base_family Character. Base font family. Default is "Helvetica".
#'
#' @return A ggplot2 theme object.
#' @importFrom ggplot2 theme_minimal theme element_rect element_line element_blank
#'   element_text margin %+replace%
#' @importFrom grid unit
#' @export
#'
#' @examples
#' library(ggplot2)
#' ggplot(mpg, aes(class, hwy)) +
#'   geom_boxplot(fill = "#0A9396", color = "white") +
#'   labs(title = "Fuel efficiency by car class") +
#'   theme_ps()
#'
theme_ps <- function(base_size = 12, base_family = "Helvetica") {
  ggplot2::theme_minimal(base_size = base_size, base_family = base_family) %+replace%
    ggplot2::theme(
      # Backgrounds
      plot.background  = ggplot2::element_rect(fill = "#f9f9f9", color = NA),
      panel.background = ggplot2::element_rect(fill = "#f9f9f9", color = NA),
      panel.grid.major = ggplot2::element_line(color = "#e1e1e1", linewidth = 0.4),
      panel.grid.minor = ggplot2::element_blank(),

      # Axes
      axis.ticks       = ggplot2::element_blank(),
      axis.line        = ggplot2::element_blank(),
      axis.text        = ggplot2::element_text(size = base_size, color = "#3a3a3a"),
      axis.text.x      = ggplot2::element_text(angle = 45, hjust = 1, vjust = 1,
                                               size = base_size, color = "#3a3a3a"),
      axis.title       = ggplot2::element_text(size = base_size + 1, face = "bold", color = "#1f1f1f"),

      # Titles and subtitles
      plot.title       = ggplot2::element_text(size = base_size + 6, face = "bold", color = "#0f1c1f", hjust = 0, margin = ggplot2::margin(b = 6)),
      plot.subtitle    = ggplot2::element_text(size = base_size + 1, color = "#4c4c4c", hjust = 0, margin = ggplot2::margin(b = 10)),
      plot.caption     = ggplot2::element_text(size = base_size - 1, color = "#6b6b6b", hjust = 1, face = "italic", margin = ggplot2::margin(t = 8)),

      # Legends
      legend.position   = "bottom",
      legend.title      = ggplot2::element_text(face = "bold", color = "#1f1f1f"),
      legend.text       = ggplot2::element_text(color = "#3a3a3a"),
      legend.background = ggplot2::element_blank(),
      legend.key.size   = grid::unit(0.4, "cm"),

      # Facet strips
      strip.background = ggplot2::element_rect(fill = "#efefef",          # neutral light gray
                                               color = "#d0d0d0",         # subtle border
                                               linewidth = 0.5),
      strip.text = ggplot2::element_text(size  = base_size + 0.5,   # slightly larger for hierarchy
                                         face  = "bold",
                                         color = "#0f1c1f",
                                         margin = ggplot2::margin(2, 4, 2, 4)),
      # Margins
      plot.margin = ggplot2::margin(10, 20, 10, 10)
    )
  }
