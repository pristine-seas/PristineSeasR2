# theme_parts.R -----------------------------------------------------------------
# The shared foundation under theme_ps() and theme_ps_map().
#
# The two themes are one design in two inks. Everything structural — the type
# scale, the title hierarchy, legend geometry, margins, how a facet strip reads —
# is defined once, here. Each theme then supplies a palette and only the handful
# of elements that genuinely differ between a chart (y grid, axis titles, light
# paper) and a map (graticule, framed panel, no axis titles, dark water).
#
# That split is the point: a chart and a map from this package can sit side by
# side on one page and read as a pair rather than as two unrelated figures.
#
# Public API:
#   - ps_font_default(): the house typeface, resolved against installed fonts
#   - ps_ink(): the ink of each theme, for annotation layers you draw
#     yourself (an EEZ hairline, a callout label) that must match the canvas
#
# Internal: ps_theme_inks, ps_theme_base()

# Inks -------------------------------------------------------------------------
# Charts sit on pampas, a warm paper that reads as a chosen ground rather than
# an absence of colour. Maps invert to deep water, because the layers they carry
# — sparse, log-distributed rasters — only register against a dark canvas.
#
# Both inks clear WCAG AAA for titles and body (>= 7:1) and AA for muted text.
ps_theme_inks <- list(

  chart = c(canvas = "#F4F1EA",   # pampas
            panel  = "#F4F1EA",
            grid   = "#DDD7CA",
            strip  = "#E8E3D8",
            title  = "#14181A",
            body   = "#3C4145",
            muted  = "#6B7376"),

  map   = c(canvas = "#05101A",   # the page behind the map
            panel  = "#0A1C2B",   # water
            grid   = "#16293A",   # graticule and panel frame
            strip  = NA,          # map strips are bare text, not a filled bar
            title  = "#EEF3F7",
            body   = "#C6D2DC",
            muted  = "#8DA2B5")
)

# Geography drawn *on* a map theme rather than by it. Kept beside the map ink so
# a basemap built by hand lands in the same key as the theme around it.
ps_map_geography <- c(land   = "#38454F",
                      coast  = "#5A6B7A",
                      eez    = "#7E97AC",
                      shelf  = "#12304A")

# Typeface ---------------------------------------------------------------------

# Resolving system fonts costs enough to be worth doing once per session.
.ps_font_cache <- new.env(parent = emptyenv())

# A family is only usable here if `face = "bold"` actually reaches a different
# face. Variable fonts are the trap: a single-file build like Inter[opsz,wght]
# is installed under one family name, and asking for bold resolves back to the
# very same file and index — so every title in the theme silently renders at
# regular weight, and the type hierarchy quietly collapses.
.ps_font_carries_bold <- function(family) {

  tryCatch({
    plain <- systemfonts::match_fonts(family, weight = "normal")
    bold  <- systemfonts::match_fonts(family, weight = "bold")

    !(identical(plain$path, bold$path) && identical(plain$index, bold$index))
  },
  error = function(e) FALSE)
}

#' The Pristine Seas house typeface
#'
#' @description
#' Returns the first of Inter, Helvetica Neue, Helvetica, Arial that is both
#' installed **and** able to render bold as a distinct face, falling back to
#' `"sans"`. Inter is preferred where it qualifies — it is the closest freely
#' available stand-in for National Geographic's Geograph, with tighter apertures
#' and better numerals than Helvetica.
#'
#' Used as the default `base_family` for [theme_ps()] and [theme_ps_map()].
#'
#' @section Why bold is checked:
#' Both themes build their hierarchy on weight — bold titles, bold legend
#' titles, bold facet strips — against regular body text. Many systems ship
#' Inter as a *variable* font in a single file, where a request for bold
#' resolves to the same file and index as regular. Nothing errors; every title
#' just renders at regular weight and the hierarchy disappears. Rather than let
#' that happen silently, a family that cannot deliver bold is skipped in favour
#' of the next candidate. Install a static Inter build (Regular + Bold as
#' separate files) to get Inter back.
#'
#' @section Rendering:
#' A named family only survives on a device with access to system fonts.
#' Raster devices generally have it — **ragg** resolves through the same
#' `systemfonts` lookup used here, and on macOS the built-in `png(type =
#' "quartz")` does too. The one that bites is `pdf()`, which R opens by default
#' when no device is active (a bare `Rscript`, for instance): it matches against
#' the PostScript font database rather than against the system, and under grid —
#' so under every ggplot — a family it does not hold is a hard error, not a
#' substitution. Rather than let that turn every PDF export into a failure,
#' resolving the family also registers it with `pdf()`, aliased onto Helvetica's
#' metrics: type comes out Helvetica rather than Inter, which is the substitution
#' the device would have made if it could, and the figure draws. Cairo-based `png()` on Linux and CI is likewise patchier.
#'
#' In practice: `ggsave()` in ggplot2 >= 4.0 already uses ragg when it is
#' installed, so exports are fine without being told. Inline figures are the
#' ones worth setting, since knitr defaults to grDevices `png` —
#' `knitr: opts_chunk: dev: ragg_png` in the document YAML.
#'
#' @return A single font family name.
#' @examples
#' ps_font_default()
#' @export
ps_font_default <- function() {

  if (!is.null(.ps_font_cache$family)) return(.ps_font_cache$family)

  preferred <- c("Inter", "Helvetica Neue", "Helvetica", "Arial")

  installed <- tryCatch(unique(systemfonts::system_fonts()$family),
                        error = function(e) character(0))

  candidates <- preferred[preferred %in% installed]

  usable <- candidates[vapply(candidates, .ps_font_carries_bold, logical(1))]

  .ps_font_cache$family <- if (length(usable)) {
    usable[[1L]]
  } else if (length(candidates)) {
    candidates[[1L]]
  } else {
    "sans"
  }

  .ps_register_device_font(.ps_font_cache$family)

  .ps_font_cache$family
}

