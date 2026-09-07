# explore_s2_detections.R ----------------------------------------------------
# Interactive Sentinel-2 detection map, with the imagery behind each detection
#
# The radar sibling of this file is explore_s1_detections.R, and the machinery
# both stand on is in detection_inspector.R: the crop cache, the base64
# embedding, the inspector overlay, the contact sheet and the title-banner
# export. What lives here is what optical alone knows — the visible-light
# stretches, the archive the crops come from, and the question the map asks.
#
#   * Optical resolves smaller hulls than radar and pays for it twice, in
#     daylight and in cloud, so a crop is judged on shape and on whether the
#     thing is solid: hence an ocean stretch and a near-infrared one.
#   * The interesting split is whether AIS explains a detection, so markers are
#     matched against unmatched and a match carries the MMSI behind it.
#
# Internal helpers (not exported): s2_views, s2_thumb_url().

# The four stretches the Earth Engine Code Editor offers. Open ocean sits at the
# bottom of the range, so natural colour is too dark to judge by; the tight
# "ocean" stretch is what separates a hull from a wave crest, which is why it is
# the default. Near-infrared is the third opinion — water absorbs it almost
# entirely, so anything solid comes back bright — and the false-colour composite
# puts that band where the eye reads it fastest.
s2_views <- list(
  ocean        = list(label = "Ocean stretch",    bands = c("B4", "B3", "B2"), min = 0, max = 1000, gamma = 1.1),
  natural      = list(label = "Natural colour",   bands = c("B4", "B3", "B2"), min = 0, max = 2500, gamma = 1.2),
  nir          = list(label = "Near-infrared",    bands = "B8",                min = 0, max = 1000),
  false_colour = list(label = "NIR false colour", bands = c("B8", "B4", "B3"), min = 0, max = 1500)
)

