# map_uvs_sites.R --------------------------------------------------------------
# The report map of underwater visual survey sites: a region or subregion on
# satellite imagery, a reference map or a clean coastline, each marker shaped
# by habitat and filled by exposure, on theme_ps_map() with a compass rose, a
# scale bar and a locator globe kept quiet enough not to compete with the
# geography.
#
# The interactive counterpart, for reviewing a survey at sea, is
# explore_uvs_sites(). This one is for the page.
#
# Public API:
#   - map_uvs_sites()
#
# Internal, in the order the map is built:
#   uvs_map_selection()   which sites
#   uvs_map_encode()      shape, fill and outline per site
#   frame_from_sites(), frame_from_extent(), frame_to_degrees(), axis_breaks()
#   export_height(), export_map()
#   place_globe(), place_rose()   the corners the insets take
#   basemap_source(), basemap_layer(), tile_zoom(), global_islands()
#   site_labels(), uvs_site_number()
#   locator_globe(), disc_points(), north_rose()

#' Map underwater visual survey sites
#'
#' @description
#' Draws the standard Pristine Seas site map for a report: the sites of a
#' region or subregion on satellite imagery, a reference map or a clean drawn
#' coastline, each marker taking its shape from the habitat ([ps_shapes()]) and
#' its fill from the exposure ([ps_colors()]), set on [theme_ps_map()] with a
#' compass rose, a scale bar and a locator globe kept quiet enough not to
#' compete with the geography. One call, one design, every expedition.
#'
#' The frame is fitted to the sites chosen: their bounding box, padded by a
#' fraction of its larger side, and never narrower than `min_span` kilometres
#' so a tight cluster of sites still shows the reef around it. To adjust it,
#' widen or tighten `expand`, or set the frame outright with `extent`. Tiles
#' are fetched at the zoom that gives the frame's longer side about 2000
#' pixels, enough for a full-page figure, and cached for the session, so
#' redrawing a map is quick.
#'
#' @section Basemaps:
#' Four to choose from, and the right one differs map by map:
#'
#' * `"esri"`, the default: Esri World Imagery. Needs no account. A consistent
#'   mosaic wherever Esri had a clear pass.
#' * `"mapbox"`: Mapbox Satellite. Often a fresher, sharper Maxar scene where
#'   Esri has cloud, and needs an access token. Rather than pass it to every
#'   call, keep it in `.Renviron` as `MAPBOX_TOKEN` and it is picked up from
#'   there: `usethis::edit_r_environ()`, then a line `MAPBOX_TOKEN=pk.xxxx`.
#' * `"coast"`: no imagery at all. Land from the USGS, Esri and WCMC Global
#'   Islands database, Landsat-derived polygons for every island on Earth,
#'   drawn in the theme's land ink on its water, with the graticule showing.
#'   The quiet option when the imagery is cloudy or the sites are the point.
#'   Polygons are fetched from UNEP-WCMC's map service for the frame drawn, so
#'   nothing needs to be on disk.
#' * `"natgeo"`: the National Geographic World Map, Esri's reference map in
#'   the Society's cartographic style, with shaded relief, bathymetry and
#'   place names. Light-toned, so the marks flip to dark ink on it. Made for
#'   the regional view: a whole region or expedition, where the names matter
#'   and a single island's reef would be too small to see. Its content is
#'   only whole to zoom 9 over the open ocean, so the automatic zoom stops
#'   there and a frame under about 200 km draws soft. Where a deeper level
#'   turns out to have content, ask for it with `zoom`.
#'
#' The caption credits whichever source drew the map, as each provider's terms
#' ask.
#'
#' @section What it needs:
#' The annotations come from **ggspatial**, and tiled basemaps from
#' **maptiles** and **tidyterra**, none of which install with this package;
#' **ggrepel** is added when `label_sites = TRUE` and **rnaturalearth** with
#' **rnaturalearthdata** when `locator = TRUE`. The first call offers to
#' install whichever is missing. Every basemap is fetched live, so an internet
#' connection is needed.
#'
#' @section Building on it:
#' The return value is an ordinary ggplot, so anything the map lacks can be
#' added the usual way: a `labs()` to change the wording, a `geom_sf()` for an
#' MPA boundary. Take colours for those layers from [ps_ink()] so they sit in
#' the same key as the canvas.
#'
#' @param sites A site-level data frame, one row per site, such as the
#'   validated UVS sites table. Must include `ps_site_id`, `longitude`,
#'   `latitude`, `region`, `subregion`, `habitat` and `exposure`. Habitat and
#'   exposure must follow the vocabulary in [allowed_vocab]; a missing exposure
#'   is drawn as `"unknown"`.
#' @param region,subregion Character. Which sites to draw. Either may name one
#'   or several values; `subregion` is matched within `region` when both are
#'   given. `NULL` (the default) places no restriction, so with neither set the
#'   whole table is drawn. A name that matches no site is an error that lists
#'   the names available.
#' @param expand Numeric. Margin around the sites, as a fraction of the larger
#'   side of their bounding box, added on every side. Default 0.25. Raise it
#'   to show more sea around the sites, lower it to tighten the frame.
#' @param min_span Numeric. The narrowest the map may be, in kilometres, on
#'   either axis. Default 3.
#' @param extent The frame, set outright: `c(xmin, ymin, xmax, ymax)` in
#'   degrees of longitude and latitude, or an `sf` bbox in any projection.
#'   Overrides `expand` and `min_span`. `NULL` (the default) fits the frame
#'   to the sites. Every map carries the frame it drew as
#'   `attr(p, "extent")`, in degrees, so the usual way to nudge one is to
#'   start from that and move an edge.
#' @param basemap What the sites are drawn on: `"esri"` (World Imagery, the
#'   default), `"mapbox"` (Satellite, needs a token), `"coast"` (Global
#'   Islands coastline, no imagery) or `"natgeo"` (the National Geographic
#'   World Map, for regional views). See the Basemaps section.
#' @param mapbox_token Character. A Mapbox access token, used only when
#'   `basemap = "mapbox"`. Defaults to the `MAPBOX_TOKEN` environment variable.
#' @param zoom Integer. Tile zoom level for the tiled basemaps. `NULL` (the
#'   default) picks the level that gives the frame's longer side about 2000
#'   pixels, within what each provider reliably serves; one level up doubles
#'   that, and quadruples the fetch. A value given here is honoured up to the
#'   provider's hard limit. Ignored by `basemap = "coast"`.
#' @param label_sites Logical. Label each marker with its site number, the
#'   digits that end `ps_site_id` (so `RMI_2023_uvs_007` reads `7`), placed by
#'   **ggrepel** so labels never sit on a marker, on each other or on the
#'   globe. An id with no trailing digits is shown whole. Default `FALSE`.
#' @param locator Logical. Inset a small globe, the hemisphere centred on the
#'   map with a rectangle outlining the frame, so a reader who does not know
#'   the archipelago can place it. It takes the top right corner unless a site
#'   sits there, then the top left, then the bottom right; the compass rose
#'   takes the next free corner. Land comes from Natural Earth through
#'   **rnaturalearth**. Default `TRUE`.
#' @param title,subtitle,caption Character. The title block. The subtitle
#'   defaults to the place drawn and its site count; the caption to the credit
#'   for the basemap drawn, which each provider's terms ask for.
#' @param base_size Numeric. Base font size in points, passed to
#'   [theme_ps_map()]. Default 12.
#' @param export Character. A file path to save the map to as well as
#'   returning it, typically a `.pdf` for the report; any extension
#'   `ggplot2::ggsave()` knows is accepted. A PDF is vector for everything but
#'   the imagery, which is embedded at its fetched resolution; the house
#'   typeface is embedded where R can draw through Cairo and set in Helvetica
#'   otherwise. `NULL` (the default) saves nothing.
#' @param width,height Numeric. Size of the exported figure in inches.
#'   `width` defaults to 8; `height` to `NULL`, which sets it from the frame's
#'   own proportions so the map is neither stretched nor padded.
#'
#' @return A ggplot object, with the frame it drew as `attr(p, "extent")`.
#'   Print it, or save it with `ggsave()`; the theme carries its own canvas,
#'   so no `bg` is needed. When `export` is given the file is written first
#'   and the map returned invisibly.
#'
#' @seealso [explore_uvs_sites()] for the interactive map, [theme_ps_map()] for
#'   the canvas, [ps_shapes()] and [ps_colors()] for the marker encoding.
#'
#' @examples
#' \dontrun{
#' map_uvs_sites(rmi_2023_uvs_sites, region = "Bikar")
#'
#' # Straight to the report
#' map_uvs_sites(rmi_2023_uvs_sites, region = "Bikar", export = "figures/bikar_sites.pdf")
#' }
#'
#' @importFrom rlang .data
#' @export
map_uvs_sites <- function(sites,
                          region       = NULL,
                          subregion    = NULL,
                          expand       = 0.25,
                          min_span     = 3,
                          extent       = NULL,
                          basemap      = c("esri", "mapbox", "coast", "natgeo"),
                          mapbox_token = Sys.getenv("MAPBOX_TOKEN"),
                          zoom         = NULL,
                          label_sites  = FALSE,
                          locator      = TRUE,
                          title        = "Underwater visual survey sites",
                          subtitle     = NULL,
                          caption      = NULL,
                          base_size    = 12,
                          export       = NULL,
                          width        = 8,
                          height       = NULL) {

  basemap <- match.arg(basemap)
  if (!is.numeric(expand) || length(expand) != 1L || expand < 0) {
    stop("`expand` must be a single number, 0 or more.", call. = FALSE)
  }
  if (!is.numeric(min_span) || length(min_span) != 1L || min_span <= 0) {
    stop("`min_span` must be a single number of kilometres, above 0.", call. = FALSE)
  }
  uvs_map_dependencies(basemap, label_sites, locator)
  source <- basemap_source(basemap, mapbox_token)

  # Every mark drawn over the basemap, outlines, labels, rose and scale bar,
  # is in a light ink on the dark basemaps and a dark one on the light
  # National Geographic map, or it would disappear.
  ink <- ps_ink("map")
  pen <- if (source$light) {
    list(fg = ink[["canvas"]], halo = ink[["title"]], note = ps_ink("chart")[["body"]])
  } else {
    list(fg = ink[["title"]], halo = ink[["canvas"]], note = ink[["body"]])
  }

  # ---- Sites and frame ------------------------------------------------------
  sel <- uvs_map_selection(sites, region, subregion)
  pts <- uvs_map_encode(sel, outline = pen$fg)

  # Web Mercator throughout, the projection tiles arrive in, so imagery is
  # never resampled.
  lim <- if (is.null(extent)) {
    frame_from_sites(pts, expand = expand, min_span = min_span)
  } else {
    frame_from_extent(extent)
  }

  pts_3857 <- sf::st_transform(pts, 3857)
  globe_at <- if (isTRUE(locator)) place_globe(lim, pts_3857)
  rose_at  <- place_rose(lim, pts_3857, taken = globe_at$corner)

  # ---- Layers ---------------------------------------------------------------
  ground <- basemap_layer(source, lim, zoom, ink)

  markers <- ggplot2::geom_sf(data = pts,
                              ggplot2::aes(shape  = .data$habitat,
                                           fill   = .data$exposure,
                                           colour = .data$outline),
                              size = 3.2, stroke = 0.6)

  labels <- if (isTRUE(label_sites)) site_labels(pts, globe_at, pen, base_size)

  globe <- if (isTRUE(locator)) {
    ggplot2::annotation_custom(
      ggplot2::ggplotGrob(locator_globe(lim, ink, edge = pen$fg)),
      xmin = globe_at$x - globe_at$r, xmax = globe_at$x + globe_at$r,
      ymin = globe_at$y - globe_at$r, ymax = globe_at$y + globe_at$r
    )
  }

  rose <- ggspatial::annotation_north_arrow(
    location = rose_at,
    height   = grid::unit(0.9, "cm"),
    width    = grid::unit(0.9, "cm"),
    pad_x    = grid::unit(0.5, "cm"),
    pad_y    = grid::unit(0.5, "cm"),
    style    = north_rose(pen$note)
  )

  scale_bar <- ggspatial::annotation_scale(
    location    = "bl",
    style       = "ticks",
    line_col    = pen$note,
    text_col    = pen$note,
    text_family = ps_font_default(),
    text_cex    = 0.65,
    line_width  = 0.5,
    height      = grid::unit(0.15, "cm"),
    pad_x       = grid::unit(0.5, "cm"),
    pad_y       = grid::unit(0.5, "cm")
  )

  # ---- Map ------------------------------------------------------------------
  if (is.null(subtitle)) subtitle <- uvs_map_subtitle(sel, region, subregion)
  if (is.null(caption))  caption  <- source$credit

  unsnake <- function(x) gsub("_", " ", x)
  deg     <- frame_to_degrees(lim)

  p <- ggplot2::ggplot() +
    ground +
    markers +
    labels +
    globe +
    rose +
    scale_bar +
    scale_shape_ps("habitat",  drop = TRUE, labels = unsnake, name = "Habitat") +
    scale_fill_ps("exposure",  drop = TRUE, labels = unsnake, name = "Exposure") +
    ggplot2::scale_colour_identity(guide = "none") +
    ggplot2::guides(
      shape = ggplot2::guide_legend(order = 1, override.aes = list(fill   = ink[["muted"]],
                                                                  colour = ink[["title"]])),
      fill  = ggplot2::guide_legend(order = 2, override.aes = list(shape  = 21,
                                                                  colour = ink[["title"]]))
    ) +
    # Graticule labels on a round step never finer than a hundredth of a
    # degree, at most six to an axis; the axis still drops any that would
    # collide on a very narrow frame.
    ggplot2::scale_x_continuous(breaks = axis_breaks(deg[["xmin"]], deg[["xmax"]]),
                                guide  = ggplot2::guide_axis(check.overlap = TRUE)) +
    ggplot2::scale_y_continuous(breaks = axis_breaks(deg[["ymin"]], deg[["ymax"]]),
                                guide  = ggplot2::guide_axis(check.overlap = TRUE)) +
    ggplot2::coord_sf(xlim = lim[c("xmin", "xmax")], ylim = lim[c("ymin", "ymax")],
                      expand = FALSE, crs = 3857) +
    ggplot2::labs(title = title, subtitle = subtitle, caption = caption) +
    theme_ps_map(base_size = base_size) +
    # The two keys stack, flush with the panel's left edge: a tall map is
    # narrow, and one centred row of thirteen entries would run past its
    # edges.
    ggplot2::theme(legend.box           = "vertical",
                   legend.box.just      = "left",
                   legend.justification = "left",
                   legend.location      = "panel",
                   legend.spacing.y     = grid::unit(2, "mm"))

  attr(p, "extent") <- deg

  if (is.null(export)) return(p)

  if (is.null(height)) height <- export_height(lim, width)
  export_map(p, export, width, height)
  invisible(p)
}


