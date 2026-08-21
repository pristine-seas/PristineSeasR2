# explore_recruit_density.R ---------------------------------------------------
# Interactive per-site coral recruit density map (single-metric circle markers)
#
# Public API:
#   - explore_recruit_density(): builds the leaflet widget used across
#     UVS/recruits reports — one circle marker per site, with both size and
#     color driven by recruit density (recruits/m²). Taxa richness, quadrat
#     effort, and total recruit count are shown as informational rows in
#     every popup.
#
# Internal helpers: none exported/documented; the popup/legend closures live
# inside the function body since they're specific to this map. Shared
# satellite "chrome" and title-banner export come from map_utils.R, same as
# explore_uvs_sites(), explore_benthic_cover(), explore_fish_biomass(), and
# explore_invert_density().

#' Build the Interactive Recruit Density Map (Circle Markers by Site)
#'
#' @description
#' Builds the standard Pristine Seas per-site coral recruit map: station-level
#' recruit density is averaged up to one circle marker per site, with both
#' marker size and color driven by mean density (recruits/m²). Taxa richness,
#' quadrat effort, and total recruit count are shown as informational rows in
#' every popup, independent of the color/size encoding. This is the same map
#' used across UVS/recruits reports, so calling it reproduces the exact same
#' metric, colors, and layout expedition to expedition.
#'
#' @param stations A station-level data frame (one row per station), such as
#'   `recruits_stations`. Must include `ps_site_id`, `divers`, `depth_strata`,
#'   `depth_m`, `n_taxa`, `n_quadrats`, `total_count`, and `avg_density_m2`.
#' @param sites A site-level data frame with `ps_site_id`, `longitude`,
#'   `latitude`, `region`, `subregion`, `locality`, `habitat`, and `exposure`
#'   — such as the validated UVS sites table — used to attach coordinates and
#'   metadata. Every site referenced in `stations` must have a match here.
#' @param title Map title shown in the banner on the *exported* standalone
#'   map only (see `export_path`) — not shown on the version this function
#'   returns, since an inline report already has its own section heading.
#'   Required if `export_path` is supplied.
#' @param subtitle Small text under the title in the exported map's banner.
#'   Set to `""` to hide it. Default `"National Geographic Pristine Seas"`.
#' @param export_path If supplied, a self-contained standalone HTML copy of
#'   the map (with the title banner) is saved to this path via
#'   [htmlwidgets::saveWidget()]. If `NULL` (the default), nothing is saved.
#'
#' @return A `leaflet` htmlwidget (without the title banner) — print it
#'   directly to display it, e.g. as the last expression in a report chunk.
#'
#' @examples
#' \dontrun{
#' m <- explore_recruit_density(
#'   stations    = recruits_stations,
#'   sites       = uvs_sites,
#'   title       = "Vanuatu 2025 Expedition — Recruit survey results",
#'   export_path = file.path(data_out, "recruits_results_map.html")
#' )
#' m
#' }
#'
#' @importFrom rlang .data
#' @export
explore_recruit_density <- function(stations,
                                    sites,
                                    title       = NULL,
                                    subtitle    = "National Geographic Pristine Seas",
                                    export_path = NULL) {

  required_station_cols <- c("ps_site_id", "divers", "depth_strata", "depth_m",
                              "n_taxa", "n_quadrats", "total_count", "avg_density_m2")
  missing_cols <- setdiff(required_station_cols, names(stations))
  if (length(missing_cols) > 0) {
    stop("`stations` is missing required column(s): ",
         paste(missing_cols, collapse = ", "), call. = FALSE)
  }
  required_site_cols <- c("ps_site_id", "longitude", "latitude", "region",
                          "subregion", "locality", "habitat", "exposure")
  missing_site_cols <- setdiff(required_site_cols, names(sites))
  if (length(missing_site_cols) > 0) {
    stop("`sites` is missing required column(s): ",
         paste(missing_site_cols, collapse = ", "), call. = FALSE)
  }
  if (!is.null(export_path) && is.null(title)) {
    stop("`title` is required when `export_path` is supplied.", call. = FALSE)
  }

  # ---- Aggregate stations -> sites --------------------------------------------
  # n_taxa/avg_density_m2 are station-level averages, so they're averaged again
  # to site; n_quadrats/total_count are extensive counts, so they're summed
  by_site <- stations |>
    dplyr::group_by(.data$ps_site_id) |>
    dplyr::summarise(
      team           = paste(unique(.data$divers), collapse = " / "),
      strata         = paste(unique(paste0(.data$depth_strata, " (", .data$depth_m, "m)")), collapse = "\n"),
      n_taxa         = mean(.data$n_taxa, na.rm = TRUE),
      n_quadrats     = sum(.data$n_quadrats, na.rm = TRUE),
      total_count    = sum(.data$total_count, na.rm = TRUE),
      avg_density_m2 = mean(.data$avg_density_m2, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::left_join(
      unique(as.data.frame(sites)[, c("ps_site_id", "region", "subregion", "locality",
                                      "habitat", "exposure", "longitude", "latitude")]),
      by = "ps_site_id"
    )

  if (any(is.na(by_site$longitude) | is.na(by_site$latitude))) {
    stop("Some sites in `stations` have no matching coordinates in `sites`.", call. = FALSE)
  }

  num     <- function(x) suppressWarnings(as.numeric(x))
  fmt_num <- function(v, digits) ifelse(is.na(v), "\u2014",
    formatC(v, format = "f", digits = digits, big.mark = ","))

  # ---- Color + size: both driven by density -----------------------------------
  pal  <- viridisLite::viridis(256, option = "B")
  v    <- num(by_site$avg_density_m2)
  palf <- leaflet::colorNumeric(pal, domain = v, na.color = "#BDBDBD")

  scale_radius <- function(x, rmin = 5, rmax = 22) {
    x   <- num(x)
    rng <- range(x, na.rm = TRUE)
    if (!all(is.finite(rng)) || diff(rng) == 0) return(rep((rmin + rmax) / 2, length(x)))
    norm <- (x - rng[1]) / (rng[2] - rng[1]); norm[is.na(norm)] <- 0
    rmin + sqrt(norm) * (rmax - rmin)
  }

  # ---- Popups -------------------------------------------------------------------
  popup_css <- htmltools::tags$style(htmltools::HTML(paste0("
    .ps-pop{font:13px/1.5 -apple-system,system-ui,Segoe UI,Roboto,sans-serif;color:#1a1a1a;min-width:225px;max-width:300px}
    .ps-pop table{border-collapse:collapse;width:100%}
    .ps-pop td{padding:2px 0;vertical-align:top}
    .ps-pop .title{font-size:15px;font-weight:700;margin:1px 0 7px;line-height:1.25}
    .ps-pop .k{color:#6b7280;padding-right:14px;white-space:nowrap;width:1%}
    .ps-pop .v{font-weight:500}
    .ps-pop .metrics{margin-top:8px;padding-top:8px;border-top:1px solid #ececec}
    .ps-pop .metric{display:flex;justify-content:space-between;align-items:baseline;margin:3px 0}
    .ps-pop .metric .ml{color:#6b7280}
    .ps-pop .metric .mv{font-weight:700;font-variant-numeric:tabular-nums;color:#0b3d5c}
    .ps-pop .metric .mv small{font-weight:500;color:#6b7280;font-size:11px}
    .ps-pop .coord{margin-top:8px;padding-top:7px;border-top:1px solid #ececec;color:#374151;font-variant-numeric:tabular-nums}
    #layer-legend{padding:12px 15px;border-radius:8px;line-height:1.35}
  ", ps_map_title_css())))

  txt   <- function(x) { x <- as.character(x); ifelse(is.na(x) | !nzchar(trimws(x)), NA, trimws(x)) }
  crumb <- function(...) { p <- c(...); p <- p[!is.na(p)]; if (length(p)) paste(p, collapse = " \u203a ") else NA }
  row_  <- function(k, v) ifelse(is.na(v), "",
    sprintf("<tr><td class='k'>%s</td><td class='v'>%s</td></tr>", k, htmltools::htmlEscape(v)))
  metric_row <- function(label, valstr, units) sprintf(
    "<div class='metric'><span class='ml'>%s</span><span class='mv'>%s%s</span></div>",
    label, valstr, if (nzchar(units)) paste0(" <small>", units, "</small>") else "")

  popups <- vapply(seq_len(nrow(by_site)), function(i) {
    strata_i    <- txt(by_site$strata[i])
    strata_html <- if (!is.na(strata_i)) gsub("\n", "<br>", htmltools::htmlEscape(strata_i)) else NA
    rows <- paste0(
      row_("Location", crumb(txt(by_site$region[i]), txt(by_site$subregion[i]), txt(by_site$locality[i]))),
      row_("Habitat",  txt(by_site$habitat[i])),
      row_("Exposure", txt(by_site$exposure[i])),
      row_("Team",     txt(by_site$team[i])),
      if (!is.na(strata_html))
        sprintf("<tr><td class='k'>Depth strata</td><td class='v'>%s</td></tr>", strata_html) else ""
    )
    mblock <- paste0(
      "<div class='metrics'>",
      metric_row("Density",        fmt_num(by_site$avg_density_m2[i], 2), "recruits/m\u00b2"),
      metric_row("Taxa richness",  fmt_num(by_site$n_taxa[i], 0),         ""),
      metric_row("Quadrats",       fmt_num(by_site$n_quadrats[i], 0),     ""),
      metric_row("Total recruits", fmt_num(by_site$total_count[i], 0),    ""),
      "</div>")
    coord <- sprintf("%.4f\u00b0 %s, %.4f\u00b0 %s",
                     abs(by_site$latitude[i]),  ifelse(by_site$latitude[i]  >= 0, "N", "S"),
                     abs(by_site$longitude[i]), ifelse(by_site$longitude[i] >= 0, "E", "W"))
    paste0(
      "<div class='ps-pop'>",
      "<div class='title'>", htmltools::htmlEscape(by_site$ps_site_id[i]), "</div>",
      "<table>", rows, "</table>",
      mblock,
      "<div class='coord'>", coord, "</div>",
      "</div>"
    )
  }, character(1))

  # ---- Gradient legend (single metric, no toggle needed) ----------------------
  rng   <- range(v, na.rm = TRUE)
  stops <- pal[round(seq(1, length(pal), length.out = 10))]
  grad  <- paste(stops, collapse = ",")
  ticks <- seq(rng[2], rng[1], length.out = 5)
  tick_html <- paste0("<span>", vapply(ticks, function(t) fmt_num(t, 2), character(1)),
                      "</span>", collapse = "")
  legend_html <- paste0(
    "<div style='font-weight:700;font-size:15px;margin-bottom:8px'>Density (recruits/m\u00b2)</div>",
    "<div style='display:flex;gap:9px;align-items:stretch'>",
      "<div style='width:16px;height:130px;border-radius:3px;",
      "background:linear-gradient(to top,", grad, ")'></div>",
      "<div style='display:flex;flex-direction:column;justify-content:space-between;",
      "font-size:13px;font-variant-numeric:tabular-nums'>", tick_html, "</div>",
    "</div>",
    "<div style='margin-top:9px;font-size:11px;color:#6b7280;display:flex;align-items:flex-end;gap:5px'>",
      "<span style='width:7px;height:7px;border-radius:50%;background:#9aa2ad;display:inline-block'></span>",
      "<span style='width:13px;height:13px;border-radius:50%;background:#9aa2ad;display:inline-block'></span>",
      "<span style='margin-left:3px'>point size \u221d value</span>",
    "</div>"
  )

  # ---- Map ----------------------------------------------------------------------
  m <- leaflet::leaflet(options = leaflet::leafletOptions(zoomControl = FALSE)) |>
    leaflet::addCircleMarkers(
      data = by_site,
      lng = ~longitude, lat = ~latitude,
      radius = scale_radius(v), stroke = TRUE, color = "white", weight = 1,
      fillColor = palf(v), fillOpacity = 0.85,
      popup = popups,
      label = paste0(by_site$ps_site_id, "  |  Density: ", fmt_num(v, 2), " recruits/m\u00b2")
    ) |>
    leaflet::addControl(html = paste0("<div id='layer-legend' class='info legend'>", legend_html, "</div>"),
                        position = "bottomright", className = "")

  m <- add_ps_map_chrome(m)
  m <- leaflet::fitBounds(m, min(by_site$longitude), min(by_site$latitude),
                           max(by_site$longitude), max(by_site$latitude))

  m <- htmlwidgets::prependContent(m, popup_css)

  if (!is.null(export_path)) {
    export_ps_map(m, title, subtitle, export_path)
  }

  m
}