# The pdf() device keeps its own font database and knows nothing about installed
# system fonts. A family resolved above is not merely substituted there: under
# grid — and therefore under every ggplot — it is an "invalid font type" error.
# That device is what R opens when no other is active, which makes it what a bare
# `Rscript`, `ggsave()` to PDF, and every example R CMD check runs all land on.
#
# Aliasing the resolved name onto Helvetica's metrics makes the device accept it.
# The glyphs drawn are Helvetica's, which is the substitution that would have
# happened anyway had the device been able to fall back — so the figure is not
# wrong, it is merely not Inter.
#
# postscript() is deliberately left alone. It validates a family against the list
# the device was opened with rather than against the database, so registering
# there turns today's warn-and-substitute into a hard error: strictly worse.
.ps_register_device_font <- function(family) {

  if (length(family) != 1L || family %in% c("sans", "serif", "mono")) {
    return(invisible(FALSE))
  }

  known <- tryCatch(grDevices::pdfFonts(), error = function(e) NULL)
  if (is.null(known) || family %in% names(known) || is.null(known$Helvetica)) {
    return(invisible(FALSE))
  }

  spec <- list(known$Helvetica)
  names(spec) <- family

  tryCatch({
    do.call(grDevices::pdfFonts, spec)
    invisible(TRUE)
  }, error = function(e) invisible(FALSE))
}

#' The Ink Behind The Themes
#'
#' @description
#' The ink behind [theme_ps()] and [theme_ps_map()]. Use it when a figure needs
#' to draw something the theme does not supply — an EEZ hairline, a text halo, a
#' reference line, land polygons under a raster — and that mark has to sit in
#' the same key as the canvas around it.
#'
#' `"chart"` returns the paper palette; `"map"` returns the water palette plus
#' the geography colors (`land`, `coast`, `eez`, `shelf`) that a hand-built
#' basemap needs.
#'
#' @param theme Either `"chart"` (default) or `"map"`.
#'
#' @return A named character vector of hex codes. Names common to both: `canvas`,
#'   `panel`, `grid`, `strip`, `title`, `body`, `muted`.
#'
#' @seealso [ps_colors()] for the *data* palettes — trophic groups, habitats,
#'   functional groups — which encode categories rather than chrome.
#'
#' @examples
#' ps_ink("chart")
#' ps_ink("map")[["eez"]]
#'
#' \dontrun{
#' ink <- ps_ink("map")
#'
#' ggplot() +
#'   geom_spatvector(data = eez, fill = NA, colour = ink[["eez"]], linetype = "22") +
#'   geom_spatvector(data = land, fill = ink[["land"]], colour = ink[["coast"]]) +
#'   theme_ps_map()
#' }
#' @export
ps_ink <- function(theme = c("chart", "map")) {

  theme <- match.arg(theme)

  if (theme == "map") c(ps_theme_inks$map, ps_map_geography) else ps_theme_inks$chart
}

#' @rdname ps_ink
#'
#' @description
#' `ps_theme_colors()` is the original name for the same function. It is kept as
#' a plain alias — no warning, no behaviour of its own — because it is called
#' across the expedition pipelines. New code should prefer `ps_ink()`, which does
#' not read as a transposition of [theme_ps()] and is not mistaken for
#' [ps_colors()], the categorical palettes for data rather than for canvas.
#'
#' @export
ps_theme_colors <- function(theme = c("chart", "map")) {
  ps_ink(theme)
}