# Sites ------------------------------------------------------------------------

uvs_map_dependencies <- function(basemap, label_sites, locator) {
  rlang::check_installed("ggspatial", reason = "to draw the compass rose and scale bar.")
  if (basemap != "coast") {
    rlang::check_installed(c("maptiles", "tidyterra"), reason = "to draw tiled basemaps.")
  }
  if (isTRUE(label_sites)) {
    rlang::check_installed("ggrepel", reason = "to label sites on the map.")
  }
  if (isTRUE(locator)) {
    rlang::check_installed(c("rnaturalearth", "rnaturalearthdata"),
                           reason = "to draw the locator globe.")
  }
}

# The sites to draw: `region` first, then `subregion` within it, each name
# checked against what is actually there so a typo reads as a typo.
uvs_map_selection <- function(sites, region = NULL, subregion = NULL) {

  required <- c("ps_site_id", "longitude", "latitude",
                "region", "subregion", "habitat", "exposure")
  missing  <- setdiff(required, names(sites))
  if (length(missing)) {
    stop("`sites` is missing required column(s): ",
         paste(missing, collapse = ", "), call. = FALSE)
  }

  keep <- function(d, column, values) {
    if (is.null(values)) return(d)
    have    <- unique(as.character(d[[column]]))
    unknown <- setdiff(values, have)
    if (length(unknown)) {
      stop("No sites in ", column, " ", paste(sQuote(unknown, FALSE), collapse = ", "),
           ". Available: ", paste(sort(have), collapse = ", "), ".", call. = FALSE)
    }
    d[as.character(d[[column]]) %in% values, , drop = FALSE]
  }

  sel <- as.data.frame(sites)
  sel <- keep(sel, "region",    region)
  sel <- keep(sel, "subregion", subregion)

  ok <- is.finite(sel$longitude) & is.finite(sel$latitude)
  if (!all(ok)) {
    warning(sum(!ok), " site(s) without coordinates were left off the map: ",
            paste(sel$ps_site_id[!ok], collapse = ", "), call. = FALSE)
    sel <- sel[ok, , drop = FALSE]
  }
  if (nrow(sel) == 0L) stop("No sites to draw.", call. = FALSE)

  sel
}

