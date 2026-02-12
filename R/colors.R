# Pristine Seas Color Palettes ------------------------------------------------
# Internal objects (not exported)

# All palettes in one registry
ps_palettes <- list(

  # depth strata
  depth_strata = c(
    supershallow = "#9DEFFF",
    shallow      = "#8FB8D8",
    deep         = "#264E86",
    superdeep    = "#0B1026"
  ),

  # exposure
  exposure = c(
    # --- Core (most used)
    windward  = "#8C1D18",
    leeward   = "#2E6F95",
    lagoon    = "#2CB1A6",

    # --- Secondary (tints of core hues)
    exposed   = "#C75A4A",  # lighter windward tint
    channel   = "#1F4E79",  # darker leeward variant
    sheltered = "#8FD6CF",  # lighter lagoon tint

    # --- Neutral
    unknown   = "#CFCFCF"
  ),

  # reef fish trophic groups
  trophic_group = c(
    shark                     = "#7A0010",
    top_predator              = "#E0B83F",
    lower_carnivore           = "#8EC9F0",
    "herbivore | detritivore" = "#1F7A4C",
    planktivore               = "#B9A3E3"
  ),

  # benthic functional groups
  functional_groups = c(
    hard_coral                   = "#2E4A9E",
    cca                          = "#FF7FA7",
    soft_coral                   = "#6FD3E3",
    algae_erect                  = "#2FA84F",

    algae_encrusting             = "#8FCFA9",
    algae_canopy                 = "#8A7A3A",
    sponges                      = "#E07A5F",
    other                        = "#7A5C8F",

    cyanobacteria                = "#0B0B0B",
    turf                         = "#4A3A2A",

    "sediment | rubble | barren" = "#D9D9D9"
  ),

  # UVS habitat types
  uvs_habitats = c(
    fore_reef     = "#E26B47",
    back_reef     = "#F39C6B",
    patch_reef    = "#F4A7B9",
    pinnacle_reef = "#C23B55",
    reef_flat     = "#4FC3D5",
    channel_pass  = "#2F6FA3",
    reef_pavement = "#B19A7A",
    bank          = "#CFAF7A",
    rocky_reef    = "#6B7078",
    wall          = "#3E4A52",
    kelp_forest   = "#2E6A3B",
    seagrass      = "#7BBF3F"
  )
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
#' ps_colors()                    # list available palettes
#' ps_colors("trophic_group")     # named vector
#' ps_colors("functional_groups") # named vector
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
#' ps_show_palette("functional_groups", ncol = 3)
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
#'                                          levels = names(ps_colors("uvs_habitats"))),
#'                         species_richness = c(42, 35, 20),
#'                         se = c(10, 8, 9))
#'
#' ggplot(diversity,
#'        aes(x = species_richness, y = habitat, color = habitat)) +
#'   geom_point(size = 4) +
#'   geom_errorbar(aes(xmin = species_richness - se, xmax = species_richness + se), width = 0.2) +
#'   scale_color_ps("uvs_habitats", drop = TRUE) +
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
#'                      functional_group = factor(rep(c("hard_coral", "soft_coral", "cca", "turf",
#'                                                      "algae_erect", "algae_encrusting", "algae_canopy",
#'                                                      "sponges", "cyanobacteria", "other", "sediment | rubble | barren"), 2),
#'                                                levels = rev(names(ps_colors("functional_groups")))),
#'                      cover            = c(32, 5, 18, 15, 8, 3, 2, 4, 1, 2, 10, 22, 8, 12, 20, 10, 5, 4, 6, 3, 3, 7))
#'
#' ggplot(benthic,
#'        aes(x = site, y = cover, fill = functional_group)) +
#'   geom_col(position = "stack") +
#'   scale_fill_ps("functional_groups") +
#'   labs(x = NULL, y = "Cover (%)", fill = "Functional group") +
#'   theme_ps()
#'
#' # Fish biomass by trophic group (stacked bar)
#'
#' fish_trophic <- data.frame(site = rep(c("Protected", "Fished"), each = 5),
#'                            trophic_group = factor(rep(c("shark", "top_predator", "lower_carnivore",
#'                                                         "herbivore | detritivore", "planktivore"), 2),
#'                                                   levels = rev(names(ps_colors("trophic_group")))),
#'   biomass = c(45, 120, 180, 210, 95, 5, 35, 150, 190, 80)/2)
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
