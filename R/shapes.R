# Pristine Seas Shape Palettes -------------------------------------------------
# The companion to colors.R: point shapes for classes that are better carried
# by form than by hue. Internal registry, public accessors that mirror
# ps_colors() / scale_fill_ps().

# All shape palettes in one registry
ps_shape_palettes <- list(

  # Three tiers, by how often a habitat is sampled:
  #   filled (21-25) for the zones sampled on most trips, which take a `fill`
  #   open   (0-2, 5-6) for zones sampled occasionally
  #   line   (3, 4, 8) for zones rarely sampled
  # The filled and open tiers pair the same five silhouettes (circle, square,
  # diamond, triangle, inverted triangle), so a legend reads as one family.
  habitat = c("fore_reef"     = 21L,
              "back_reef"     = 22L,
              "patch_reef"    = 23L,
              "fringing_reef" = 24L,
              "bank"          = 25L,
              "pinnacle_reef" =  1L,
              "reef_flat"     =  0L,
              "wall"          =  5L,
              "reef_pavement" =  2L,
              "rocky_reef"    =  6L,
              "channel_pass"  =  3L,
              "kelp_forest"   =  4L,
              "seagrass"      =  8L)

)

.ps_abort_unknown_shape_palette <- function(palette) {
  stop(
    "Unknown shape palette '", palette, "'.\n",
    "Available shape palettes: ", paste(names(ps_shape_palettes), collapse = ", "),
    call. = FALSE
  )
}

# Public API -------------------------------------------------------------------

#' Get Pristine Seas shapes
#'
#' Retrieve Pristine Seas point-shape palettes by name. The companion to
#' [ps_colors()] for classes that are carried by form rather than hue.
#'
#' The `"habitat"` palette covers every level of the habitat vocabulary in
#' three tiers. The five zones sampled on most trips take the filled shapes
#' (21 to 25), which draw with a `fill` and an outline `colour`. Zones sampled
#' occasionally take the matching open shapes (0, 1, 2, 5, 6), and zones rarely
#' sampled take line shapes (3, 4, 8). On a map the convention is that exposure
#' fills the marker and habitat sets its shape.
#'
#' @param palette Character. Name of the shape palette to retrieve. If
#'   `NULL`, returns the available palette names.
#'
#' @return If `palette` is `NULL`, a character vector of palette names.
#'   Otherwise, a named integer vector of R point shapes (see
#'   [graphics::points()]).
#'
#' @examples
#' ps_shapes()             # list available shape palettes
#' ps_shapes("habitat")    # named integer vector
#'
#' @seealso [scale_shape_ps()], [ps_colors()], [ps_habitat_colors()]
#' @export
ps_shapes <- function(palette = NULL) {

  if (is.null(palette)) {
    return(names(ps_shape_palettes))
  }

  if (!is.character(palette) || length(palette) != 1L || !nzchar(palette)) {
    stop("`palette` must be a single non-empty character string (or NULL).", call. = FALSE)
  }

  if (!palette %in% names(ps_shape_palettes)) {
    .ps_abort_unknown_shape_palette(palette)
  }

  ps_shape_palettes[[palette]]
}


#' Discrete shape scale using Pristine Seas shape palettes
#'
#' Convenience wrapper around [ggplot2::scale_shape_manual()] that pulls
#' shapes from [ps_shapes()], the way [scale_fill_ps()] pulls colours from
#' [ps_colors()].
#'
#' Filled shapes (21 to 25) take their interior from the `fill` aesthetic and
#' their outline from `colour`, so a site map that sets `fill = exposure` and
#' `shape = habitat` needs both `scale_fill_ps("exposure")` and this scale.
#' Open and line shapes draw entirely in `colour` and ignore `fill`.
#'
#' @param palette Character. Shape palette name passed to [ps_shapes()].
#' @param drop Logical. Passed to [ggplot2::scale_shape_manual()]. Default
#'   `FALSE` to preserve palette order even if levels are unused.
#' @param ... Additional arguments passed to [ggplot2::scale_shape_manual()].
#'
#' @return A ggplot2 shape scale.
#'
#' @examples
#' library(ggplot2)
#'
#' # Sites on a map: exposure fills the marker, habitat sets its shape
#' sites <- data.frame(
#'   lon      = c(-171.2, -171.1, -171.3, -171.0, -171.15),
#'   lat      = c(-13.9, -13.8, -13.85, -13.95, -13.75),
#'   habitat  = c("fore_reef", "back_reef", "patch_reef", "wall", "channel_pass"),
#'   exposure = c("windward", "lagoon", "sheltered", "exposed", "channel")
#' )
#'
#' ggplot(sites, aes(lon, lat, shape = habitat, fill = exposure)) +
#'   geom_point(size = 4, colour = ps_ink("map")[["title"]], stroke = 0.6) +
#'   scale_shape_ps("habitat", drop = TRUE) +
#'   scale_fill_ps("exposure", drop = TRUE) +
#'   guides(fill = guide_legend(override.aes = list(shape = 21))) +
#'   theme_ps_map()
#'
#' @export
scale_shape_ps <- function(palette, drop = FALSE, ...) {

  shp <- ps_shapes(palette)

  ggplot2::scale_shape_manual(
    values = shp,
    breaks = names(shp),
    drop   = drop,
    ...
  )
}