# The marker encoding, as an sf of points: exposure fills the marker and
# habitat sets its shape. Open shapes have no interior, so for those the
# exposure colour moves to the outline; filled shapes take `outline`, a light
# ink that lifts them off the imagery.
uvs_map_encode <- function(sel, outline) {

  shapes <- ps_shapes("habitat")
  fills  <- ps_colors("exposure")

  sel$habitat  <- as.character(sel$habitat)
  sel$exposure <- ifelse(is.na(sel$exposure), "unknown", as.character(sel$exposure))

  bad <- list(habitat  = setdiff(unique(sel$habitat),  names(shapes)),
              exposure = setdiff(unique(sel$exposure), names(fills)))
  bad <- bad[lengths(bad) > 0]
  if (length(bad)) {
    stop("`sites` uses values outside the vocabulary\n",
         paste0("  ", names(bad), ": ", vapply(bad, paste, "", collapse = ", "), collapse = "\n"),
         "\nSee `allowed_vocab` and `validate_vocab()`.", call. = FALSE)
  }

  sel$outline <- unname(ifelse(shapes[sel$habitat] >= 21L, outline, fills[sel$exposure]))

  sf::st_as_sf(sel, coords = c("longitude", "latitude"), crs = 4326, remove = FALSE)
}

# "Bikar . 15 sites": the place drawn, then the count.
uvs_map_subtitle <- function(sel, region, subregion) {
  place <- if (!is.null(subregion)) {
    regions <- unique(sel$region)
    paste(c(paste(subregion, collapse = ", "), if (length(regions) == 1L) regions),
          collapse = ", ")
  } else if (!is.null(region)) {
    paste(region, collapse = ", ")
  } else {
    paste(sort(unique(sel$region)), collapse = ", ")
  }
  paste0(place, " \u00b7 ", nrow(sel), " sites")
}

