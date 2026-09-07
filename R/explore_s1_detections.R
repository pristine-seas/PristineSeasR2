# explore_s1_detections.R ---------------------------------------------------
# Interactive Sentinel-1 detection map, with the radar scene behind each detection
#
# The optical sibling of this file is explore_s2_detections.R, and the machinery
# both stand on is in detection_inspector.R: the crop cache, the base64
# embedding, the inspector overlay, the contact sheet and the title-banner
# export. What lives here is what radar alone knows.
#
#   * Sentinel-1 sees backscatter, not colour. A hull is a bright return against
#     water that is nearly black, so the useful stretches are polarisation bands
#     in dB rather than visible-light composites.
#   * Optical asks whether AIS explains a detection, so its markers are matched
#     against unmatched. Radar over this EEZ is mostly shipping, so the question
#     is what kind of object it is, and markers take the caller's own classes.
#
# Internal helpers (not exported): s1_views, s1_thumb_url().

# Sentinel-1 GRD arrives calibrated to decibels, so these are dB windows rather
# than reflectance. Open water sits near the bottom of the range in both
# polarisations and metal sits far above it, which is what makes a vessel legible
# at all: VV is the workhorse and the default, VH is the second opinion — it is
# weaker everywhere, so a target that survives it is unlikely to be sea clutter.
s1_views <- list(
  vv = list(label = "VV backscatter", bands = "VV", min = -25, max = 0),
  vh = list(label = "VH backscatter", bands = "VH", min = -30, max = -5)
)

# The thumbnail for one detection, centred on it.
#
# GFW files a detection under the ESA product name, which is also Earth Engine's
# `system:index` for the same granule, so the scene is addressed directly rather
# than inferred from a time and a place. The date window and the bounds are a
# fallback for granules the archive files under a different id: they cannot
# return the wrong day's overpass, and taking the first is safe because a point
# this small sits in one swath.
s1_thumb_url <- function(scene_id, lon, lat, buffer_m, px, view) {

  ee    <- rgee::ee
  point <- ee$Geometry$Point(c(lon, lat))
  day   <- as.Date(stringr::str_extract(scene_id, "[0-9]{8}"), "%Y%m%d")

  granule <- ee$ImageCollection("COPERNICUS/S1_GRD")$
    filter(ee$Filter$eq("system:index", scene_id))

  fallback <- ee$ImageCollection("COPERNICUS/S1_GRD")$
    filterDate(format(day), format(day + 1))$
    filterBounds(point)

  hit <- ee$Image(ee$Algorithms$If(granule$size()$gt(0),
                                   granule$first(),
                                   fallback$first()))

  vis <- s1_views[[view]][c("bands", "min", "max")]

  # A granule the archive does not hold returns an empty collection, and the
  # error that follows names a null parameter rather than the scene. One
  # detection without a crop must not cost the whole map.
  tryCatch(
    hit$getThumbURL(c(list(region     = point$buffer(buffer_m)$bounds(),
                           dimensions = as.integer(px),
                           format     = "png"),
                      vis)),
    error = function(e) {
      warning("No Sentinel-1 image for scene ", scene_id, call. = FALSE)
      NA_character_
    }
  )
}

