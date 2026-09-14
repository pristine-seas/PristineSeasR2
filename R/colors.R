# Pristine Seas Color Palettes ------------------------------------------------
# Internal objects (not exported)

# All palettes in one registry
ps_palettes <- list(

  depth_strata = c("supershallow" = "#96D8DE",
                   "shallow"      = "#52B2CD",
                   "deep"         = "#007EB1",
                   "superdeep"    = "#015871"),

  trophic_group = c("shark"                   = "#75161D",
                    "top_predator"            = "#AC2D00",
                    "lower_carnivore"         = "#B96310",
                    "herbivore | detritivore" = "#40AE82",
                    "planktivore"             = "#C1C2FA"),

  benthic_cover = c("hard_coral"                 = "#FFCD16",
                    "cca"                        = "#E563A4",
                    "sponges"                    = "#393A81",
                    "soft_coral"                 = "#DE98E3",
                    "other"                      = "#BAB5B1",
                    "algae_encrusting"           = "#0D5F5B",
                    "algae_erect"                = "#8EBB67",
                    "algae_canopy"               = "#784620",
                    "sediment | rubble | barren" = "#E8DDB7",
                    "turf"                       = "#7B8563",
                    "cyanobacteria"              = "#2C2234"),

  exposure = c("unknown"   = "#BAB5B1",
               "sheltered" = "#FDD2D7",
               "lagoon"    = "#F3A7B1",
               "leeward"   = "#E07F8E",
               "channel"   = "#BC5B6C",
               "windward"  = "#8F404F",
               "exposed"   = "#602A34"),

  # Five slots, named for the zones sampled on most trips. When a trip samples
  # other habitats, reassign the slots in order with ps_habitat_colors().
  habitat = c("fore_reef"     = "#005F87",
              "back_reef"     = "#DCA04F",
              "patch_reef"    = "#A5DBE0",
              "fringing_reef" = "#6F3F1B",
              "bank"          = "#8E81CE")

  # Retired 2026-09: too many classes to be distinct, and never used in a
  # figure. Kept for reference in case an invertebrate palette is revisited.
  # invert_groups = c("Ark clam"                 = "#5050FF",
  #                   "Barnacles"                 = "#CE3D32",
  #                   "Bivalves"                  = "#749B58",
  #                   "Boxer shrimps"             = "#F0E685",
  #                   "Brittle stars"             = "#466983",
  #                   "Carpet sea anemones"       = "#BA6338",
  #                   "Ceriths"                   = "#5DB1DD",
  #                   "Conchs"                    = "#802268",
  #                   "Cone snail"                = "#6BD76B",
  #                   "Coral crabs"               = "#D595A7",
  #                   "Crabs"                     = "#924822",
  #                   "Crown-of-thorns starfish"  = "#837B8D",
  #                   "Feather stars"             = "#C75127",
  #                   "Foam oysters"              = "#D58F5C",
  #                   "Giant clams"               = "#7A65A5",
  #                   "Hermit crabs"              = "#E4AF69",
  #                   "Mantis shrimp"             = "#3B1B53",
  #                   "Nudibranchs"               = "#CDDEB7",
  #                   "Octopus"                   = "#612A79",
  #                   "Pearl oysters"             = "#AE1F63",
  #                   "Penaeid shrimps"           = "#E7C76F",
  #                   "Sea anemones"              = "#5A655E",
  #                   "Sea cucumbers"             = "#CC9900",
  #                   "Sea slugs"                 = "#99CC00",
  #                   "Sea snails"                = "#A9A9A9",
  #                   "Sea stars"                 = "#33CC00",
  #                   "Sea urchins"               = "#00CC33",
  #                   "Shrimps"                   = "#00CC99",
  #                   "Slipper lobsters"          = "#0099CC",
  #                   "Spiny lobsters"            = "#0A47FF",
  #                   "Sponges"                   = "#4775FF",
  #                   "Swimming crabs"            = "#FFC20A",
  #                   "Top shells"                = "#FFD147",
  #                   "Triton snails"             = "#990033",
  #                   "Turban snails"             = "#991A00",
  #                   "Vase snails"               = "#996600",
  #                   "Worms"                     = "#809900",
  #                   "Xanthid crabs"             = "#339900")

)


# Small internal helpers -----------------------------------------------------

.ps_abort_unknown_palette <- function(palette) {
  stop(
    "Unknown palette '", palette, "'.\n",
    "Available palettes: ", paste(names(ps_palettes), collapse = ", "),
    call. = FALSE
  )
}

# Public API -----------------------------------------------------------------