# The number that ends a site id, without its leading zeros: RMI_2023_uvs_007
# becomes 7. An id that does not end in digits is returned whole.
uvs_site_number <- function(id) {
  id  <- as.character(id)
  has <- grepl("[0-9]+$", id)
  id[has] <- as.character(as.integer(regmatches(id, regexpr("[0-9]+$", id))))
  id
}


# Frame ------------------------------------------------------------------------
# A frame is c(xmin, ymin, xmax, ymax) in Web Mercator metres.

# The frame fitted to the sites: their bounding box, padded on every side by
# `expand` of its larger dimension, then widened where needed so that neither
# side falls under `min_span` kilometres of ground. Mercator metres stretch by
# 1/cos(latitude), so the minimum is converted before it is compared.
frame_from_sites <- function(pts, expand = 0.25, min_span = 3) {

  lon <- sf::st_coordinates(pts)[, 1]
  if (max(lon) - min(lon) > 180) {
    stop("The sites straddle the antimeridian, which one Web Mercator frame cannot ",
         "cross. Draw each side with its own `region` or `subregion`.", call. = FALSE)
  }

  bb <- sf::st_bbox(sf::st_transform(pts, 3857))
  w  <- bb[["xmax"]] - bb[["xmin"]]
  h  <- bb[["ymax"]] - bb[["ymin"]]

  lat   <- mean(sf::st_coordinates(pts)[, 2])
  min_m <- min_span * 1000 / cos(lat * pi / 180)

  pad   <- max(w, h) * expand
  pad_x <- max(pad, (min_m - w) / 2)
  pad_y <- max(pad, (min_m - h) / 2)

  c(xmin = bb[["xmin"]] - pad_x, ymin = bb[["ymin"]] - pad_y,
    xmax = bb[["xmax"]] + pad_x, ymax = bb[["ymax"]] + pad_y)
}

