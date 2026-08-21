# explore_s2_detections.R ---------------------------------------------------
# Interactive Sentinel-2 detection map, with the imagery behind each detection
#
# Public API:
#   - explore_s2_detections(): the map — one marker per detection, each popup
#     opening the Sentinel-2 crop that detection was made from, marked at its
#     exact centre so a three-pixel hull is never lost in the frame
#   - ee_connect(): the Earth Engine connection the crops are rendered through.
#     Exported because it is worth opening once per session, and because its two
#     workarounds are the whole reason rgee is usable from a knitr chunk at all
#
# Internal helpers (not exported): s2_views, s2_thumb_path(), s2_thumb_url(),
# s2_crop_sources(), s2_inspector_css(), s2_inspector_js(), ensure_pandoc().
# The satellite chrome and title-banner export come from map_utils.R, so this
# map looks like every other Pristine Seas map.
#
# On caching, which is what makes the map worth exporting: `getThumbURL()` hands
# back a rendered resource, not a permanent link, and it dies within days. So the
# crops are downloaded once into `cache_dir` and inlined as `data:` URIs. Nothing
# in the exported HTML can expire, a cached crop never costs a second Earth
# Engine round-trip, and a caller whose crops are all cached needs no Earth
# Engine credentials at all.

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

# Session state, so a second map in the same document does not pay for the
# Earth Engine handshake twice
.s2_state <- new.env(parent = emptyenv())