#' Explore Sentinel-2 Vessel Detections, With The Imagery Behind Each One
#'
#' @description
#' Builds the standard Pristine Seas Sentinel-2 detection map: one marker per
#' detection on satellite imagery, a popup carrying the model's scores and the
#' scene the detection came from, and — behind a **View Sentinel-2 thumbnail**
#' link — the crop itself, opened full-size with a red ring marking the exact
#' detection position. Arrow keys step through every detection in turn, so a
#' few hundred candidates can be reviewed without going back to the map.
#'
#' Crops are rendered by Earth Engine, cached to `cache_dir`, and inlined into
#' the page, which is what lets the exported map travel: send the HTML to a
#' colleague and it opens with no Earth Engine account, no credentials, and no
#' access to the data behind it. Only the basemap is fetched live.
#'
#' Earth Engine is contacted **only for crops not already cached**, so a map
#' whose cache is warm needs no credentials at all and builds in about a second.
#'
#' @param detections A detection table, or a path to a CSV of one — such as a
#'   pull from GFW's `detect_scene_match_pipe` tables. Must include `detect_id`,
#'   `detect_lat`, `detect_lon`, `scene_id`, `presence_score` and `cloud_score`.
#'   Optional columns used when present: `detect_timestamp` (or `when`),
#'   `length_m_inferred` (or `length_m`),
#'   `matched` (logical), and `mmsi` — or `ssvid`, GFW's name for the same
#'   number on AIS data. Each adds a line to the popup and the crop's caption;
#'   `matched`, or `ssvid` standing in for it, is also what splits the markers
#'   into matched and unmatched, and the MMSI is what makes a matched detection
#'   a vessel you can look up rather than just an object on the water.
#' @param cache_dir Directory the crops are cached in, one PNG per detection.
#'   Defaults to a session temporary directory, which means every crop is pulled
#'   again next session — pass a real path for anything you intend to re-render.
#' @param buffer_m Half-width of the crop, in metres: the frame is twice this
#'   across. Default `500`, so a 1 km view in which a 30 m hull is three pixels.
#' @param view Which stretch to render: `"ocean"` (the default, and the one that
#'   separates a hull from a wave crest), `"natural"`, `"nir"`, or
#'   `"false_colour"`. Give it more than one and each detection is shown in all
#'   of them, side by side — `c("ocean", "nir")` is the useful pair, since water
#'   absorbs near-infrared almost entirely and anything solid comes back bright.
#'   Every extra view is another crop to render, cache and inline, so the cost
#'   and the file size scale with the number asked for.
#' @param embed Inline each crop into the page as a `data:` URI. `TRUE`, the
#'   default, and the only setting that produces a map worth sending anyone.
#'   `FALSE` links to the Earth Engine URLs instead — lighter, but the map stops
#'   working when those expire, which takes days.
#' @param boundary Optional `sf` polygon drawn over the imagery, e.g. an MPA.
#' @param boundary_color Colour of that outline. Default `"#B6D94C"`.
#' @param matched_color,unmatched_color Marker colours for detections matched to
#'   AIS and detections not matched. Ignored when `class_col` is active.
#' @param class_col Name of a column giving each matched detection an identity —
#'   a vessel type, say — beyond the plain matched/unmatched split. Defaults to
#'   `"type"` when present, so a table built with a vessel-type join needs no
#'   argument at all; `NULL` keeps the plain two-colour behaviour regardless of
#'   what the table carries. The same generalisation [explore_s1_detections()]
#'   already makes, for the same reason: a match is an identity, not just a
#'   broadcast.
#' @param palette Named colours, one per level of `class_col`. Defaults to a
#'   grey ramp when `class_col` is active and no palette is given.
#' @param gallery_order How the contact sheet is sorted, named under its count.
#'   Rows are drawn in the order they arrive, so this labels that order rather
#'   than imposing one.
#' @param gallery Give the exported map a second pane: every detection as a
#'   thumbnail, ordered by detection score, linked both ways to the map. Clicking
#'   a thumbnail flies the map there and opens the crop; opening a marker's popup
#'   scrolls the gallery to its thumbnail. `TRUE` by default, and it adds nothing
#'   to the file — the thumbnails are crops the page already carries. The widget
#'   this function *returns* is always the plain map, since a two-pane dashboard
#'   wants a full window rather than a report's figure column.
#' @param legend_title Heading over the legend. Defaults to the detection count.
#' @param title Map title shown in the banner on the *exported* map only (see
#'   `export_path`) — not on the widget this returns, since an inline report
#'   already has its own heading. Required if `export_path` is supplied.
#' @param subtitle Small text under that title. `""` hides it.
#' @param export_path If supplied, a self-contained standalone HTML copy is
#'   saved here. This is the shareable artefact, and with `embed = TRUE` it is
#'   the whole tool in one file.
#' @param ee_project,ee_python,ee_asset_home Passed to [ee_connect()] if — and
#'   only if — a crop has to be rendered. `ee_project` is required in that case.
#'
#' @return A `leaflet` htmlwidget. Print it to display it inline; or ignore the
#'   return value and use `export_path`, which is usually the better read since
#'   the map wants a full window.
#'
#' @examples
#' \dontrun{
#' explore_s2_detections(
#'   detections  = s2_detections,
#'   cache_dir   = file.path(gfw_dir, "s2_thumbs"),
#'   boundary    = mpa,
#'   title       = "Sentinel-2 detections in Bikar-Bokak since designation",
#'   export_path = file.path(fig_dir, "s2_detections.html"),
#'   ee_project  = "pristine-seas"
#' )
#' }
#'
#' @export
explore_s2_detections <- function(detections,
                                  cache_dir       = NULL,
                                  buffer_m        = 500,
                                  view            = "ocean",
                                  embed           = TRUE,
                                  boundary        = NULL,
                                  boundary_color  = "#B6D94C",
                                  matched_color   = "#4EC9E8",
                                  unmatched_color = "#8A949E",
                                  class_col       = NULL,
                                  palette         = NULL,
                                  gallery         = TRUE,
                                  gallery_order   = "by detection score",
                                  legend_title    = NULL,
                                  title           = NULL,
                                  subtitle        = "National Geographic Pristine Seas",
                                  export_path     = NULL,
                                  ee_project      = NULL,
                                  ee_python       = Sys.getenv("EARTHENGINE_PYTHON"),
                                  ee_asset_home   = NULL) {

  # `several.ok`: more than one view means more than one crop per detection,
  # shown side by side. Two is the useful case — the ocean stretch to see the
  # shape, near-infrared to see whether the thing is solid.
  view <- match.arg(view, names(s2_views), several.ok = TRUE)

  if (is.character(detections) && length(detections) == 1) {
    detections <- readr::read_csv(detections, show_col_types = FALSE)
  }

  required_cols <- c("detect_id", "detect_lat", "detect_lon", "scene_id",
                     "presence_score", "cloud_score")
  missing_cols  <- setdiff(required_cols, names(detections))
  if (length(missing_cols) > 0) {
    stop("`detections` is missing required column(s): ",
         paste(missing_cols, collapse = ", "), call. = FALSE)
  }
  if (nrow(detections) == 0) {
    stop("`detections` has no rows.", call. = FALSE)
  }
  if (!is.null(export_path) && is.null(title)) {
    stop("`title` is required when `export_path` is supplied.", call. = FALSE)
  }

  if (is.null(cache_dir)) {
    cache_dir <- file.path(tempdir(), "s2_thumbs")
    cli::cli_inform(c("!" = "No {.arg cache_dir} given — crops are cached in a temporary
                             directory and will be pulled again next session."))
  }

  df <- tibble::as_tibble(detections)

  # AIS matching splits the markers, and it arrives under either name. Neither
  # is required: without them every detection is simply "Detection".
  if (!"matched" %in% names(df) && "ssvid" %in% names(df)) df$matched <- !is.na(df$ssvid)
  has_status <- "matched" %in% names(df)

  # A class beyond plain matched/unmatched, when the table carries one — a
  # vessel type, typically, from the same identity join radar reads. Defaulting
  # to `type` means a table built by the usual pipeline needs no argument at
  # all; `class_col = NULL` explicitly, or a table with neither column, falls
  # straight through to the two-colour behaviour below, unchanged.
  if (is.null(class_col)) {
    class_col <- intersect(c("type"), names(df))[1]
  }
  has_class <- !is.na(class_col) && !is.null(class_col) && class_col %in% names(df)

  if (has_class) {
    df$.class <- as.character(df[[class_col]])
    levels_in <- if (is.factor(df[[class_col]])) {
      intersect(levels(df[[class_col]]), df$.class)
    } else {
      sort(unique(df$.class))
    }
    if (is.null(palette)) {
      palette <- stats::setNames(
        grDevices::grey.colors(length(levels_in), start = 0.35, end = 0.75), levels_in)
    }
    palette      <- palette[levels_in]
    status_levels <- levels_in
    df$status    <- df$.class
  } else {
    status_levels <- c("Matched to AIS", "Not matched to AIS", "Detection")
    df$status <- if (has_status) {
      ifelse(df$matched, "Matched to AIS", "Not matched to AIS")
    } else {
      "Detection"
    }
  }

  # The identity behind a match, which is the whole value of one: an unmatched
  # detection is an object, a matched one is a named vessel you can go and look
  # up. `ssvid` is GFW's name for the number, and on AIS data it is the MMSI.
  # Formatted rather than coerced because the column often arrives as a double,
  # and `as.character()` on one is a scientific-notation accident waiting.
  id_col <- intersect(c("mmsi", "ssvid"), names(df))
  mmsi   <- if (length(id_col) > 0) {
    ifelse(is.na(df[[id_col[1]]]), NA_character_,
           format(df[[id_col[1]]], scientific = FALSE, trim = TRUE))
  } else {
    rep(NA_character_, nrow(df))
  }
  mmsi_tag <- ifelse(is.na(mmsi) | !nzchar(mmsi), "",
                     paste0(" · MMSI <span class='psd-mmsi'>", mmsi, "</span>"))

  # ---- Crops ------------------------------------------------------------------
  src <- psd_crop_sources(
    df, cache_dir = cache_dir, buffer_m = buffer_m, view = view, embed = embed,
    thumb_url = s2_thumb_url,
    labels    = vapply(s2_views[view], `[[`, character(1), "label"),
    connect   = function() {
      if (is.null(ee_project) || !nzchar(ee_project)) {
        stop("Rendering Sentinel-2 crops needs Earth Engine: pass `ee_project`. ",
             "Crops already in `cache_dir` need no account, which is why this is ",
             "only reached when one is missing.", call. = FALSE)
      }
      ee_connect(project = ee_project, python = ee_python, asset_home = ee_asset_home)
    }
  )

  # A detection is only unshowable when no view rendered; one missing panel
  # among several is a gap in the row, not a reason to drop the link.
  has_crop <- Reduce(`|`, lapply(src, function(x) !is.na(x)))

  # ---- Popups and captions ----------------------------------------------------
  # Two renderings of the same row. The popup is what the map shows; the caption
  # is what the crop shows, and it has to exist for every detection up front —
  # the arrow keys reach detections whose popup has never been opened.
  fmt_num  <- function(x, d) ifelse(is.na(x), "—", formatC(round(x, d), format = "f", digits = d))
  stamp <- first_col(df, c("detect_timestamp", "when"))
  when  <- if (is.null(stamp)) rep(NA_character_, nrow(df)) else {
    paste0(format(as.POSIXct(stamp, tz = "UTC"), "%d %b %Y %H:%M"), " UTC")
  }

  size <- first_col(df, c("length_m_inferred", "length_m"))
  len  <- if (is.null(size)) rep("", nrow(df)) else {
    ifelse(is.na(size), "", paste0(" · inferred length ", round(size), " m"))
  }

  # Everything the reader steps through — the viewer, the arrow keys, the
  # gallery — runs in score order, highest first, because that is the order a
  # reviewer wants: the most vessel-like thing the model found should be the
  # first crop they see. `rank` is where each row lands in that order and is
  # what the popup link hands over; the map itself keeps the order it was given,
  # being spatial.
  ord       <- order(-df$presence_score)
  rank      <- integer(nrow(df))
  rank[ord] <- seq_len(nrow(df)) - 1

  labels     <- vapply(view, function(v) s2_views[[v]]$label, character(1))
  scale_note <- paste0(2 * buffer_m, " m across · Sentinel-2 at 10 m · ",
                       "\u2190 \u2192 to step, Esc to close")

  caption <- paste0(
    "<b>", df$status, "</b>", mmsi_tag,
    ifelse(is.na(when), "", paste0(" · ", when)), "<br/>",
    "Presence ", fmt_num(df$presence_score, 2), " · cloud ", fmt_num(df$cloud_score, 3), len,
    "<br/><span class='psd-scene'>", df$scene_id, "</span>",
    "<div class='psd-lb-foot'>", scale_note, "</div>"
  )

  # An inlined crop is not a place a browser will navigate to, so in embed mode
  # the link stops pretending to be one and lets the handler do the work.
  href <- if (embed) rep("#", nrow(df)) else ifelse(has_crop, src[[1]], "#")
  link <- ifelse(
    !has_crop,
    "<span class='psd-dead'>No Sentinel-2 crop for this scene</span>",
    paste0("<a class='psd-thumb' data-i='", rank, "' href='", href,
           "' target='_blank' rel='noopener'>View Sentinel-2 ",
           if (length(view) > 1) "crops" else "thumbnail", "</a>")
  )

  df$popup <- paste0(
    "<div class='psd-pop'>",
    "<b>Detection:</b> <span title='", df$detect_id, "'>", trunc_middle(df$detect_id, 42), "</span><br/>",
    ifelse(is.na(when), "", paste0("<b>When:</b> ", when, "<br/>")),
    "<b>Presence:</b> ", fmt_num(df$presence_score, 2),
    " &nbsp;·&nbsp; <b>Cloud:</b> ", fmt_num(df$cloud_score, 3), "<br/>",
    if (has_class) {
      # The class already says whether AIS explains the detection — Dark is
      # exactly the unmatched half — so it replaces the plain match line
      # rather than sitting beside it.
      paste0("<b>Type:</b> ", df$.class, mmsi_tag, "<br/>")
    } else if (has_status) {
      # "AIS: Matched to AIS" reads twice, so the label carries the channel and
      # the value carries only what is new — the match, and who it matched.
      paste0("<b>AIS:</b> ", ifelse(df$matched, "Matched", "Not matched"),
             mmsi_tag, "<br/>")
    } else {
      ""
    },
    "<b>Scene:</b> <span class='psd-scene'>", df$scene_id, "</span><br/><br/>",
    link, "</div>"
  )

  # ---- Map --------------------------------------------------------------------
  # `levels` is given explicitly because colorFactor() otherwise sorts the domain
  # alphabetically, which would hand the matched colour to whichever label
  # happens to sort first rather than to the matched detections — or, with a
  # class column, scramble a caller's own reading order.
  pal <- if (has_class) {
    leaflet::colorFactor(palette = unname(palette), levels = status_levels)
  } else {
    leaflet::colorFactor(palette = c(matched_color, unmatched_color, unmatched_color),
                         levels = status_levels)
  }

  if (is.null(legend_title)) {
    legend_title <- paste(format(nrow(df), big.mark = ","), "detections")
  }

  m <- leaflet::leaflet(df, options = leaflet::leafletOptions(zoomControl = FALSE))

  if (!is.null(boundary)) {
    m <- leaflet::addPolygons(m, data = boundary, fill = FALSE,
                               color = boundary_color, weight = 2)
  }

  m <- leaflet::addCircleMarkers(
    m,
    lng = ~detect_lon, lat = ~detect_lat,
    color = pal(df$status), radius = 6, weight = 1,
    opacity = 0.9, fillOpacity = 0.55,
    popup = df$popup,
    popupOptions = leaflet::popupOptions(maxWidth = 330)
  )

  if (has_class || has_status) {
    m <- leaflet::addLegend(m, position = "bottomright", pal = pal, values = ~status,
                             title = legend_title, opacity = 1)
  }

  # `matched` reads the underlying boolean rather than the display string:
  # with a class column active, `status` carries type labels like "Fishing
  # vessels", never the literal "Matched to AIS" this used to compare against,
  # and comparing against it would have silently turned every gallery tile's
  # matched-outline off the day a class column was ever attached.
  m <- add_ps_map_chrome(m)
  m <- htmlwidgets::onRender(
    m,
    psd_inspector_js(lapply(src, `[`, ord), caption[ord], unname(labels),
                    lat     = df$detect_lat[ord],
                    lon     = df$detect_lon[ord],
                    score   = df$presence_score[ord],
                    matched = if (has_status) df$matched[ord] else NULL,
                    tint    = if (has_class) pal(df$status)[ord] else NULL)
  )
  m <- htmlwidgets::prependContent(
    m, htmltools::tags$style(htmltools::HTML(psd_inspector_css(panels = length(view))))
  )

  if (!is.null(export_path)) {
    ensure_pandoc()
    # The gallery goes on the exported copy only. It takes over the viewport,
    # which is right for a page opened on its own and wrong inside a report that
    # has its own column — the same reason the title banner is added here rather
    # than to the widget the caller prints.
    export_ps_map(if (gallery) htmlwidgets::onRender(m, psd_gallery_js(gallery_order)) else m,
                  title, subtitle, export_path)
  }

  m
}

# One rendered crop, as a URL. The collection is narrowed by date and by the
# detection's own position before PRODUCT_ID is matched: filtering the archive
# on the id alone works, and is what the Code Editor examples do, but it scans
# every scene ever taken and costs about fifteen seconds a call. Narrowed first,
# the same lookup costs less than one.
s2_thumb_url <- function(scene_id, lon, lat, buffer_m, px, view) {

  ee    <- rgee::ee
  point <- ee$Geometry$Point(c(lon, lat))
  day   <- as.Date(stringr::str_extract(scene_id, "[0-9]{8}"), "%Y%m%d")

  hit <- ee$ImageCollection("COPERNICUS/S2_HARMONIZED")$
    filterDate(format(day - 1), format(day + 2))$
    filterBounds(point)$
    filter(ee$Filter$eq("PRODUCT_ID", scene_id))$
    first()

  vis <- s2_views[[view]][c("bands", "min", "max", "gamma")]
  vis <- vis[!vapply(vis, is.null, logical(1))]

  # An id the archive does not hold returns an empty collection, and the error
  # that follows names a null parameter rather than the scene. One detection
  # without a crop must not cost the whole map.
  tryCatch(
    ee$Image(hit)$getThumbURL(c(list(region     = point$buffer(buffer_m)$bounds(),
                                     dimensions = as.integer(px),
                                     format     = "png"),
                                vis)),
    error = function(e) {
      warning("No Sentinel-2 image with PRODUCT_ID ", scene_id, call. = FALSE)
      NA_character_
    }
  )
}