# The frame a caller asked for: c(xmin, ymin, xmax, ymax) in degrees, or an
# sf bbox in any projection.
frame_from_extent <- function(extent) {

  if (inherits(extent, "bbox")) {
    if (is.na(sf::st_crs(extent))) sf::st_crs(extent) <- 4326
    box <- sf::st_as_sfc(extent)
  } else if (is.numeric(extent) && length(extent) == 4L) {
    sides <- c("xmin", "ymin", "xmax", "ymax")
    # a named vector is read by name, whatever its order; a bare one in order
    if (all(sides %in% names(extent))) extent <- extent[sides] else names(extent) <- sides
    if (extent[["xmin"]] >= extent[["xmax"]] || extent[["ymin"]] >= extent[["ymax"]]) {
      stop("`extent` must be c(xmin, ymin, xmax, ymax) with xmin < xmax and ymin < ymax.",
           call. = FALSE)
    }
    box <- sf::st_as_sfc(sf::st_bbox(extent, crs = sf::st_crs(4326)))
  } else {
    stop("`extent` must be c(xmin, ymin, xmax, ymax) in degrees, or an sf bbox.",
         call. = FALSE)
  }

  bb <- sf::st_bbox(sf::st_transform(box, 3857))
  c(xmin = bb[["xmin"]], ymin = bb[["ymin"]], xmax = bb[["xmax"]], ymax = bb[["ymax"]])
}

# A frame back in degrees, rounded to what a caller would type.
frame_to_degrees <- function(lim) {
  bb <- sf::st_bbox(sf::st_transform(frame_as_sfc(lim), 4326))
  round(c(xmin = bb[["xmin"]], ymin = bb[["ymin"]], xmax = bb[["xmax"]], ymax = bb[["ymax"]]), 4)
}

frame_as_sfc <- function(lim) {
  sf::st_as_sfc(sf::st_bbox(lim, crs = sf::st_crs(3857)))
}

frame_short_side <- function(lim) {
  min(lim[["xmax"]] - lim[["xmin"]], lim[["ymax"]] - lim[["ymin"]])
}

# Graticule breaks for one axis, in degrees: multiples of the finest step
# from a round ladder that fits at most `n` labels on the axis, and never
# finer than `min_step`, so a tight frame reads 167.64, 167.65 rather than
# 167.645.
axis_breaks <- function(lo, hi, n = 6, min_step = 0.01) {
  ladder <- c(0.01, 0.02, 0.05, 0.1, 0.2, 0.5, 1, 2, 5, 10, 20, 30)
  ladder <- ladder[ladder >= min_step]
  step   <- ladder[which((hi - lo) / ladder <= n)[1]]
  if (is.na(step)) step <- ladder[length(ladder)]
  round(seq(ceiling(lo / step) * step, floor(hi / step) * step, by = step), 6)
}


# Export -----------------------------------------------------------------------

# A figure height that fits the frame: the panel keeps the frame's proportions
# inside the width left after the axis labels, and the title block, axis text,
# the two stacked legends and the caption add a fixed band below and above.
export_height <- function(lim, width, side = 1.1, band = 2.6) {
  aspect <- (lim[["ymax"]] - lim[["ymin"]]) / (lim[["xmax"]] - lim[["xmin"]])
  (width - side) * aspect + band
}

# Writes the map. A PDF is tried through Cairo first, which embeds the house
# typeface; where Cairo is unavailable at run time (a Mac without XQuartz, for
# one) it falls back to R's own device, on which ps_font_default() has already
# aliased the typeface onto Helvetica. Anything else is left to ggsave() to
# pick from the extension.
export_map <- function(p, path, width, height) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  save <- function(device) {
    ggplot2::ggsave(path, p, device = device, width = width, height = height,
                    units = "in", dpi = 300)
  }
  if (tolower(tools::file_ext(path)) == "pdf") {
    # A Cairo device that cannot load warns and then writes nothing, without
    # an error, so success is judged by the file rather than by the call.
    written <- tryCatch({
      suppressWarnings(save(grDevices::cairo_pdf))
      file.exists(path) && file.size(path) > 0
    }, error = function(e) FALSE)
    if (!written) {
      if (file.exists(path)) unlink(path)
      save(grDevices::pdf)
    }
  } else {
    save(NULL)
  }
  invisible(path)
}


# Corners ----------------------------------------------------------------------
# The globe and the rose each take a corner of the frame, and neither may sit
# on a site. Corners are offered top right, top left, bottom right, in that
# order; the bottom left is the scale bar's and is never offered.