#' Get Pristine Seas colors
#'
#' Retrieve Pristine Seas color palettes by name.
#'
#' Palettes are returned as named character vectors of hex color codes.
#'
#' @param palette Character. Name of the palette to retrieve. If \code{NULL},
#'   returns the available palette names.
#'
#' @return If \code{palette} is \code{NULL}, a character vector of palette names.
#' Otherwise, a named character vector of hex codes.
#'
#' @examples
#' ps_colors()                 # list available palettes
#' ps_colors("trophic_group")  # named vector
#' ps_colors("benthic_cover")  # named vector
#'
#' @export
ps_colors <- function(palette = NULL) {

  if (is.null(palette)) {
    return(names(ps_palettes))
  }

  if (!is.character(palette) || length(palette) != 1L || !nzchar(palette)) {
    stop("`palette` must be a single non-empty character string (or NULL).", call. = FALSE)
  }

  if (!palette %in% names(ps_palettes)) {
    .ps_abort_unknown_palette(palette)
  }

  ps_palettes[[palette]]
}


#' Assign the habitat palette to the habitats a trip sampled
#'
#' The `"habitat"` palette has five slots, named by default for the zones
#' sampled on most expeditions (fore reef, back reef, patch reef, fringing
#' reef, bank). Trips that sample other habitats reassign the same five
#' colours, in order, to the habitats they have, so a figure always uses the
#' same well-separated set no matter which zones were surveyed.
#'
#' @param levels Character. Habitat names in the order they should take the
#'   palette slots, typically `levels(df$habitat)` or the habitats present in
#'   the data. At most five.
#'
#' @return A named character vector of hex codes, one per level, in the order
#'   given.
#'
#' @examples
#' ps_habitat_colors(c("fore_reef", "pinnacle_reef", "wall"))
#'
#' @seealso [ps_colors()], [ps_shapes()] for the matching habitat shapes
#' @export
ps_habitat_colors <- function(levels) {

  levels <- unique(as.character(levels))
  slots  <- ps_palettes[["habitat"]]

  if (length(levels) == 0L) {
    stop("`levels` must contain at least one habitat.", call. = FALSE)
  }
  if (length(levels) > length(slots)) {
    stop("The habitat palette has ", length(slots), " slots; ",
         length(levels), " habitats were supplied.", call. = FALSE)
  }

  out <- unname(slots[seq_along(levels)])
  names(out) <- levels
  out
}


#' Preview a Pristine Seas palette
#'
#' Quick visualization helper to inspect palettes at a glance.
#'
#' If \pkg{ggplot2} is installed, returns a ggplot swatch plot.
#' Otherwise, draws a simple base R swatch plot.
#'
#' @param palette Character. Palette name passed to \code{ps_colors()}.
#' @param show_labels Logical. Whether to display category labels. Default \code{TRUE}.
#' @param ncol Integer. Number of columns for the swatch grid. Default \code{NULL}
#'   (auto).
#'
#' @return A ggplot object if ggplot2 is available; otherwise invisibly returns
#'   \code{NULL} after plotting.
#'
#' @examples
#' \dontrun{
#' ps_show_palette("trophic_group")
#' ps_show_palette("benthic_cover", ncol = 4)
#' }
#'
#' @importFrom graphics par plot.new rect text title
#' @importFrom rlang .data
#' @export
ps_show_palette <- function(palette, show_labels = TRUE, ncol = NULL) {

  cols <- ps_colors(palette)

  n <- length(cols)
  if (n == 0) {
    stop("Palette '", palette, "' is empty.", call. = FALSE)
  }

  if (is.null(ncol)) {
    ncol <- min(5L, max(1L, ceiling(sqrt(n))))
  }

  nrow <- ceiling(n / ncol)

  if (requireNamespace("ggplot2", quietly = TRUE)) {

    df <- data.frame(
      name = factor(names(cols), levels = names(cols)),
      hex  = unname(cols),
      idx  = seq_len(n),
      stringsAsFactors = FALSE
    )
    df$row <- ((df$idx - 1L) %% nrow) + 1L
    df$col <- ((df$idx - 1L) %/% nrow) + 1L

    p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$col, y = -.data$row, fill = .data$name)) +
      ggplot2::geom_tile(color = "white", linewidth = 0.7, width = 0.95, height = 0.95) +
      ggplot2::scale_fill_manual(values = cols, guide = "none") +
      ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0.02, 0.02))) +
      ggplot2::scale_y_continuous(expand = ggplot2::expansion(mult = c(0.02, 0.02))) +
      ggplot2::coord_fixed() +
      ggplot2::labs(title = paste0("Pristine Seas palette: ", palette)) +
      ggplot2::theme_minimal(base_size = 12) +
      ggplot2::theme(
        axis.title = ggplot2::element_blank(),
        axis.text  = ggplot2::element_blank(),
        axis.ticks = ggplot2::element_blank(),
        panel.grid = ggplot2::element_blank()
      )

    if (isTRUE(show_labels)) {
      p <- p + ggplot2::geom_text(
        ggplot2::aes(label = paste0(as.character(.data$name), "\n", .data$hex)),
        size = 3,
        lineheight = 0.95
      )
    }

    return(p)
  }

  # Base R fallback
  oldpar <- graphics::par(no.readonly = TRUE)
  on.exit(graphics::par(oldpar), add = TRUE)

  graphics::par(mar = c(1, 1, 3, 1))
  graphics::plot.new()
  graphics::title(main = paste0("Pristine Seas palette: ", palette))

  k <- 1L
  for (r in seq_len(nrow)) {
    for (c in seq_len(ncol)) {
      if (k > n) break
      x0 <- (c - 1) / ncol
      x1 <- c / ncol
      y1 <- 1 - (r - 1) / nrow
      y0 <- 1 - r / nrow
      graphics::rect(x0, y0, x1, y1, col = cols[k], border = "white")
      if (isTRUE(show_labels)) {
        graphics::text((x0 + x1) / 2, (y0 + y1) / 2,
                       labels = paste0(names(cols)[k], "\n", cols[k]),
                       cex = 0.75)
      }
      k <- k + 1L
    }
  }

  invisible(NULL)
}


