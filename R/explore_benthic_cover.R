# explore_benthic_cover.R ------------------------------------------------------------
# Interactive per-site benthic cover map (pie charts on a satellite basemap)
#
# Public API:
#   - explore_benthic_cover(): builds the leaflet + leaflet.minicharts widget used
#     across UVS/LPI benthic reports, so it looks identical expedition to
#     expedition without re-deriving colors/popups/layout each time
#   - default_benthic_cover_groups(): the standard group/column/color mapping,
#     exported so a caller can start from it when building a custom variant
#
# Internal helpers: none exported/documented; small formatting closures
# (txt(), row_(), crumb()) live inside the function body since their names
# are generic enough that promoting them to package-level internals would
# risk colliding with something else in the package later. The satellite
# "chrome" (tiles/mouse-coords/fullscreen/scale bar) and the title-banner
# export pattern are shared with explore_uvs_sites() via map_utils.R instead.

#' Standard Benthic Cover Groups for `explore_benthic_cover()`
#'
#' @description
#' The default `group` / `cols` / `color` mapping used by
#' [explore_benthic_cover()]. Returned as data so you can start from it when
#' building a custom `cover_groups` table (e.g. `dplyr::filter()` out a group,
#' or `dplyr::mutate()` in a different color) rather than writing one from
#' scratch.
#'
#' @return A tibble with columns `group` (display name), `cols` (one or more
#'   source column names, comma-separated), and `color` (hex color).
#'
#' @seealso [explore_benthic_cover()]
#'
#' @export
default_benthic_cover_groups <- function() {
  tibble::tribble(
    ~group,             ~cols,                              ~color,
    "Hard coral",       "pct_coral",                        "#FFD51C",
    "Soft coral",       "pct_soft_coral",                   "#512E98",
    "CCA",              "pct_cca",                          "#DD207E",
    "Encrusting algae", "pct_algae_encrust",                "#51C7B8",
    "Macroalgae",       "pct_algae_erect,pct_algae_canopy", "#1E9B49",
    "Turf / EAM",       "pct_turf,pct_eam",                 "#5F5739",
    "Cyanobacteria",    "pct_cyano",                        "#3E243E",
    "Sponges",          "pct_sponges",                      "#2B7BDD",
    "Seagrass",         "pct_seagrass",                     "#9ACD32",
    "Rubble",           "pct_rubble",                       "#BBB38B",
    "Other",            "pct_other",                        "#818CAF"
  )
}