# The centres of a disc of radius r set `gap` in from each corner.
frame_corners <- function(lim, r, gap) {
  list(
    tr = c(x = lim[["xmax"]] - gap - r, y = lim[["ymax"]] - gap - r),
    tl = c(x = lim[["xmin"]] + gap + r, y = lim[["ymax"]] - gap - r),
    br = c(x = lim[["xmax"]] - gap - r, y = lim[["ymin"]] + gap + r)
  )
}

# The first corner with no site within the disc plus a marker's worth of
# margin, skipping any in `taken`; failing that, the one with fewest sites.
free_corner <- function(corners, pts_3857, r, taken = NULL) {
  corners <- corners[setdiff(names(corners), taken)]
  xy <- sf::st_coordinates(pts_3857)
  under <- vapply(corners, function(c) {
    sum((xy[, 1] - c[["x"]])^2 + (xy[, 2] - c[["y"]])^2 <= (1.3 * r)^2)
  }, numeric(1))
  pick <- names(corners)[which(under == 0)[1]]
  if (is.na(pick)) pick <- names(corners)[which.min(under)]
  pick
}

# Where the locator globe goes, as list(x, y, r, corner): a disc a fifth of
# the frame's shorter side across, in the first free corner.
place_globe <- function(lim, pts_3857) {
  short   <- frame_short_side(lim)
  r       <- 0.1 * short
  corners <- frame_corners(lim, r, gap = 0.03 * short)
  corner  <- free_corner(corners, pts_3857, r)
  list(x = corners[[corner]][["x"]], y = corners[[corner]][["y"]], r = r, corner = corner)
}

# Where the compass rose goes, as a ggspatial location: the first free corner
# the globe did not take. Its footprint is taken as a disc of a sixteenth of
# the shorter side, about what 0.9 cm comes to on a full-page map.
place_rose <- function(lim, pts_3857, taken = NULL) {
  short <- frame_short_side(lim)
  r     <- 0.06 * short
  free_corner(frame_corners(lim, r, gap = 0.03 * short), pts_3857, r, taken = taken)
}


# Basemap ----------------------------------------------------------------------

# What a basemap needs: the maptiles provider, the deepest zoom it serves and
# the deepest the automatic choice may use, whether it is light-toned, and the
# credit its terms ask for.
basemap_source <- function(basemap, mapbox_token = "") {

  if (basemap == "mapbox" && !nzchar(mapbox_token)) {
    stop("Mapbox imagery needs an access token. Pass `mapbox_token`, or add\n",
         "  MAPBOX_TOKEN=<your token>\n",
         "to .Renviron (`usethis::edit_r_environ()`) and restart R.", call. = FALSE)
  }

  switch(basemap,
    esri   = list(provider = "Esri.WorldImagery", max_zoom = 19L, auto_max = 19L, light = FALSE,
                  credit   = "Imagery: Esri World Imagery"),
    mapbox = list(provider = list(src = "Mapbox", sub = NA, cit = "Mapbox, Maxar",
                                  q   = paste0("https://api.mapbox.com/v4/mapbox.satellite/",
                                               "{z}/{x}/{y}.jpg90?access_token=", mapbox_token)),
                  max_zoom = 22L, auto_max = 22L, light = FALSE,
                  credit   = "Imagery: Mapbox Satellite \u00a9 Mapbox \u00a9 Maxar"),
    # Served to zoom 16, but over the open ocean the content is patchy past
    # zoom 9: some tiles at 10 carry bathymetry and names, their neighbours
    # are flat blue, and past 12 they are a "map data not yet available"
    # placeholder. The automatic choice stops at 9, the deepest level that is
    # whole everywhere; a caller who has looked can ask for more.
    natgeo = list(provider = "Esri.NatGeoWorldMap", max_zoom = 16L, auto_max = 9L, light = TRUE,
                  credit   = "Basemap: National Geographic World Map, Esri"),
    coast  = list(provider = NULL, max_zoom = NA, auto_max = NA, light = FALSE,
                  credit   = "Coastline: USGS, Esri and WCMC Global Islands")
  )
}

# The ground layer for a frame: Global Islands land in the theme's land ink,
# or the provider's tiles. Either is fetched with a small margin beyond the
# frame so it fills it to the edge.
basemap_layer <- function(source, lim, zoom, ink) {

  margin <- 0.02 * max(lim[["xmax"]] - lim[["xmin"]], lim[["ymax"]] - lim[["ymin"]])
  fetch  <- frame_as_sfc(lim + c(-1, -1, 1, 1) * margin)

  if (is.null(source$provider)) {
    return(ggplot2::geom_sf(data = global_islands(fetch),
                            fill = ink[["land"]], colour = ink[["coast"]], linewidth = 0.25))
  }

  zoom <- if (is.null(zoom)) {
    min(tile_zoom(lim), source$auto_max)
  } else {
    min(as.integer(zoom), source$max_zoom)
  }

  # terra reports progress on the merge of the tiles; a report figure is not
  # the place for a progress bar.
  progress <- terra::terraOptions(print = FALSE)$progress
  terra::terraOptions(progress = 0)
  on.exit(terra::terraOptions(progress = progress), add = TRUE)

  tiles <- maptiles::get_tiles(fetch, provider = source$provider, zoom = zoom,
                               crop = TRUE, verbose = FALSE)
  tidyterra::geom_spatraster_rgb(data = tiles, maxcell = 1e7)
}