# ggplot2 helpers ------------------------------------------------------------

#' Discrete color scale using Pristine Seas palettes
#'
#' Convenience wrapper around \code{ggplot2::scale_color_manual()} that pulls
#' colors from \code{ps_colors()}.
#'
#' Intended for discrete color aesthetics where factor levels match palette names.
#'
#' @param palette Character. Palette name passed to \code{ps_colors()}.
#' @param drop Logical. Passed to \code{ggplot2::scale_color_manual()}. Default \code{FALSE}
#'   to preserve palette order even if levels are unused.
#' @param ... Additional arguments passed to \code{ggplot2::scale_color_manual()}.
#'
#' @return A ggplot2 color scale.
#'
#' @seealso [scale_fill_ps()] for fill aesthetic, [ps_colors()] for raw palettes
#'
#' @examples
#' library(ggplot2)
#'
#' # Species diversity by habitat (points with error bars)
#' diversity <- data.frame(habitat = factor(c("fore_reef", "back_reef", "patch_reef"),
#'                                          levels = names(ps_colors("habitat"))),
#'                         species_richness = c(42, 35, 20),
#'                         se = c(10, 8, 9))
#'
#' ggplot(diversity,
#'        aes(x = species_richness, y = habitat, color = habitat)) +
#'   geom_point(size = 4) +
#'   geom_errorbar(aes(xmin = species_richness - se, xmax = species_richness + se), width = 0.2) +
#'   scale_color_ps("habitat", drop = TRUE) +
#'   labs(x = "Species richness", y = NULL) +
#'   theme_ps()
#'
#' @export
scale_color_ps <- function(palette, drop = FALSE, ...) {

  cols <- ps_colors(palette)

  ggplot2::scale_color_manual(
    values = cols,
    breaks = names(cols),
    drop   = drop,
    ...
  )
}


#' Discrete fill scale using Pristine Seas palettes
#'
#' Convenience wrapper around \code{ggplot2::scale_fill_manual()} that pulls
#' colors from \code{ps_colors()}.
#'
#' @inheritParams scale_color_ps
#'
#' @return A ggplot2 fill scale.
#'
#' @seealso [scale_color_ps()] for color aesthetic, [ps_colors()] for raw palettes
#'
#' @examples
#' library(ggplot2)
#'
#' # Benthic cover composition (stacked bar) - all functional groups
#'
#' benthic <- data.frame(site             = rep(c("Site A", "Site B"), each = 11),
#'                      functional_group = factor(rep(names(ps_colors("benthic_cover")), 2),
#'                                                levels = rev(names(ps_colors("benthic_cover")))),
#'                      cover            = c(52, 20, 2, 4, 2, 3, 2, 1, 6, 7, 1,
#'                                           14, 8, 4, 4, 4, 5, 18, 2, 12, 23, 6))
#'
#' ggplot(benthic,
#'        aes(x = site, y = cover, fill = functional_group)) +
#'   geom_col(position = "stack") +
#'   scale_fill_ps("benthic_cover") +
#'   labs(x = NULL, y = "Cover (%)", fill = "Functional group") +
#'   theme_ps()
#'
#' # Fish biomass by trophic group (stacked bar)
#'
#' fish_trophic <- data.frame(site = rep(c("Protected", "Fished"), each = 5),
#'                            trophic_group = factor(rep(names(ps_colors("trophic_group")), 2),
#'                                                   levels = rev(names(ps_colors("trophic_group")))),
#'                            biomass = c(45, 120, 180, 210, 95, 5, 35, 150, 190, 80) / 2)
#'
#' ggplot(fish_trophic,
#'        aes(x = site, y = biomass, fill = trophic_group)) +
#'   geom_col(position = "stack") +
#'   scale_fill_ps("trophic_group") +
#'   labs(x = NULL, y = expression(Biomass~(g/m^2)), fill = "Trophic group") +
#'   theme_ps()
#' @export
scale_fill_ps <- function(palette, drop = FALSE, ...) {

  cols <- ps_colors(palette)

  ggplot2::scale_fill_manual(
    values = cols,
    breaks = names(cols),
    drop   = drop,
    ...
  )
}
