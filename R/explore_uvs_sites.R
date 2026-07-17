# explore_uvs_sites.R -----------------------------------------------------------------
# Interactive UVS site map (color-by region/subregion/habitat/exposure)
#
# Public API:
#   - explore_uvs_sites(): builds the leaflet widget used across UVS site reports,
#     so it looks identical expedition to expedition without re-deriving
#     palettes/popups/layout each time
#
# Internal helpers: none exported/documented; formatting closures (levels_of(),
# pal_for(), build_popups(), legend_html(), add_sites_layer()) live inside the
# function body for the same reason as in explore_benthic_cover(). The satellite
# "chrome" and title-banner export pattern are shared via map_utils.R.

#' Build the Interactive UVS Sites Map (Color-By Region/Subregion/Habitat/Exposure)
#'
#' @description
#' Builds the standard Pristine Seas UVS site map: one marker per site, with
#' a "Color by" toggle (top right) to recolor markers by region, subregion,
#' habitat, or exposure, a rich popup (location, habitat, exposure, survey
#' date, MPA status, notes), and a search box (top left) to jump to a site
#' by ID or name. This is the same map used across UVS site reports, so
#' calling it with the standard habitat/exposure palettes reproduces the
#' exact same look expedition to expedition.
#'
#' @param sites A site-level data frame (one row per site), such as the
#'   validated UVS sites table. Must include `ps_site_id`, `longitude`,
#'   `latitude`, `region`, `subregion`, `habitat`, and `exposure`. Optional
#'   columns used in the popup if present: `site_name`, `locality`, `date`,
#'   `time`, `in_mpa`, `mpa_notes`, `notes`.
#' @param region_palette,subregion_palette Named character vectors mapping
#'   each region/subregion name to a hex color. Expedition-specific (region
#'   and subregion names differ every expedition), so there's no default —
#'   define these once in the expedition's setup script.
#' @param habitat_palette,exposure_palette Named character vectors mapping
#'   each habitat/exposure category to a hex color. Default to
#'   [ps_colors()]'s `"uvs_habitats"` and `"exposure"` palettes, which are
#'   fixed taxonomies shared across every expedition. A level with no color
#'   in the supplied palette gets a generated fallback color (with a
#'   warning) rather than failing.
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
#' m <- explore_uvs_sites(
#'   sites             = uvs_sites,
#'   region_palette    = region_palette,
#'   subregion_palette = subregion_palette,
#'   title             = "Vanuatu 2025 Expedition — Underwater Visual Survey sites",
#'   export_path       = file.path(data_out, "dive_site_map.html")
#' )
#' m
#' }
#'
#' @export
explore_uvs_sites <- function(sites,
                          region_palette,
                          subregion_palette,
                          habitat_palette  = ps_colors("uvs_habitats"),
                          exposure_palette = ps_colors("exposure"),
                          title       = NULL,
                          subtitle    = "National Geographic Pristine Seas",
                          export_path = NULL) {

  required_cols <- c("ps_site_id", "longitude", "latitude",
                      "region", "subregion", "habitat", "exposure")
  missing_cols <- setdiff(required_cols, names(sites))
  if (length(missing_cols) > 0) {
    stop("`sites` is missing required column(s): ",
         paste(missing_cols, collapse = ", "), call. = FALSE)
  }
  if (!is.null(export_path) && is.null(title)) {
    stop("`title` is required when `export_path` is supplied.", call. = FALSE)
  }

  sites_sf <- sf::st_as_sf(sites, coords = c("longitude", "latitude"), crs = 4326, remove = FALSE)

  # ---- Palettes — one per color-by layer --------------------------------------
  levels_of <- function(x) sort(unique(as.character(x[!is.na(x) & nzchar(trimws(as.character(x)))])))

  palette_sets <- list(region = region_palette, subregion = subregion_palette,
                       habitat = habitat_palette, exposure = exposure_palette)

  pal_for <- function(x, key) {
    lv   <- levels_of(x)
    base <- palette_sets[[key]]

    if (!is.null(names(base)) && all(nzchar(names(base)))) {
      # named palette: match color to level BY NAME
      cols <- base[lv]
      unmatched <- lv[is.na(cols)]
      if (length(unmatched) > 0) {
        cols[is.na(cols)] <- grDevices::hcl.colors(length(unmatched), "Spectral")
        warning("No named color defined for: ", paste(unmatched, collapse = ", "),
                " (palette: ", key, ") — using generated fallback colors.")
      }
      names(cols) <- lv
    } else {
      # unnamed palette: assign positionally in sorted-level order
      cols <- if (length(lv) <= length(base)) base[seq_along(lv)]
              else grDevices::hcl.colors(length(lv), "Spectral")
    }

    leaflet::colorFactor(cols, domain = lv, na.color = "#BDBDBD")
  }

  pal_region    <- pal_for(sites$region,    "region")
  pal_subregion <- pal_for(sites$subregion, "subregion")
  pal_habitat   <- pal_for(sites$habitat,   "habitat")
  pal_exposure  <- pal_for(sites$exposure,  "exposure")

  # ---- Popups ------------------------------------------------------------------
  popup_css <- htmltools::tags$style(htmltools::HTML(paste0("
    .ps-pop{font:13px/1.5 -apple-system,system-ui,Segoe UI,Roboto,sans-serif;color:#1a1a1a;min-width:215px;max-width:290px}
    .ps-pop .eyebrow{font-size:11px;letter-spacing:.06em;text-transform:uppercase;color:#0072B2;font-weight:600}
    .ps-pop .title{font-size:15px;font-weight:700;margin:1px 0 7px;line-height:1.25}
    .ps-pop .pill{display:inline-block;font-size:11px;font-weight:600;padding:2px 9px;border-radius:999px;margin:0 0 8px}
    .ps-pop .pill.in{background:#dcfce7;color:#166534}
    .ps-pop .pill.out{background:#f1f5f9;color:#64748b}
    .ps-pop table{border-collapse:collapse;width:100%}
    .ps-pop td{padding:2px 0;vertical-align:top}
    .ps-pop .k{color:#6b7280;padding-right:14px;white-space:nowrap;width:1%}
    .ps-pop .v{font-weight:500}
    .ps-pop .coord{margin-top:7px;padding-top:7px;border-top:1px solid #ececec;color:#374151;font-variant-numeric:tabular-nums}
    .ps-pop .notes{margin-top:6px;color:#4b5563;font-style:italic}
    /* layer toggle: single Color-by heading + roomy options */
    .leaflet-control-layers{font-size:14px;padding:10px 14px 10px 12px;border-radius:8px}
    .leaflet-control-layers-base::before{content:'Color by';display:block;font-weight:700;
      font-size:12px;text-transform:uppercase;letter-spacing:.05em;color:#0b3d5c;margin:0 0 7px}
    .leaflet-control-layers-list{line-height:2}
    .leaflet-control-layers label{font-size:14px;font-weight:500;display:flex;align-items:center}
    .leaflet-control-layers input[type=radio]{transform:scale(1.25);margin-right:9px}
    /* colour legend container */
    #layer-legend{padding:12px 15px;border-radius:8px;line-height:1.35}
    /* search control: match the rest of the chrome */
    .leaflet-control-search{border-radius:8px}
  ", ps_map_title_css())))

  build_popups <- function(d) {
    if (inherits(d, "sf")) d <- sf::st_drop_geometry(d)
    g   <- function(col) if (col %in% names(d)) d[[col]] else rep(NA, nrow(d))
    txt <- function(x) { x <- as.character(x); ifelse(is.na(x) | !nzchar(trimws(x)), NA, trimws(x)) }
    ps_id   <- txt(g("ps_site_id")); name <- txt(g("site_name"))
    region  <- txt(g("region")); subreg <- txt(g("subregion")); local <- txt(g("locality"))
    habitat <- txt(g("habitat")); exposure <- txt(g("exposure"))
    mpa_notes <- txt(g("mpa_notes")); notes <- txt(g("notes"))
    in_mpa  <- toupper(txt(g("in_mpa")))
    lat <- as.numeric(g("latitude")); lon <- as.numeric(g("longitude"))
    d_date <- g("date"); if (!inherits(d_date, "Date")) d_date <- as.Date(as.character(d_date))
    d_time <- sub("^(\\d{1,2}:\\d{2}).*", "\\1", as.character(g("time")))
    row  <- function(k, v) ifelse(is.na(v), "",
      sprintf("<tr><td class='k'>%s</td><td class='v'>%s</td></tr>", k, htmltools::htmlEscape(v)))
    crumb <- function(...) { p <- c(...); p <- p[!is.na(p)]
      if (length(p)) paste(p, collapse = " › ") else NA }
    when  <- ifelse(is.na(d_date), NA,
               paste0(format(d_date, "%d %b %Y"), ifelse(is.na(d_time), "", paste0(" · ", d_time))))
    coord <- sprintf("%.4f° %s, %.4f° %s",
                     abs(lat), ifelse(lat >= 0, "N", "S"),
                     abs(lon), ifelse(lon >= 0, "E", "W"))
    pill  <- ifelse(is.na(in_mpa), "",
               ifelse(in_mpa %in% c("YES", "TRUE", "Y", "1", "IN"),
                      "<span class='pill in'>Inside MPA</span>",
                      "<span class='pill out'>Outside MPA</span>"))
    vapply(seq_len(nrow(d)), function(i) {
      header <- if (!is.na(name[i])) name[i] else if (!is.na(ps_id[i])) ps_id[i] else "Dive site"
      rows <- paste0(
        row("Location", crumb(region[i], subreg[i], local[i])),
        row("Habitat",  habitat[i]),
        row("Exposure", exposure[i]),
        row("Surveyed", when[i]),
        row("MPA note", mpa_notes[i])
      )
      paste0(
        "<div class='ps-pop'>",
        if (!is.na(ps_id[i]) && !is.na(name[i])) paste0("<div class='eyebrow'>", htmltools::htmlEscape(ps_id[i]), "</div>") else "",
        "<div class='title'>", htmltools::htmlEscape(header), "</div>",
        pill[i],
        "<table>", rows, "</table>",
        "<div class='coord'>", coord[i], "</div>",
        if (!is.na(notes[i])) paste0("<div class='notes'>", htmltools::htmlEscape(notes[i]), "</div>") else "",
        "</div>"
      )
    }, character(1))
  }
  popup_sites <- build_popups(sites_sf)

  # search text shown on hover AND matched against when typing in the search box
  g_chr <- function(col) if (col %in% names(sites)) as.character(sites[[col]]) else rep(NA_character_, nrow(sites))
  search_label <- paste0(sites$ps_site_id, " — ",
                         dplyr::coalesce(g_chr("site_name"), g_chr("locality"), "Unnamed site"))

  # ---- One legend per color-by group, swapped in client-side on switch --------
  legend_html <- function(lbl, pal, values) {
    lv   <- levels_of(values)
    cols <- pal(lv)
    items <- paste0(
      "<div style='display:flex;align-items:center;margin:4px 0;font-size:14px'>",
      "<span style='background:", cols,
      ";width:18px;height:18px;border-radius:4px;display:inline-block;margin-right:10px;flex:0 0 auto'></span>",
      "<span>", htmltools::htmlEscape(lv), "</span></div>", collapse = "")
    paste0("<div style='font-weight:700;font-size:15px;margin-bottom:7px'>", htmltools::htmlEscape(lbl), "</div>", items)
  }
  legends <- list(
    "Region"    = legend_html("Region",    pal_region,    sites$region),
    "Subregion" = legend_html("Subregion", pal_subregion, sites$subregion),
    "Habitat"   = legend_html("Habitat",   pal_habitat,   sites$habitat),
    "Exposure"  = legend_html("Exposure",  pal_exposure,  sites$exposure)
  )
  default_group <- "Region"

  add_sites_layer <- function(map, group, palfun, var) {
    leaflet::addCircleMarkers(
      map, group = group,
      lng = ~longitude, lat = ~latitude,
      radius = 7, stroke = TRUE, color = "white", weight = 1,
      fillColor = palfun(sites[[var]]), fillOpacity = 0.9,
      popup = popup_sites, label = search_label
    )
  }

  # ---- Map ----------------------------------------------------------------------
  m <- leaflet::leaflet(sites_sf, options = leaflet::leafletOptions(zoomControl = FALSE)) |>
    add_sites_layer("Region",    pal_region,    "region") |>
    add_sites_layer("Subregion", pal_subregion, "subregion") |>
    add_sites_layer("Habitat",   pal_habitat,   "habitat") |>
    add_sites_layer("Exposure",  pal_exposure,  "exposure") |>
    leaflet::hideGroup(c("Subregion", "Habitat", "Exposure")) |>
    leaflet::showGroup(default_group) |>
    # invisible, always-on layer dedicated to search: the four groups above
    # each contain the same sites once per "color by" mode, so targeting all
    # of them would return the same site 4x per search; targeting just one
    # visible group would break search whenever that group is toggled off.
    # A single hidden group sidesteps both problems.
    leaflet::addCircleMarkers(
      group = "search_index",
      lng = ~longitude, lat = ~latitude,
      radius = 10, stroke = FALSE, fillOpacity = 0,
      popup = popup_sites, label = search_label
    ) |>
    leaflet::addLayersControl(
      baseGroups = c("Region", "Subregion", "Habitat", "Exposure"),
      position   = "topright",
      options    = leaflet::layersControlOptions(collapsed = FALSE)
    ) |>
    # single legend container — its contents are swapped on switch below
    leaflet::addControl(html = "<div id='layer-legend' class='info legend'></div>",
                         position = "bottomright", className = "")

  m <- add_ps_map_chrome(m)

  # search by site ID or name, matched against each marker's label text
  m <- leaflet.extras::addSearchFeatures(
    m,
    targetGroups = "search_index",
    options = leaflet.extras::searchFeaturesOptions(
      zoom                 = 15,
      openPopup            = TRUE,
      firstTipSubmit       = TRUE,
      autoCollapse         = TRUE,
      hideMarkerOnCollapse = TRUE,
      position             = "topleft",
      textPlaceholder      = "Search site ID or name..."
    )
  )

  # swap the legend on layer-group switch (client-side)
  m <- htmlwidgets::onRender(m, sprintf("
    function(el, x) {
      var map = this;
      var legends = %s;
      function setLegend(name) {
        var box = document.getElementById('layer-legend');
        if (box && legends[name]) box.innerHTML = legends[name];
      }
      setLegend('%s');
      map.on('baselayerchange', function(e) { setLegend(e.name); });
    }",
    jsonlite::toJSON(legends, auto_unbox = TRUE), default_group))

  m <- htmlwidgets::prependContent(m, popup_css)

  if (!is.null(export_path)) {
    export_ps_map(m, title, subtitle, export_path)
  }

  m
}