#' Explore Sentinel-1 detections
#'
#' @description
#' An interactive map of radar vessel detections, one marker per detection,
#' each popup opening the Sentinel-1 crop the detection was made from and
#' marked at its exact centre.
#'
#' The optical counterpart is [explore_s2_detections()], and the two share a
#' cache format, an inspector overlay and an export path. Two things differ.
#' Crops are backscatter in decibels rather than a visible-light composite, so
#' the views are polarisations (`"vv"`, `"vh"`). And markers are coloured by a
#' caller-supplied class rather than by whether AIS explained them, because over
#' most water radar sees far more shipping than fishing and the interesting
#' question is which is which.
#'
#' @param detections A data frame, or a path to a CSV, with `detect_id`,
#'   `detect_lat`, `detect_lon` and `scene_id`. Used when present:
#'   `detect_timestamp` (or `when`), `length_m` (or `length_m_inferred`), a
#'   class column, `fishing_score`, `presence_score` and `matching_score`
#'   (GFW's own confidence in the AIS identity behind a match, NA where a
#'   detection has none). With `fishing_score`, the gallery and arrow-key
#'   order runs highest score first, as [explore_s2_detections()] already
#'   orders by `presence_score`; without it, rows are shown in the order they
#'   arrive.
#' @param class_col Name of the column colouring the markers. Defaults to
#'   `"fleet"` when present, then `"class"`; `NULL` draws every marker alike.
#' @param palette Named colours, one per class level. Names must match the
#'   values in `class_col`. Defaults to a grey ramp.
#' @param cache_dir Where crops are cached. Crops already cached need no Earth
#'   Engine credentials, which is what lets a colleague rebuild the map.
#' @param buffer_m Half-width of the crop, in metres. Sentinel-1 GRD is 10 m a
#'   pixel, so 500 m gives a 100-pixel frame.
#' @param view One or more of `names(s1_views)`.
#' @param embed Cache and inline the crops as `data:` URIs. `FALSE` links to
#'   Earth Engine URLs, which expire within days.
#' @param boundary Optional `sf` outline drawn over the map.
#' @param gallery_order Label shown under the contact sheet's count, describing
#'   the order it is actually in: by `fishing_score` when the column is
#'   present, otherwise the order rows arrive in.
#' @param boundary_color,gallery,legend_title,title,subtitle,export_path As in
#'   [explore_s2_detections()].
#' @param ee_project,ee_python,ee_asset_home Earth Engine connection details,
#'   used only when a crop is missing from `cache_dir`.
#'
#' @return A `leaflet` widget.
#' @export
explore_s1_detections <- function(detections,
                                  class_col      = NULL,
                                  palette        = NULL,
                                  cache_dir      = NULL,
                                  buffer_m       = 500,
                                  view           = "vv",
                                  embed          = TRUE,
                                  boundary       = NULL,
                                  boundary_color = "#B6D94C",
                                  gallery        = TRUE,
                                  gallery_order  = "in the order given",
                                  legend_title   = NULL,
                                  title          = NULL,
                                  subtitle       = "National Geographic Pristine Seas",
                                  export_path    = NULL,
                                  ee_project     = NULL,
                                  ee_python      = Sys.getenv("EARTHENGINE_PYTHON"),
                                  ee_asset_home  = NULL) {

  view <- match.arg(view, names(s1_views), several.ok = TRUE)

  if (is.character(detections) && length(detections) == 1) {
    detections <- readr::read_csv(detections, show_col_types = FALSE)
  }

  required_cols <- c("detect_id", "detect_lat", "detect_lon", "scene_id")
  missing_cols  <- setdiff(required_cols, names(detections))
  if (length(missing_cols) > 0) {
    stop("`detections` is missing required column(s): ",
         paste(missing_cols, collapse = ", "), call. = FALSE)
  }
  if (nrow(detections) == 0) stop("`detections` has no rows.", call. = FALSE)
  if (!is.null(export_path) && is.null(title)) {
    stop("`title` is required when `export_path` is supplied.", call. = FALSE)
  }

  if (is.null(cache_dir)) {
    cache_dir <- file.path(tempdir(), "s1_thumbs")
    cli::cli_inform(c("!" = "No {.arg cache_dir} given — crops are cached in a
                             temporary directory and will be pulled again next session."))
  }

  df <- tibble::as_tibble(detections)

  # The class the markers take. Defaulting to `fleet` then `class` means a table
  # built by the usual pipeline needs no argument at all.
  if (is.null(class_col)) {
    class_col <- intersect(c("fleet", "class"), names(df))[1]
  }
  has_class <- !is.na(class_col) && !is.null(class_col) && class_col %in% names(df)
  df$.class <- if (has_class) as.character(df[[class_col]]) else "Detection"

  levels_in  <- if (has_class && is.factor(df[[class_col]])) {
    intersect(levels(df[[class_col]]), df$.class)
  } else {
    sort(unique(df$.class))
  }
  if (is.null(palette)) {
    palette <- stats::setNames(
      grDevices::grey.colors(length(levels_in), start = 0.35, end = 0.75), levels_in)
  }
  palette <- palette[levels_in]

  src      <- psd_crop_sources(df, cache_dir = cache_dir, buffer_m = buffer_m,
                               view = view, embed = embed,
                               thumb_url = s1_thumb_url,
                               labels    = vapply(s1_views[view], `[[`, character(1), "label"),
                               connect   = function() {
                                 if (is.null(ee_project) || !nzchar(ee_project)) {
                                   stop("Rendering Sentinel-1 crops needs Earth Engine: pass `ee_project`. ",
                                        "Crops already in `cache_dir` need no account, which is why this is ",
                                        "only reached when one is missing.", call. = FALSE)
                                 }
                                 ee_connect(project = ee_project, python = ee_python,
                                            asset_home = ee_asset_home)
                               })
  has_crop <- Reduce(`|`, lapply(src, function(x) !is.na(x)))

  fmt_num <- function(x, d) ifelse(is.na(x), "—", formatC(round(x, d), format = "f", digits = d))

  stamp <- first_col(df, c("detect_timestamp", "when"))
  when  <- if (is.null(stamp)) rep(NA_character_, nrow(df)) else {
    paste0(format(as.POSIXct(stamp, tz = "UTC"), "%d %b %Y %H:%M"), " UTC")
  }

  size <- first_col(df, c("length_m_inferred", "length_m"))
  len  <- if (is.null(size)) rep("", nrow(df)) else {
    ifelse(is.na(size), "", paste0(" · inferred length ", round(size), " m"))
  }

  # GFW's own scores, when the caller's table carries them. None is required:
  # a table without them shows no score line and keeps arrival order, exactly
  # as before these existed. `matching_score` is NA wherever a detection has
  # no AIS match at all — there is no score to show for a match that was
  # never made, and `fmt_num` already prints that as "—".
  fishing  <- df[["fishing_score"]]
  presence <- df[["presence_score"]]
  matching <- df[["matching_score"]]
  has_score <- !is.null(fishing)

  # `if/else`, not `ifelse()`: whether a column exists at all is one decision
  # for the whole table, not a per-row test, and `ifelse()` shapes its result
  # to its `test` — with a length-one `is.null(...)` as that test, it silently
  # collapsed every row's own presence and matching score down to row one's,
  # repeated for the whole popup column. Only `fishing` was ever written the
  # right way; this had been showing one frozen value for every detection
  # since presence and matching scores were added to the popup.
  scores <- if (is.null(fishing) && is.null(presence) && is.null(matching)) "" else {
    paste0("<b>Fishing score:</b> ", if (is.null(fishing)) "—" else fmt_num(fishing, 2),
           if (is.null(presence)) "" else
             paste0(" &nbsp;·&nbsp; <b>Presence:</b> ", fmt_num(presence, 2)),
           if (is.null(matching)) "" else
             paste0(" &nbsp;·&nbsp; <b>Matching:</b> ", fmt_num(matching, 2)),
           "<br/>")
  }

  # Highest fishing score first, matching how `explore_s2_detections()` already
  # orders its own gallery by `presence_score`. Without a score, rows keep the
  # order they arrived in — `order()` on an all-NA or absent vector is a no-op
  # identity permutation, so this needs no separate branch.
  ord       <- if (has_score) order(-fishing, na.last = TRUE) else seq_len(nrow(df))
  rank      <- integer(nrow(df))
  rank[ord] <- seq_len(nrow(df)) - 1L

  link <- ifelse(!has_crop,
                 "<span class='psd-dead'>No Sentinel-1 crop for this scene</span>",
                 paste0("<a class='psd-thumb' data-i='", rank, "' href='#' ",
                        "target='_blank' rel='noopener'>View Sentinel-1 ",
                        if (length(view) > 1) "crops" else "crop", "</a>"))

  df$popup <- paste0(
    "<div class='psd-pop'>",
    "<b>Detection:</b> <span title='", df$detect_id, "'>", df$.class, "</span><br/>",
    ifelse(is.na(when), "", paste0("<b>When:</b> ", when, "<br/>")),
    ifelse(nzchar(len), paste0("<b>Size:</b>", sub("^ · inferred length", "", len), "<br/>"), ""),
    scores,
    "<b>Scene:</b> <span class='psd-scene'>", df$scene_id, "</span><br/><br/>",
    link, "</div>")

  pal <- leaflet::colorFactor(palette = unname(palette), levels = names(palette))

  if (is.null(legend_title)) {
    legend_title <- paste(format(nrow(df), big.mark = ","), "detections")
  }

  m <- leaflet::leaflet(df, options = leaflet::leafletOptions(zoomControl = FALSE))
  if (!is.null(boundary)) {
    m <- leaflet::addPolygons(m, data = boundary, fill = FALSE,
                              color = boundary_color, weight = 2)
  }
  m <- leaflet::addCircleMarkers(m, lng = ~detect_lon, lat = ~detect_lat,
                                 color = pal(df$.class), radius = 6, weight = 1,
                                 opacity = 0.9, fillOpacity = 0.55, popup = df$popup,
                                 popupOptions = leaflet::popupOptions(maxWidth = 330))
  if (has_class) {
    m <- leaflet::addLegend(m, position = "bottomright", pal = pal, values = df$.class,
                            title = legend_title, opacity = 1)
  }
  m <- add_ps_map_chrome(m)

  caption <- paste0(df$.class, ifelse(is.na(when), "", paste0(" · ", when)),
                    if (has_score) paste0(" · fishing score ", fmt_num(fishing, 2)) else "", len)
  labels  <- vapply(s1_views[view], `[[`, character(1), "label")

  # Radar carries no AIS match to mark, so the tile tint comes from the class
  # colour rather than from `matched`, as it would for optical. The gallery's
  # own score badge and step order, though, now read the same score the class
  # itself is drawn from — reordered here exactly as `explore_s2_detections()`
  # reorders by `presence_score`.
  m <- htmlwidgets::onRender(m, psd_inspector_js(lapply(src, `[`, ord), caption[ord], unname(labels),
                                                lat   = df$detect_lat[ord],
                                                lon   = df$detect_lon[ord],
                                                score = if (has_score) fishing[ord] else NULL,
                                                tint  = pal(df$.class)[ord]))
  m <- htmlwidgets::prependContent(
    m, htmltools::tags$style(htmltools::HTML(psd_inspector_css(panels = length(view)))))

  if (!is.null(export_path)) {
    ensure_pandoc()
    export_ps_map(if (gallery) htmlwidgets::onRender(m, psd_gallery_js(gallery_order)) else m,
                  title, subtitle, export_path)
  }

  m
}
