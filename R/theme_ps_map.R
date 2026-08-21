#' Pristine Seas map theme
#'
#' @description
#' The house ggplot2 theme for maps: deep water, a barely-there graticule, a
#' hairline panel frame, and no axis titles. The dark canvas is the working part
#' of the design — the layers Pristine Seas maps carry are sparse and
#' log-distributed (fishing effort, thermal stress, habitat suitability), and on
#' a light ground they wash out. Here the data is the only bright thing on the
#' page.
#'
#' Shares its type scale, legend geometry, and title hierarchy with [theme_ps()],
#' so a map and a chart can sit side by side on one page and read as a pair.
#'
#' @section Drawing on it:
#' The theme paints the canvas; the geography is yours to draw. Take its colors
#' from [ps_ink()] so they land in the same key:
#'
#' ```
#' ink <- ps_ink("map")
#'
#' ggplot() +
#'   geom_spatraster(data = effort) +
#'   geom_spatvector(data = land, fill = ink[["land"]], colour = ink[["coast"]]) +
#'   geom_spatvector(data = eez,  fill = NA, colour = ink[["eez"]], linetype = "22") +
#'   theme_ps_map()
#' ```
#'
#' A continuous fill wants a wide, thin bar along the bottom; a categorical key
#' reads better stacked at the right. In ggplot2 3.5 and later each guide can
#' choose for itself, so the two need not compete for one strip:
#'
#' ```
#' guide_colourbar(position = "bottom")
#' guide_legend(position = "right", direction = "vertical")
#' ```
#'
#' @section Exporting:
#' Nothing special is required. The theme paints an opaque `plot.background`
#' over the whole plot, and `ggsave()` reads that fill when its own `bg` is
#' unset — so a saved map carries its canvas without being told:
#'
#' ```
#' ggsave("map.png", p, width = 11, height = 10, dpi = 400)
#' ```
#'
#' Passing `bg` only changes anything if `plot.background` has been blanked or
#' made transparent. See [ps_font_default()] for the one device caveat that does
#' matter — `pdf()`, which cannot see system fonts and is handled by aliasing the
#' family onto Helvetica rather than by failing.
#'
#' @param base_size Numeric. Base font size in points; every other size is a
#'   step from it. Default 12. Large-format maps usually want 13–16.
#' @param base_family Character. Base font family. Defaults to
#'   [ps_font_default()] — Inter where it is installed, otherwise Helvetica.
#' @param graticule Logical. Draw longitude/latitude grid lines. Default `TRUE`.
#'
#' @return A ggplot2 theme object.
#'
#' @seealso [theme_ps()] for charts, [ps_ink()] for the palette behind
#'   both.
#'
#' @importFrom ggplot2 theme_void theme element_rect element_line element_blank
#'   element_text margin
#' @importFrom grid unit
#' @export
#'
#' @examples
#' library(ggplot2)
#'
#' ink <- ps_ink("map")
#'
#' ggplot(faithfuld, aes(waiting, eruptions, fill = density)) +
#'   geom_raster() +
#'   scale_fill_viridis_c(option = "inferno", name = "Density") +
#'   labs(title    = "A dark canvas for sparse layers",
#'        subtitle = "The data is the only bright thing on the page") +
#'   theme_ps_map()
theme_ps_map <- function(base_size   = 12,
                         base_family = ps_font_default(),
                         graticule   = TRUE) {

  ink <- ps_theme_inks$map

  ps_theme_base(base_size   = base_size,
                base_family = base_family,
                ink         = ink,
                base        = ggplot2::theme_void) +
    ggplot2::theme(

      # Coordinates label themselves; "Longitude" underneath adds nothing.
      axis.title = ggplot2::element_blank(),
      axis.text  = ggplot2::element_text(size = base_size - 2, colour = ink[["muted"]]),

      # A hairline frame closes the panel so the map reads as a plate. Same
      # colour as the graticule, so the frame never outranks the geography.
      panel.border = ggplot2::element_rect(fill      = NA,
                                           colour    = ink[["grid"]],
                                           linewidth = 0.6),

      panel.grid.major = if (isTRUE(graticule)) {
        ggplot2::element_line(colour = ink[["grid"]], linewidth = 0.25)
      } else {
        ggplot2::element_blank()
      },

      # Colourbar ticks in the canvas colour: they punch through the ramp as
      # gaps rather than sitting on it as marks.
      legend.ticks = ggplot2::element_line(colour = ink[["canvas"]], linewidth = 0.7),
      legend.frame = ggplot2::element_blank(),

      panel.spacing = grid::unit(0.9, "lines"),
      plot.margin   = ggplot2::margin(20, 24, 14, 24)
    )
}