#' Connect to Google Earth Engine
#'
#' @description
#' Opens the `rgee` connection that [explore_s2_detections()] renders its crops
#' through, working around two things that otherwise make `rgee` unusable from a
#' knitr chunk:
#'
#' * `rgee` asks Earth Engine for the account's legacy asset root, but the
#'   `earthengine-api` no longer answers that call — it returns nothing whether
#'   or not a home exists. `rgee` then prompts for a folder name, and
#'   `readline()` returns `""` instantly in a non-interactive chunk, so the
#'   prompt loops on an answer it will never get. Supplying `asset_home` skips
#'   the lookup entirely.
#' * `reticulate` does not read `EARTHENGINE_PYTHON` — that variable is `rgee`'s
#'   — and defaults to its own managed environment, which has no
#'   `earthengine-api`. `rgee` then reports the interpreter it *wanted* rather
#'   than the one in use, so the error names a Python that does have the package.
#'   Binding the interpreter before `rgee` touches Python at all avoids it.
#'
#' Calling this more than once in a session is free: the connection is opened on
#' the first call and remembered.
#'
#' @param project Earth Engine cloud project to bill and authenticate against,
#'   e.g. `"pristine-seas"`.
#' @param python Path to a Python interpreter that has `earthengine-api`
#'   installed. Defaults to the `EARTHENGINE_PYTHON` environment variable; pass
#'   `""` to leave `reticulate`'s own choice alone.
#' @param asset_home The account's Earth Engine asset root, e.g.
#'   `"users/jsmith"`. Optional, and only needed if `rgee` stalls on the asset
#'   root prompt described above.
#' @param force Re-open the connection even if one was already made this
#'   session. Default `FALSE`.
#'
#' @return `TRUE`, invisibly.
#'
#' @examples
#' \dontrun{
#' ee_connect(project = "pristine-seas", asset_home = "users/jsmith")
#' }
#'
#' @export
ee_connect <- function(project,
                       python     = Sys.getenv("EARTHENGINE_PYTHON"),
                       asset_home = NULL,
                       force      = FALSE) {

  if (!force && isTRUE(.s2_state$connected)) return(invisible(TRUE))

  if (missing(project) || is.null(project) || !nzchar(project)) {
    stop("`project` is required: the Earth Engine cloud project to authenticate ",
         "against, e.g. \"pristine-seas\".", call. = FALSE)
  }

  rlang::check_installed(c("rgee", "reticulate"),
                         "to render Sentinel-2 crops from Earth Engine.")

  if (!is.null(python) && nzchar(python)) {
    reticulate::use_python(python, required = TRUE)
  }

  # Deliberate: there is no supported way to tell rgee the asset root, and the
  # lookup it does instead cannot succeed. R CMD check notes this call.
  if (!is.null(asset_home)) {
    utils::assignInNamespace("ee_check_root_folder", function() asset_home, ns = "rgee")
  }

  rgee::ee_Initialize(project = project, quiet = TRUE)

  .s2_state$connected <- TRUE
  invisible(TRUE)
}

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
#'   Optional columns used when present: `detect_timestamp`, `length_m_inferred`,
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
#'   AIS and detections not matched.
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
                                  gallery         = TRUE,
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
    cache_dir <- file.path(tempdir(), "s2_crops")
    cli::cli_inform(c("!" = "No {.arg cache_dir} given \u2014 crops are cached in a temporary
                             directory and will be pulled again next session."))
  }

  df <- tibble::as_tibble(detections)

  # AIS matching splits the markers, and it arrives under either name. Neither
  # is required: without them every detection is simply "Detection".
  if (!"matched" %in% names(df) && "ssvid" %in% names(df)) df$matched <- !is.na(df$ssvid)
  has_status <- "matched" %in% names(df)
  df$status  <- if (has_status) {
    ifelse(df$matched, "Matched to AIS", "Not matched to AIS")
  } else {
    "Detection"
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
                     paste0(" \u00b7 MMSI <span class='s2-mmsi'>", mmsi, "</span>"))

  # ---- Crops ------------------------------------------------------------------
  src <- s2_crop_sources(
    df, cache_dir = cache_dir, buffer_m = buffer_m, view = view, embed = embed,
    connect = function() {
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
  fmt_num  <- function(x, d) ifelse(is.na(x), "\u2014", formatC(round(x, d), format = "f", digits = d))
  when     <- if ("detect_timestamp" %in% names(df)) {
    paste0(format(as.POSIXct(df$detect_timestamp, tz = "UTC"), "%d %b %Y %H:%M"), " UTC")
  } else {
    rep(NA_character_, nrow(df))
  }
  len <- if ("length_m_inferred" %in% names(df)) {
    ifelse(is.na(df$length_m_inferred), "",
           paste0(" \u00b7 inferred length ", round(df$length_m_inferred), " m"))
  } else {
    rep("", nrow(df))
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
  scale_note <- paste0(2 * buffer_m, " m across \u00b7 Sentinel-2 at 10 m \u00b7 ",
                       "\u2190 \u2192 to step, Esc to close")

  caption <- paste0(
    "<b>", df$status, "</b>", mmsi_tag,
    ifelse(is.na(when), "", paste0(" \u00b7 ", when)), "<br/>",
    "Presence ", fmt_num(df$presence_score, 2), " \u00b7 cloud ", fmt_num(df$cloud_score, 3), len,
    "<br/><span class='s2-scene'>", df$scene_id, "</span>",
    "<div class='s2-lb-foot'>", scale_note, "</div>"
  )

  # An inlined crop is not a place a browser will navigate to, so in embed mode
  # the link stops pretending to be one and lets the handler do the work.
  href <- if (embed) rep("#", nrow(df)) else ifelse(has_crop, src[[1]], "#")
  link <- ifelse(
    !has_crop,
    "<span class='s2-dead'>No Sentinel-2 crop for this scene</span>",
    paste0("<a class='s2-thumb' data-i='", rank, "' href='", href,
           "' target='_blank' rel='noopener'>View Sentinel-2 ",
           if (length(view) > 1) "crops" else "thumbnail", "</a>")
  )

  df$popup <- paste0(
    "<div class='s2-pop'>",
    "<b>Detection:</b> <span title='", df$detect_id, "'>", trunc_middle(df$detect_id, 42), "</span><br/>",
    ifelse(is.na(when), "", paste0("<b>When:</b> ", when, "<br/>")),
    "<b>Presence:</b> ", fmt_num(df$presence_score, 2),
    " &nbsp;\u00b7&nbsp; <b>Cloud:</b> ", fmt_num(df$cloud_score, 3), "<br/>",
    if (has_status) {
      # "AIS: Matched to AIS" reads twice, so the label carries the channel and
      # the value carries only what is new — the match, and who it matched.
      paste0("<b>AIS:</b> ", ifelse(df$matched, "Matched", "Not matched"),
             mmsi_tag, "<br/>")
    } else {
      ""
    },
    "<b>Scene:</b> <span class='s2-scene'>", df$scene_id, "</span><br/><br/>",
    link, "</div>"
  )

  # ---- Map --------------------------------------------------------------------
  # `levels` is given explicitly because colorFactor() otherwise sorts the domain
  # alphabetically, which would hand the matched colour to whichever label
  # happens to sort first rather than to the matched detections.
  status_levels <- c("Matched to AIS", "Not matched to AIS", "Detection")
  pal <- leaflet::colorFactor(palette = c(matched_color, unmatched_color, unmatched_color),
                               levels = status_levels)

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

  if (has_status) {
    m <- leaflet::addLegend(m, position = "bottomright", pal = pal, values = ~status,
                             title = legend_title, opacity = 1)
  }

  m <- add_ps_map_chrome(m)
  m <- htmlwidgets::onRender(
    m,
    s2_inspector_js(lapply(src, `[`, ord), caption[ord], unname(labels),
                    lat     = df$detect_lat[ord],
                    lon     = df$detect_lon[ord],
                    score   = df$presence_score[ord],
                    matched = df$status[ord] == "Matched to AIS")
  )
  m <- htmlwidgets::prependContent(
    m, htmltools::tags$style(htmltools::HTML(s2_inspector_css(panels = length(view))))
  )

  if (!is.null(export_path)) {
    ensure_pandoc()
    # The gallery goes on the exported copy only. It takes over the viewport,
    # which is right for a page opened on its own and wrong inside a report that
    # has its own column — the same reason the title banner is added here rather
    # than to the widget the caller prints.
    export_ps_map(if (gallery) htmlwidgets::onRender(m, s2_gallery_js()) else m,
                  title, subtitle, export_path)
  }

  m
}

# Middle-truncate an identifier: a detection id is its scene plus its position,
# so both ends carry information and only the middle is safe to drop
trunc_middle <- function(x, width) {
  ifelse(nchar(x) <= width, x,
         paste0(substr(x, 1, ceiling((width - 1) / 2)), "\u2026",
                substr(x, nchar(x) - floor((width - 1) / 2) + 1, nchar(x))))
}

# Where a detection's crop lives. `detect_id` is the scene id with the position
# appended, so the name is unique by construction and traces back to its row
s2_thumb_path <- function(detect_id, cache_dir, buffer_m, px, view) {
  file.path(cache_dir,
            paste0(gsub("[^A-Za-z0-9._-]", "_", detect_id),
                   "_", buffer_m, "m_", px, "px_", view, ".png"))
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

# The crop for every row, as something an <img> can use.
#
# Asking Earth Engine for a bigger thumbnail than the sensor holds buys nothing:
# it upsamples nearest-neighbour, so a 600-pixel crop of a 1 km window is the
# same hundred pixels drawn six times over, at half again the bytes. The browser
# does that upsampling itself (`image-rendering: pixelated` in the CSS), so the
# crop is pulled at native scale and blown up on arrival.
s2_crop_sources <- function(df, cache_dir, buffer_m, view, embed, connect) {

  px       <- as.integer(ceiling(2 * buffer_m / 10))
  connected <- FALSE

  # Deferred, so a run whose cache is complete never opens Earth Engine at all —
  # which is what lets a colleague rebuild the map with no credentials
  once <- function() {
    if (!connected) { connect(); connected <<- TRUE }
  }

  pull <- function(i, v) {
    vapply(i, function(k) s2_thumb_url(df$scene_id[k], df$detect_lon[k], df$detect_lat[k],
                                       buffer_m = buffer_m, px = px, view = v),
           character(1))
  }

  one_view <- function(v) {

    if (!embed) {
      # Nothing to cache: these expire, so they are always pulled fresh
      once()
      return(pull(seq_len(nrow(df)), v))
    }

    path <- s2_thumb_path(df$detect_id, cache_dir, buffer_m, px, v)
    need <- which(!file.exists(path))

    if (length(need) > 0) {
      once()
      cli::cli_inform(c("i" = "Rendering {length(need)} {s2_views[[v]]$label}
                               {cli::qty(length(need))}crop{?s} \u2014 about a second each.
                               Cached in {.path {cache_dir}}."))
      urls <- rep(NA_character_, nrow(df))
      urls[need] <- pull(need, v)
      for (k in need) {
        if (!is.na(urls[k])) {
          try(utils::download.file(urls[k], path[k], quiet = TRUE, mode = "wb"), silent = TRUE)
        }
      }
    }

    ok  <- file.exists(path)
    src <- rep(NA_character_, nrow(df))
    src[ok] <- vapply(path[ok], function(f) {
      paste0("data:image/png;base64,",
             gsub("[\r\n]", "", jsonlite::base64_enc(readBin(f, "raw", file.size(f)))))
    }, character(1), USE.NAMES = FALSE)

    src
  }

  if (embed) dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)

  out <- lapply(view, one_view)
  names(out) <- view
  out
}

# The popup card and the crop viewer. `.s2-x` is the marker over a crop's
# centre: the crop is built around the detection, so the detection is dead
# centre and the overlay needs no projection to find it. The ring is left open
# in the middle, because a marker that covered a 30 m hull at this scale would
# hide exactly what the reader came to see.
#
# Panels are laid out in a row and sized against the viewport in both axes, so
# two crops side by side stay square and on screen without a media query.
s2_inspector_css <- function(mark = "#FF3B30", panels = 1) {

  size <- if (panels == 1) "min(74vh, 600px)" else sprintf("min(70vh, 520px, %dvw)",
                                                            floor(92 / panels))

  paste0(ps_map_title_css(), "
.s2-pop{font:12px/1.5 -apple-system,system-ui,Segoe UI,Roboto,sans-serif;color:#1a1a1a}
.s2-pop .s2-scene{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:10px;
  color:#5a6672;word-break:break-all}
.s2-pop a.s2-thumb{display:inline-block;margin-top:.2rem;padding:.35rem .65rem;border-radius:4px;
  background:#12212b;color:#eaf4fa;text-decoration:none;font-weight:600;font-size:11.5px}
.s2-pop a.s2-thumb:hover{background:#1d3440}
.s2-pop .s2-dead{color:#8a949e;font-style:italic}
.s2-mmsi{font-variant-numeric:tabular-nums;letter-spacing:.02em}
.s2-lb{position:fixed;inset:0;z-index:9999;display:none;align-items:center;justify-content:center;
  background:rgba(6,10,16,.97)}
.s2-lb.on{display:flex}
.s2-lb-card{max-width:94vw;color:#e8edf2;
  font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Helvetica,Arial,sans-serif}
.s2-lb-head{display:flex;align-items:center;gap:.45rem;padding-bottom:.5rem;font-size:.78rem;
  letter-spacing:.06em;text-transform:uppercase;color:#93a1ae}
.s2-lb-head .s2-lb-count{margin-right:auto}
.s2-lb-card button{background:none;border:1px solid #38434f;color:#c7d2dc;border-radius:4px;
  cursor:pointer;font-size:.95rem;line-height:1;padding:.2rem .55rem}
.s2-lb-card button:hover{border-color:#93a1ae;color:#fff}
.s2-frames{display:flex;gap:10px;align-items:flex-start}
.s2-label{font-size:.7rem;letter-spacing:.06em;text-transform:uppercase;color:#93a1ae;
  padding-bottom:.3rem;line-height:1}
.s2-frame{position:relative;line-height:0;background:#0a0f14;
  box-shadow:0 0 0 1px #33404d}
.s2-frame img{display:block;width:", size, ";height:", size, ";image-rendering:pixelated}
.s2-x{position:absolute;left:50%;top:50%;width:44px;height:44px;margin:-22px 0 0 -22px;
  pointer-events:none}
.s2-x i{position:absolute;inset:12px;border:1.5px solid ", mark, ";border-radius:50%}
.s2-x::before,.s2-x::after{content:'';position:absolute}
.s2-x::before{left:0;right:0;top:50%;height:1.5px;margin-top:-.75px;
  background:linear-gradient(to right,", mark, " 0 8px,transparent 8px calc(100% - 8px),
  ", mark, " calc(100% - 8px) 100%)}
.s2-x::after{top:0;bottom:0;left:50%;width:1.5px;margin-left:-.75px;
  background:linear-gradient(to bottom,", mark, " 0 8px,transparent 8px calc(100% - 8px),
  ", mark, " calc(100% - 8px) 100%)}
.s2-lb-meta{padding-top:.55rem;font-size:.8rem;line-height:1.55;max-width:94vw}
.s2-lb-meta .s2-scene{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:10px;
  color:#8d99a5;word-break:break-all}
.s2-lb-foot{padding-top:.4rem;font-size:.72rem;color:#8d99a5}
.s2-dash{position:fixed;inset:0;display:flex;background:#0b1016;z-index:1}
.s2-dash-map{flex:1 1 auto;min-width:0;position:relative}
.s2-dash-side{flex:0 0 clamp(240px,32vw,460px);display:flex;flex-direction:column;
  border-left:1px solid #1e2833;background:#0b1016;
  font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Helvetica,Arial,sans-serif}
.s2-side-head{padding:12px 14px 10px;color:#e8edf2;font-size:.85rem;
  border-bottom:1px solid #1e2833}
.s2-side-head b{font-size:1.05rem}
.s2-side-head span{display:block;font-size:.7rem;letter-spacing:.06em;text-transform:uppercase;
  color:#8d99a5;margin-top:3px}
.s2-grid{flex:1 1 auto;overflow-y:auto;padding:10px;display:grid;gap:7px;
  grid-template-columns:repeat(auto-fill,minmax(84px,1fr));align-content:start}
.s2-tile{position:relative;padding:0;border:0;background:#0a0f14;cursor:pointer;
  outline:1px solid #1e2833;outline-offset:-1px}
.s2-tile img{display:block;width:100%;aspect-ratio:1/1;image-rendering:pixelated}
.s2-tile .s2-nope{display:block;width:100%;aspect-ratio:1/1;background:#11181f}
.s2-tile .s2-ring{position:absolute;left:50%;top:50%;width:15px;height:15px;margin:-7.5px 0 0 -7.5px;
  border:1px solid rgba(255,59,48,.85);border-radius:50%;pointer-events:none}
.s2-tile .s2-score{position:absolute;left:0;bottom:0;padding:1px 4px;font-size:9.5px;
  font-variant-numeric:tabular-nums;color:#dfe7ee;background:rgba(6,10,16,.72)}
.s2-tile.matched{outline:2px solid #4EC9E8}
.s2-tile:hover{outline:2px solid #93a1ae}
.s2-tile.on{outline:2px solid #FF3B30}
")
}

s2_inspector_js <- function(src, caption, labels, lat, lon, score, matched) {

  # One entry per detection, each carrying one crop per view. `I()` keeps the
  # url list an array even when a single view makes it length one, so the panel
  # loop on the other side does not have to special-case it.
  #
  # The scalars ride along for the gallery, which reads this same array rather
  # than being handed its own copy — a second copy of the crops would double a
  # file that is already mostly pixels.
  items <- jsonlite::toJSON(
    lapply(seq_along(caption), function(i) {
      list(urls    = I(unname(vapply(src, `[`, character(1), i))),
           meta    = caption[i],
           lat     = lat[i],
           lon     = lon[i],
           score   = score[i],
           matched = isTRUE(matched[i]))
    }),
    auto_unbox = TRUE, na = "null", digits = 8
  )

  sprintf("
function(el, x) {

  var items = %s, views = %s, at = 0;

  var box = document.createElement('div');
  box.className = 's2-lb';
  box.innerHTML =
    '<div class=\"s2-lb-card\">' +
      '<div class=\"s2-lb-head\"><span class=\"s2-lb-count\"></span>' +
        '<button class=\"s2-nav\" data-d=\"-1\" title=\"Previous\">&lsaquo;</button>' +
        '<button class=\"s2-nav\" data-d=\"1\" title=\"Next\">&rsaquo;</button>' +
        '<button class=\"s2-close\" title=\"Close\">&times;</button></div>' +
      '<div class=\"s2-frames\">' + views.map(function(v) {
        // one line, deliberately: `return` on its own line would be a bare
        // `return;` after automatic semicolon insertion, and every panel
        // would come back undefined
        return '<div><div class=\"s2-label\">' + v + '</div>' +
               '<div class=\"s2-frame\"><img alt=\"Sentinel-2 crop\">' +
               '<div class=\"s2-x\"><i></i></div></div></div>';
      }).join('') +
      '</div>' +
      '<div class=\"s2-lb-meta\"></div>' +
    '</div>';
  document.body.appendChild(box);

  var imgs  = box.querySelectorAll('.s2-frame img'),
      meta  = box.querySelector('.s2-lb-meta'),
      count = box.querySelector('.s2-lb-count');

  function show(i) {
    if (!items.length) return;
    at = (i %% items.length + items.length) %% items.length;
    for (var k = 0; k < imgs.length; k++) {
      var u = items[at].urls[k];
      imgs[k].src = u || '';
      imgs[k].style.visibility = u ? 'visible' : 'hidden';
    }
    meta.innerHTML = items[at].meta;
    count.textContent = (at + 1) + ' / ' + items.length;
    box.classList.add('on');
  }

  function hide() {
    box.classList.remove('on');
    for (var k = 0; k < imgs.length; k++) imgs[k].src = '';
  }

  document.addEventListener('click', function(e) {
    var a = e.target.closest && e.target.closest('a.s2-thumb');
    if (!a || !el.contains(a)) return;
    e.preventDefault();
    show(parseInt(a.getAttribute('data-i'), 10));
  });

  box.addEventListener('click', function(e) {
    if (e.target === box || e.target.classList.contains('s2-close')) hide();
    var nav = e.target.closest && e.target.closest('.s2-nav');
    if (nav) show(at + parseInt(nav.getAttribute('data-d'), 10));
  });

  document.addEventListener('keydown', function(e) {
    if (!box.classList.contains('on')) return;
    if (e.key === 'Escape')     hide();
    if (e.key === 'ArrowRight') show(at + 1);
    if (e.key === 'ArrowLeft')  show(at - 1);
  });

  // Published for the gallery hook, which runs after this one on the same
  // element. Sharing the array is what keeps the crops from being sent twice.
  el.__s2 = { items: items, show: show, hide: hide };
}", items, jsonlite::toJSON(labels))
}

# The second pane, added to the exported page only.
#
# It reads the viewer's own item array off the element rather than being handed
# its own — the thumbnails are the crops the page already carries, so a gallery
# of two hundred of them adds a few hundred bytes of markup and no pixels at all.
#
# The shell is fixed to the viewport because a standalone widget page has no
# layout to inherit: htmlwidgets leaves the map at an inline height and lets its
# fill CSS stretch it, which a flex parent would fight. Taking the viewport
# outright and moving the map into the left half is simpler than negotiating.
s2_gallery_js <- function() {
  "
function(el, x) {

  var api = el.__s2;
  if (!api || !api.items.length) return;
  var items = api.items, map = this;

  var shell = document.createElement('div');
  shell.className = 's2-dash';
  shell.innerHTML = '<div class=\"s2-dash-map\"></div>' +
                    '<div class=\"s2-dash-side\">' +
                      '<div class=\"s2-side-head\"><b>' + items.length + '</b> detections' +
                      '<span>by detection score</span></div>' +
                      '<div class=\"s2-grid\"></div>' +
                    '</div>';
  document.body.appendChild(shell);

  shell.querySelector('.s2-dash-map').appendChild(el);
  el.classList.remove('html-fill-item');
  el.style.width = '100%';
  el.style.height = '100%';
  map.invalidateSize();

  var grid = shell.querySelector('.s2-grid');
  grid.innerHTML = items.map(function(it, i) {
    return '<button class=\"s2-tile' + (it.matched ? ' matched' : '') + '\" data-i=\"' + i +
           '\" title=\"score ' + it.score.toFixed(2) + '\">' +
           (it.urls[0] ? '<img src=\"' + it.urls[0] + '\" alt=\"\">' : '<span class=\"s2-nope\"></span>') +
           '<span class=\"s2-ring\"></span>' +
           '<span class=\"s2-score\">' + it.score.toFixed(2) + '</span></button>';
  }).join('');

  var tiles = grid.querySelectorAll('.s2-tile'), current = -1;

  function select(i, scroll) {
    if (current > -1 && tiles[current]) tiles[current].classList.remove('on');
    current = i;
    if (i < 0 || !tiles[i]) return;
    tiles[i].classList.add('on');
    if (scroll) tiles[i].scrollIntoView({ block: 'center' });
  }

  // Markers are found by position rather than by insertion order, which leaflet
  // does not promise to preserve when iterating its layers.
  var key = function(a, b) { return a.toFixed(5) + ',' + b.toFixed(5); };
  var markerAt = {}, indexAt = {};
  map.eachLayer(function(l) {
    if (l.getLatLng && l.setStyle) { var p = l.getLatLng(); markerAt[key(p.lat, p.lng)] = l; }
  });
  items.forEach(function(it, i) { indexAt[key(it.lat, it.lon)] = i; });

  grid.addEventListener('click', function(e) {
    var t = e.target.closest && e.target.closest('.s2-tile');
    if (!t) return;
    var i = parseInt(t.getAttribute('data-i'), 10), it = items[i];
    select(i, false);
    map.setView([it.lat, it.lon], Math.max(map.getZoom(), 11));
    var mk = markerAt[key(it.lat, it.lon)];
    if (mk) mk.openPopup();
    api.show(i);
  });

  // The other direction: whichever detection the map is showing, the gallery
  // scrolls to it, so the two panes are never describing different things.
  map.on('popupopen', function(e) {
    var p = e.popup.getLatLng();
    if (!p) return;
    var i = indexAt[key(p.lat, p.lng)];
    if (i != null) select(i, true);
  });
}"
}

# saveWidget(selfcontained = TRUE) shells out to pandoc. Quarto ships a copy but
# does not put it on R's path, so a knitr chunk that would otherwise be fine
# fails at export time. Point rmarkdown at Quarto's copy when nothing else is
# findable.
ensure_pandoc <- function() {
  if (!requireNamespace("rmarkdown", quietly = TRUE)) return(invisible(FALSE))
  if (rmarkdown::pandoc_available()) return(invisible(TRUE))
  dirs  <- file.path(Sys.getenv("QUARTO_BIN_PATH"), "tools", c(R.version$arch, ""))
  found <- dirs[file.exists(file.path(dirs, "pandoc"))]
  if (length(found) > 0) rmarkdown::find_pandoc(dir = found[[1]])
  invisible(rmarkdown::pandoc_available())
}
