#' Pristine Seas chart theme
#'
#' @description
#' The house ggplot2 theme for charts. A warm pampas canvas, a horizontal grid
#' that carries the eye without competing with the data, no ticks, and a title
#' block aligned to the plot rather than the panel.
#'
#' Shares its type scale, legend geometry, and title hierarchy with
#' [theme_ps_map()], so a chart and a map can sit side by side on one page and
#' read as a pair.
#'
#' @section Axis labels:
#' This theme does not rotate x-axis labels. Rotate where a particular figure
#' needs it, rather than everywhere:
#'
#' ```
#' theme_ps() + theme(axis.text.x = element_text(angle = 45, hjust = 1))
#' ```
#'
#' @param base_size Numeric. Base font size in points; every other size is a
#'   step from it. Default 12.
#' @param base_family Character. Base font family. Defaults to
#'   [ps_font_default()] — Inter where it is installed, otherwise Helvetica.
#'
#' @return A ggplot2 theme object.
#'
#' @seealso [theme_ps_map()] for maps, [ps_ink()] for the palette
#'   behind both, [scale_fill_ps()] and [scale_color_ps()] for data palettes.
#'
#' @importFrom ggplot2 theme_minimal theme element_rect element_line element_blank
#'   element_text margin
#' @importFrom grid unit
#' @export
#'
#' @examples
#' library(ggplot2)
#'
#' ggplot(mpg, aes(class, hwy)) +
#'   geom_boxplot(fill = "#1F6F8B", colour = "#14181A", linewidth = 0.3) +
#'   labs(title    = "Fuel efficiency by car class",
#'        subtitle = "Highway miles per gallon",
#'        x = NULL, y = "MPG") +
#'   theme_ps()
theme_ps <- function(base_size = 12, base_family = ps_font_default()) {

  ink <- ps_theme_inks$chart

  ps_theme_base(base_size   = base_size,
                base_family = base_family,
                ink         = ink,
                base        = ggplot2::theme_minimal) +
    ggplot2::theme(

      # A chart earns its grid; a map gets a graticule instead.
      panel.grid.major = ggplot2::element_line(colour    = ink[["grid"]],
                                               linewidth = 0.4),

      strip.background = ggplot2::element_rect(fill = ink[["strip"]], colour = NA),

      axis.title.x = ggplot2::element_text(margin = ggplot2::margin(t = 8)),
      axis.title.y = ggplot2::element_text(margin = ggplot2::margin(r = 8))
    )
}