#' Build the Interactive Benthic Cover Map (Pie Charts by Site)
#'
#' @description
#' Builds the standard Pristine Seas per-site benthic cover map: station-level
#' percent cover is averaged up to one site, then shown as a pie chart on a
#' satellite basemap, with a rich popup (location, habitat, exposure, station
#' count, dive team) and a legend of functional-group colors. This is the
#' same map used across UVS/LPI benthic reports, so calling it with the
#' default `cover_groups` reproduces the exact same groups, colors, and
#' layout expedition to expedition.
#'
#' @param stations A station-level data frame (one row per station), such as
#'   `lpi_stations`. Must include `ps_site_id`, `region`, `subregion`,
#'   `locality`, `habitat`, `exposure`, `divers`, and the percent-cover
#'   columns referenced by `cover_groups$cols`. A cover column that's missing
#'   entirely is treated as 0 for that group, so a protocol that doesn't
#'   track every group still works.
#' @param sites A site-level data frame with `ps_site_id`, `longitude`, and
#'   `latitude` — such as the validated UVS sites table — used to attach
#'   coordinates. Every site referenced in `stations` must have a match here.
#' @param title Map title shown in the banner on the *exported* standalone
#'   map only (see `export_path`) — not shown on the version this function
#'   returns, since an inline report already has its own section heading.
#'   Required if `export_path` is supplied.
#' @param subtitle Small text under the title in the exported map's banner.
#'   Set to `""` to hide it. Default `"National Geographic Pristine Seas"`.
#' @param export_path If supplied, a self-contained standalone HTML copy of
#'   the map (with the title banner) is saved to this path via
#'   [htmlwidgets::saveWidget()]. If `NULL` (the default), nothing is saved.
#' @param cover_groups A data frame with columns `group` (display name),
#'   `cols` (one or more `stations` column names, comma-separated, summed
#'   into this group), and `color` (hex color for the pie slice/legend).
#'   Defaults to [default_benthic_cover_groups()]; override only if a
#'   protocol's cover columns genuinely differ from the LPI standard.
#'
#' @return A `leaflet` htmlwidget (without the title banner) — print it
#'   directly to display it, e.g. as the last expression in a report chunk.
#'
#' @examples
#' \dontrun{
#' m <- explore_benthic_cover(
#'   stations    = lpi_stations,
#'   sites       = uvs_sites,
#'   title       = "Vanuatu 2025 Expedition — Benthic composition",
#'   export_path = file.path(data_out, "lpi_results_map.html")
#' )
#' m
#' }
#'
#' @importFrom rlang .data
#' @export
explore_benthic_cover <- function(stations,
                               sites,
                               title       = NULL,
                               subtitle    = "National Geographic Pristine Seas",
                               export_path = NULL,
                               cover_groups = default_benthic_cover_groups()) {

  required_station_cols <- c("ps_site_id", "region", "subregion", "locality",
                              "habitat", "exposure", "divers")
  missing_cols <- setdiff(required_station_cols, names(stations))
  if (length(missing_cols) > 0) {
    stop("`stations` is missing required column(s): ",
         paste(missing_cols, collapse = ", "), call. = FALSE)
  }
  if (!all(c("ps_site_id", "longitude", "latitude") %in% names(sites))) {
    stop("`sites` must include ps_site_id, longitude, and latitude.", call. = FALSE)
  }
  if (!is.null(export_path) && is.null(title)) {
    stop("`title` is required when `export_path` is supplied.", call. = FALSE)
  }

  df <- as.data.frame(stations)

  # ---- Build group cover per station, then aggregate stations -> sites -----
  group_names <- cover_groups$group
  for (i in seq_len(nrow(cover_groups))) {
    cols <- intersect(strsplit(cover_groups$cols[i], ",")[[1]], names(df))
    if (length(cols)) {
      # as.matrix(), not sapply(), so this stays a proper matrix (and
      # rowSums() doesn't error) even for a single station and a single
      # source column, where sapply()'s simplify-to-vector behavior would
      # otherwise collapse it to a bare scalar with no dimensions
      mat <- as.matrix(df[cols])
      storage.mode(mat) <- "numeric"
      df[[group_names[i]]] <- rowSums(mat, na.rm = TRUE)
    } else {
      df[[group_names[i]]] <- 0
    }
  }

  first_chr <- function(x) { x <- x[!is.na(x)]; if (length(x)) as.character(x[1]) else NA_character_ }
  split_divers <- function(x) {
    parts <- unlist(strsplit(as.character(x), "\\s*[|;/]\\s*"))
    parts <- unique(trimws(parts[!is.na(parts) & nzchar(trimws(parts))]))
    if (length(parts)) paste(parts, collapse = ", ") else NA_character_
  }

  by_site <- df |>
    dplyr::group_by(.data$ps_site_id) |>
    dplyr::summarise(
      region     = first_chr(.data$region),   subregion = first_chr(.data$subregion),
      locality   = first_chr(.data$locality), habitat   = first_chr(.data$habitat),
      exposure   = first_chr(.data$exposure),
      n_stations = dplyr::n(),
      divers     = split_divers(paste(.data$divers, collapse = " | ")),
      dplyr::across(dplyr::all_of(group_names), ~ mean(.x, na.rm = TRUE)),
      .groups = "drop"
    )

  # ---- Attach coordinates -----------------------------------------------------
  coords  <- dplyr::distinct(as.data.frame(sites)[, c("ps_site_id", "longitude", "latitude")])
  by_site <- dplyr::left_join(by_site, coords, by = "ps_site_id")
  if (any(is.na(by_site$longitude) | is.na(by_site$latitude))) {
    stop("Some sites in `stations` have no matching coordinates in `sites`.", call. = FALSE)
  }

  # ---- Drop all-zero groups; align colours ------------------------------------
  keep      <- group_names[vapply(group_names, function(g) sum(by_site[[g]], na.rm = TRUE) > 0.01, logical(1))]
  colors    <- cover_groups$color[match(keep, cover_groups$group)]
  chartdata <- as.data.frame(by_site[, keep, drop = FALSE])

  # ---- Popups ------------------------------------------------------------------
  popup_css <- htmltools::tags$style(htmltools::HTML(paste0("
    .ps-pop{font:13px/1.5 -apple-system,system-ui,Segoe UI,Roboto,sans-serif;color:#1a1a1a;min-width:235px;max-width:300px}
    .ps-pop .title{font-size:15px;font-weight:700;margin:0 0 7px;line-height:1.25}
    .ps-pop table{border-collapse:collapse;width:100%}
    .ps-pop td{padding:2px 0;vertical-align:top}
    .ps-pop .k{color:#6b7280;padding-right:14px;white-space:nowrap;width:1%}
    .ps-pop .v{font-weight:500}
    .ps-pop .comp{margin-top:8px;padding-top:8px;border-top:1px solid #ececec}
    .ps-pop .comp .ch{font-weight:700;font-size:12px;text-transform:uppercase;letter-spacing:.04em;color:#0b3d5c;margin-bottom:5px}
    .ps-pop .comp .cr{display:flex;align-items:center;justify-content:space-between;margin:3px 0}
    .ps-pop .comp .cl{display:flex;align-items:center}
    .ps-pop .comp .sw{width:11px;height:11px;border-radius:2px;margin-right:8px;flex:0 0 auto}
    .ps-pop .comp .pv{font-weight:700;font-variant-numeric:tabular-nums;color:#0b3d5c}
    .ps-pop .coord{margin-top:8px;padding-top:7px;border-top:1px solid #ececec;color:#374151;font-variant-numeric:tabular-nums}
  ", ps_map_title_css())))

  txt   <- function(x) { x <- as.character(x); ifelse(is.na(x) | !nzchar(trimws(x)), NA, trimws(x)) }
  crumb <- function(...) { p <- c(...); p <- p[!is.na(p)]; if (length(p)) paste(p, collapse = " › ") else NA }
  row_  <- function(k, v) ifelse(is.na(v), "",
    sprintf("<tr><td class='k'>%s</td><td class='v'>%s</td></tr>", k, htmltools::htmlEscape(v)))

  popups <- vapply(seq_len(nrow(by_site)), function(i) {
    region <- txt(by_site$region[i]); subreg <- txt(by_site$subregion[i]); local <- txt(by_site$locality[i])
    vals   <- vapply(keep, function(g) by_site[[g]][i], numeric(1))
    ord    <- order(vals, decreasing = TRUE)
    comp   <- paste0(vapply(ord, function(j) if (vals[j] < 0.05) "" else sprintf(
        "<div class='cr'><span class='cl'><span class='sw' style='background:%s'></span>%s</span><span class='pv'>%s%%</span></div>",
        colors[j], htmltools::htmlEscape(keep[j]), formatC(vals[j], format = "f", digits = 1)),
      character(1)), collapse = "")
    rows <- paste0(
      row_("Location", crumb(region, subreg, local)),
      row_("Habitat",  txt(by_site$habitat[i])),
      row_("Exposure", txt(by_site$exposure[i])),
      row_("Stations", as.character(by_site$n_stations[i])),
      row_("Team",     txt(by_site$divers[i]))
    )
    coord <- sprintf("%.4f° %s, %.4f° %s",
                     abs(by_site$latitude[i]),  ifelse(by_site$latitude[i]  >= 0, "N", "S"),
                     abs(by_site$longitude[i]), ifelse(by_site$longitude[i] >= 0, "E", "W"))
    paste0("<div class='ps-pop'>",
           "<div class='title'>", htmltools::htmlEscape(by_site$ps_site_id[i]), "</div>",
           "<table>", rows, "</table>",
           "<div class='comp'><div class='ch'>Benthic cover</div>", comp, "</div>",
           "<div class='coord'>", coord, "</div></div>")
  }, character(1))

  # ---- Map ----------------------------------------------------------------------
  m <- leaflet::leaflet(options = leaflet::leafletOptions(zoomControl = FALSE)) |>
    leaflet.minicharts::addMinicharts(
      lng = by_site$longitude, lat = by_site$latitude,
      type = "pie", chartdata = chartdata, colorPalette = colors,
      width = 46, opacity = 0.95, transitionTime = 0,
      layerId = by_site$ps_site_id,
      popup = leaflet.minicharts::popupArgs(html = popups),
      legend = TRUE, legendPosition = "bottomright"
    )

  m <- add_ps_map_chrome(m)
  m <- leaflet::fitBounds(m, min(by_site$longitude), min(by_site$latitude),
                           max(by_site$longitude), max(by_site$latitude))
  m <- htmlwidgets::prependContent(m, popup_css)

  if (!is.null(export_path)) {
    export_ps_map(m, title, subtitle, export_path)
  }

  m
}