# The tile zoom at which a frame's longer side is nearest `px` pixels. A
# zoom-z tile covers 40075016.686 / 2^z metres of Mercator width in 256
# pixels. Sized on the longer side so a tall, narrow frame is not fetched at a
# zoom chosen for its width alone, which quadruples the tiles for nothing.
tile_zoom <- function(lim, px = 2000) {
  side <- max(lim[["xmax"]] - lim[["xmin"]], lim[["ymax"]] - lim[["ymin"]])
  as.integer(round(log2(px * 40075016.686 / (side * 256))))
}

# Land within an area, from the USGS, Esri and WCMC Global Islands database
# (v3): the Landsat-derived polygons of every island on Earth, plus the
# continents, served by UNEP-WCMC as an ArcGIS map service. Each of the four
# layers is queried for the area and the pieces stacked; the service hands
# back at most a thousand features per call, so a crowded area is paged.
# Returned in WGS84; coord_sf projects it onto whatever the map is drawn in.
global_islands_service <-
  "https://data-gis.unep-wcmc.org/server/rest/services/Global_Islands/MapServer"

global_islands <- function(area) {

  bb <- sf::st_bbox(sf::st_transform(area, 4326))

  query <- function(layer, offset) {
    paste0(global_islands_service, "/", layer, "/query?where=1%3D1",
           "&geometry=", paste(sprintf("%.6f", bb[c("xmin", "ymin", "xmax", "ymax")]), collapse = ","),
           "&geometryType=esriGeometryEnvelope&inSR=4326&outSR=4326",
           "&spatialRel=esriSpatialRelIntersects&outFields=OBJECTID",
           "&resultOffset=", offset, "&f=geojson")
  }

  page   <- 1000L
  pieces <- list()

  for (layer in 0:3) {              # very small, small, big islands; continents
    offset <- 0L
    repeat {
      got <- tryCatch(sf::read_sf(query(layer, offset), quiet = TRUE),
                      error = function(e) {
                        stop("Could not fetch the Global Islands coastline from ",
                             global_islands_service, "\n", conditionMessage(e), call. = FALSE)
                      })
      if (nrow(got)) pieces[[length(pieces) + 1L]] <- sf::st_geometry(got)
      if (nrow(got) < page) break
      offset <- offset + page
    }
  }

  if (!length(pieces)) return(sf::st_sf(geometry = sf::st_sfc(crs = 4326)))
  sf::st_sf(geometry = do.call(c, pieces))
}


# Labels -----------------------------------------------------------------------

# Site numbers in the foreground ink with a thin halo, so they read on cloud
# and on reef alike, and a hairline leader only where the label had to move
# away from its marker. ggrepel keeps labels off every point in its layer,
# labelled or not, so the globe's disc is seeded with a grid of unlabelled
# points and no number can land on it.
site_labels <- function(pts, globe_at, pen, base_size) {

  marks <- sf::st_sf(label = uvs_site_number(pts$ps_site_id), geometry = sf::st_geometry(pts))
  if (!is.null(globe_at)) {
    marks <- rbind(marks, sf::st_sf(label = "", geometry = disc_points(globe_at)))
  }

  ggrepel::geom_text_repel(
    data = marks,
    ggplot2::aes(label = .data$label, geometry = .data$geometry),
    stat               = "sf_coordinates",
    colour             = pen$fg,
    family             = ps_font_default(),
    size               = (base_size - 3) / ggplot2::.pt,
    bg.colour          = pen$halo,
    bg.r               = 0.12,
    point.padding      = grid::unit(0.25, "lines"),
    box.padding        = grid::unit(0.35, "lines"),
    min.segment.length = grid::unit(0.5, "lines"),
    segment.colour     = pen$note,
    segment.size       = 0.3,
    max.overlaps       = Inf,
    seed               = 1
  )
}

# A grid of points filling the globe's disc, returned in WGS84 to sit beside
# the sites. Spaced at a quarter radius, closer than any label is wide, so
# labels find no gap between them.
disc_points <- function(globe_at) {
  step <- globe_at$r / 4
  g <- expand.grid(x = seq(globe_at$x - globe_at$r, globe_at$x + globe_at$r, by = step),
                   y = seq(globe_at$y - globe_at$r, globe_at$y + globe_at$r, by = step))
  g <- g[(g$x - globe_at$x)^2 + (g$y - globe_at$y)^2 <= globe_at$r^2, ]
  sf::st_geometry(sf::st_transform(sf::st_as_sf(g, coords = c("x", "y"), crs = 3857), 4326))
}


# Insets -----------------------------------------------------------------------