#' A colourbar proportioned for Pristine Seas figures
#'
#' @description
#' [ggplot2::guide_colourbar()] sized from the theme's legend key produces a bar
#' roughly two centimetres long — far too short for a continuous legend, whose
#' break labels then collide into an unreadable smear. This returns a colourbar
#' with proportions that suit a full-width figure: long, thin, and centred under
#' its title.
#'
#' Pair it with a categorical key placed at the right, so a continuous ramp and a
#' geography key never compete for the same strip:
#'
#' ```
#' scale_fill_gradientn(..., guide = guide_ps_colourbar())
#' scale_colour_manual(..., guide = guide_legend(position = "right"))
#' ```
#'
#' @param length Numeric. Long dimension of the bar, in centimetres. Default 8.
#' @param thickness Numeric. Short dimension of the bar, in centimetres.
#'   Default 0.35.
#' @param position Where the bar sits: `"bottom"` (default), `"top"`, `"right"`
#'   or `"left"`. The long dimension follows the orientation automatically.
#' @param ... Passed to [ggplot2::guide_colourbar()].
#'
#' @return A ggplot2 guide.
#'
#' @seealso [theme_ps_map()], [theme_ps()]
#'
#' @examples
#' library(ggplot2)
#'
#' ggplot(faithfuld, aes(waiting, eruptions, fill = density)) +
#'   geom_raster() +
#'   scale_fill_viridis_c(option = "inferno", name = "Density",
#'                        guide = guide_ps_colourbar()) +
#'   theme_ps_map()
#' @export
guide_ps_colourbar <- function(length    = 8,
                               thickness = 0.35,
                               position  = c("bottom", "top", "right", "left"),
                               ...) {

  position <- match.arg(position)

  horizontal <- position %in% c("bottom", "top")

  ggplot2::guide_colourbar(
    position = position,
    theme = ggplot2::theme(
      legend.key.width  = grid::unit(if (horizontal) length else thickness, "cm"),
      legend.key.height = grid::unit(if (horizontal) thickness else length, "cm"),
      legend.title      = ggplot2::element_text(hjust = if (horizontal) 0.5 else 0)
    ),
    ...
  )
}

# Shared skeleton --------------------------------------------------------------

# The type scale, stated once, in steps relative to base_size:
#
#   title        base + 6   bold
#   subtitle     base + 1
#   axis title   base
#   axis text    base - 1
#   legend title base - 1   bold
#   caption      base - 2
#   legend text  base - 2
#   strip        base       bold
#
# `base` is the ggplot2 theme to build on — theme_minimal() for charts, which
# keeps axes and grid, theme_void() for maps, which starts from nothing.
ps_theme_base <- function(base_size, base_family, ink, base) {

  base(base_size = base_size, base_family = base_family) +
    ggplot2::theme(

      # Canvas
      plot.background   = ggplot2::element_rect(fill = ink[["canvas"]], colour = NA),
      panel.background  = ggplot2::element_rect(fill = ink[["panel"]],  colour = NA),
      legend.background = ggplot2::element_blank(),
      legend.key        = ggplot2::element_blank(),

      # Type
      text = ggplot2::element_text(family = base_family, colour = ink[["body"]]),

      plot.title = ggplot2::element_text(size   = base_size + 6,
                                         face   = "bold",
                                         colour = ink[["title"]],
                                         hjust  = 0,
                                         margin = ggplot2::margin(b = 4)),

      plot.subtitle = ggplot2::element_text(size   = base_size + 1,
                                            colour = ink[["muted"]],
                                            hjust  = 0,
                                            margin = ggplot2::margin(b = 14)),

      plot.caption = ggplot2::element_text(size   = base_size - 2,
                                           colour = ink[["muted"]],
                                           hjust  = 1,
                                           margin = ggplot2::margin(t = 12)),

      # Axes. No ticks and no axis line anywhere: the grid or the graticule
      # already carries the reader, and the extra rules only add clutter.
      axis.text  = ggplot2::element_text(size = base_size - 1, colour = ink[["body"]]),
      axis.title = ggplot2::element_text(size = base_size,     colour = ink[["body"]]),
      axis.ticks = ggplot2::element_blank(),
      axis.line  = ggplot2::element_blank(),

      # Legend
      legend.position       = "bottom",
      legend.title          = ggplot2::element_text(size   = base_size - 1,
                                                    face   = "bold",
                                                    colour = ink[["title"]]),
      legend.text           = ggplot2::element_text(size   = base_size - 2,
                                                    colour = ink[["muted"]]),
      legend.title.position = "top",
      legend.key.size       = grid::unit(4, "mm"),
      legend.box.spacing    = grid::unit(5, "mm"),

      # Facets
      strip.text = ggplot2::element_text(size   = base_size,
                                         face   = "bold",
                                         colour = ink[["title"]],
                                         margin = ggplot2::margin(4, 4, 6, 4)),

      # Frame. Titles and caption align to the whole plot, not the panel, so a
      # long y-axis label cannot push the title out of alignment with its figure.
      panel.grid.minor      = ggplot2::element_blank(),
      plot.title.position   = "plot",
      plot.caption.position = "plot",
      plot.margin           = ggplot2::margin(14, 18, 12, 14)
    )
}
