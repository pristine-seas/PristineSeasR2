# map_utils.R ---------------------------------------------------------------
# Shared internal leaflet building blocks for Pristine Seas interactive maps
# (used by explore_benthic_cover() and explore_uvs_sites()), so their satellite-basemap
# "chrome" and title-banner export pattern stay identical without duplicating
# the same ~20 lines in every map-building function.
#
# Nothing in this file is exported — these are implementation details shared
# across the package's map functions, not part of the public API.

# Satellite tiles + mouse-coordinate readout + fullscreen control + scale bar,
# then repositions the zoom control to bottom-left (leaflet(zoomControl=FALSE)
# is expected upstream, since the zoom control has to be re-added after the
# other bottom-left controls or it ends up stacked in the wrong order)
add_ps_map_chrome <- function(m, tiles_group = "Satellite") {
  m <- leaflet::addProviderTiles(m, leaflet::providers$Esri.WorldImagery, group = tiles_group)
  m <- leafem::addMouseCoordinates(
    m,
    css = list(
      position = "absolute", bottom = "8px", left = "50%",
      transform = "translateX(-50%)", "z-index" = "800",
      "border-radius" = "6px", padding = "3px 12px", "font-size" = "12px",
      "background-color" = "rgba(255,255,255,0.88)",
      "box-shadow" = "0 1px 4px rgba(0,0,0,.3)",
      "white-space" = "nowrap", color = "#1a1a1a"
    )
  )
  m <- leaflet.extras::addFullscreenControl(m, position = "bottomleft")
  m <- leaflet::addScaleBar(m, position = "bottomleft")
  htmlwidgets::onRender(m, "function(el, x) { L.control.zoom({ position: 'bottomleft' }).addTo(this); }")
}

# The `.map-title` banner CSS, identical across every Pristine Seas map —
# each map's own popup_css interpolates this alongside its own popup-specific
# rules, since the popup card styles themselves differ map to map
ps_map_title_css <- function() {
  "
  .map-title{font:800 27px/1.1 -apple-system,system-ui,Segoe UI,Roboto,sans-serif;
    color:#0b3d5c;background:rgba(255,255,255,.94);padding:14px 22px;border-radius:12px;
    box-shadow:0 3px 14px rgba(0,0,0,.35);border-left:6px solid #0072B2;letter-spacing:.2px}
  .map-title small{display:block;font-weight:600;font-size:13px;letter-spacing:.05em;
    text-transform:uppercase;color:#5b6b78;margin-top:5px}
  "
}

# Saves a standalone, self-contained copy of `m` with a title banner added —
# the banner goes only on this exported copy, never on the widget a caller
# displays inline, since an inline report already has its own section heading
export_ps_map <- function(m, title, subtitle, export_path) {
  m_export <- leaflet::addControl(
    m,
    html = sprintf("<div class='map-title'>%s%s</div>", title,
                   if (nzchar(subtitle)) paste0("<small>", subtitle, "</small>") else ""),
    position = "topleft", className = "map-title-ctl"
  )
  htmlwidgets::saveWidget(m_export, export_path, selfcontained = TRUE, title = title)
  invisible(export_path)
}