# The locator globe: the hemisphere centred on the frame in an orthographic
# projection, Natural Earth land in the map's land ink on its water, a faint
# graticule, and a rectangle outlining the frame. A bare ggplot with no canvas
# of its own, to be inset with annotation_custom().
#
# Land is clipped to a cap a little inside the horizon before projecting;
# geometry on or beyond the horizon does not survive the projection. A frame a
# few tens of kilometres across is under a pixel on a globe, so the rectangle
# keeps the frame's proportions but its longer side is never drawn shorter
# than `min_side` metres, enough to read as a box.
locator_globe <- function(lim, ink, edge = ink[["title"]], min_side = 1e6) {

  # Clipping to the cap is a spherical operation; sf's planar mode would
  # buffer in degrees and get it wrong, so spherical mode is forced here.
  s2 <- sf::sf_use_s2(TRUE)
  on.exit(sf::sf_use_s2(s2), add = TRUE)

  frame  <- frame_as_sfc(lim)
  centre <- sf::st_transform(sf::st_centroid(frame), 4326)
  lonlat <- sf::st_coordinates(centre)[1, ]

  ortho <- sf::st_crs(sprintf("+proj=ortho +lat_0=%f +lon_0=%f +datum=WGS84 +units=m",
                              lonlat[[2]], lonlat[[1]]))
  cap   <- sf::st_buffer(centre, 6.2e6)

  land <- rnaturalearth::ne_countries(scale = 50, returnclass = "sf")
  land <- sf::st_union(sf::st_make_valid(sf::st_geometry(land)))
  land <- sf::st_transform(sf::st_intersection(land, cap), ortho)

  grat <- sf::st_geometry(sf::st_graticule(lon = seq(-180, 150, 30), lat = seq(-60, 60, 30)))
  grat <- sf::st_transform(sf::st_intersection(grat, cap), ortho)

  disc <- sf::st_buffer(sf::st_sfc(sf::st_point(c(0, 0)), crs = ortho), 6371000)

  box   <- sf::st_bbox(sf::st_transform(frame, ortho))
  w     <- box[["xmax"]] - box[["xmin"]]
  h     <- box[["ymax"]] - box[["ymin"]]
  scale <- max(1, min_side / max(w, h))
  cx    <- mean(box[c("xmin", "xmax")])
  cy    <- mean(box[c("ymin", "ymax")])
  box   <- sf::st_as_sfc(sf::st_bbox(c(xmin = cx - scale * w / 2, xmax = cx + scale * w / 2,
                                       ymin = cy - scale * h / 2, ymax = cy + scale * h / 2),
                                     crs = ortho))

  ggplot2::ggplot() +
    ggplot2::geom_sf(data = disc, fill = ink[["canvas"]], colour = edge, linewidth = 0.3) +
    ggplot2::geom_sf(data = grat, colour = ink[["grid"]], linewidth = 0.2) +
    ggplot2::geom_sf(data = land, fill = ink[["land"]], colour = NA) +
    ggplot2::geom_sf(data = box, fill = NA, linewidth = 0.5,
                     colour = ps_colors("exposure")[["leeward"]]) +
    ggplot2::coord_sf(crs = ortho, datum = NA) +
    ggplot2::theme_void() +
    ggplot2::theme(plot.background  = ggplot2::element_blank(),
                   panel.background = ggplot2::element_blank(),
                   plot.margin      = ggplot2::margin(0, 0, 0, 0))
}

# The house north arrow: an eight-point compass rose in the manner of a chart,
# the four cardinal points split lengthwise, one half solid and one half open,
# over four shorter open intercardinal points, and no letter. Drawn in npc
# within the square ggspatial gives it, so it scales with the size asked for.
north_rose <- function(col) {

  # a point from the centre at bearing `a` (degrees, 0 = north), as its left
  # and right halves: centre, shoulder, tip
  halves <- function(a, len, width) {
    r   <- a * pi / 180
    rot <- function(x, y) c(0.5 + x * cos(r) + y * sin(r), 0.5 - x * sin(r) + y * cos(r))
    list(left  = rbind(rot(0, 0), rot(-width, len * 0.28), rot(0, len)),
         right = rbind(rot(0, 0), rot( width, len * 0.28), rot(0, len)))
  }

  cardinal <- function(a) {
    h <- halves(a, len = 0.46, width = 0.08)
    grid::gList(
      grid::polygonGrob(h$left[, 1],  h$left[, 2],  gp = grid::gpar(fill = col, col = NA)),
      grid::polygonGrob(h$right[, 1], h$right[, 2],
                        gp = grid::gpar(fill = NA, col = col, lwd = 0.7, linejoin = "mitre"))
    )
  }

  intercardinal <- function(a) {
    h <- halves(a, len = 0.3, width = 0.05)
    grid::polygonGrob(c(h$left[, 1], rev(h$right[, 1])), c(h$left[, 2], rev(h$right[, 2])),
                      gp = grid::gpar(fill = NA, col = col, lwd = 0.6, linejoin = "mitre"))
  }

  grid::gTree(children = do.call(grid::gList, c(
    lapply(c(45, 135, 225, 315), intercardinal),
    unlist(lapply(c(0, 90, 180, 270), cardinal), recursive = FALSE)
  )))
}
