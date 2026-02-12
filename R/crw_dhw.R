# crw_dhw.R --------------------------------------------------------------------
# NOAA Coral Reef Watch Degree Heating Week (DHW) via ERDDAP
#
# Public API:
#   - get_crw_dhw_bbox(): query by numeric bbox (lat/lon bounds)
#   - get_crw_dhw_sf()  : query by sf feature (bbox derived from geometry)
#
# Internal helpers (not exported / not documented):
#   - crw_dhw_url()
#   - crw_fetch_dhw()

#' Fetch NOAA CRW DHW (Degree Heating Week) for a bounding box (bbox)
#'
#' Query NOAA CoastWatch ERDDAP for NOAA Coral Reef Watch (CRW) **Degree Heating
#' Week** (DHW; units = °C-weeks) daily values within a lat/lon bounding box.
#' Requests are chunked by year to keep responses manageable and more reliable.
#'
#' Data source: ERDDAP dataset `noaacrwdhwDaily`, variable `degree_heating_week`.
#'
#' @param lat_min,lat_max Latitude bounds (decimal degrees, WGS84).
#' @param lon_min,lon_max Longitude bounds (decimal degrees, WGS84).
#' @param start,end Date range (YYYY-MM-DD or Date). `end` must be >= `start`.
#' @param timeout_sec Request timeout (seconds).
#' @param pause_sec Pause between yearly requests (seconds).
#' @param verbose If TRUE, prints progress messages per year.
#'
#' @return A tibble with columns: `date`, `latitude`, `longitude`, `dhw`.
#'
#' @examples
#' \dontrun{
#' dhw <- get_crw_dhw_bbox(
#'   lat_min = 10.0, lat_max = 10.2,
#'   lon_min = 169.4, lon_max = 169.7,
#'   start = "2015-01-01", end = "2015-12-31"
#' )
#' }
#'
#' @export
get_crw_dhw_bbox <- function(lat_min, lat_max, lon_min, lon_max,
                             start = "2015-01-01", end = "2024-12-31",
                             timeout_sec = 300,
                             pause_sec = 0.2,
                             verbose = TRUE) {

  empty <- tibble::tibble(date = as.Date(character()),
                          latitude = numeric(),
                          longitude = numeric(),
                          dhw = numeric())

  start <- as.Date(start)
  end   <- as.Date(end)
  if (end < start) stop("end must be >= start")

  years <- seq(lubridate::year(start), lubridate::year(end))

  purrr::map_dfr(years, function(y) {

    y_start <- max(start, as.Date(glue::glue("{y}-01-01")))
    y_end   <- min(end,   as.Date(glue::glue("{y}-12-31")))
    if (y_end < y_start) return(empty)

    if (isTRUE(verbose)) message(glue::glue("  Fetching {y}..."))

    url <- crw_dhw_url(lat_min = lat_min, lat_max = lat_max,
                       lon_min = lon_min, lon_max = lon_max,
                       start = y_start, end = y_end)

    Sys.sleep(pause_sec)

    tryCatch(
      crw_fetch_dhw(url, timeout_sec = timeout_sec),
      error = function(e) {
        if (isTRUE(verbose)) message(glue::glue("  Failed {y}: {conditionMessage(e)}"))
        empty
      }
    )
  })
}

#' Fetch NOAA CRW DHW for an `sf` feature's bounding box
#'
#' Convenience wrapper that:
#' 1) transforms the feature geometry to WGS84 (EPSG:4326),
#' 2) extracts its bounding box (xmin/xmax = lon, ymin/ymax = lat), and
#' 3) queries CRW DHW in yearly chunks via [get_crw_dhw_bbox()].
#'
#' By default, returns a **daily mean DHW** across all grid points in the bbox.
#' Set `summarise_daily = FALSE` to return raw gridded values (one row per grid
#' cell per day).
#'
#' @param feature A single-row `sf` object (one feature geometry).
#' @param start,end Date range (YYYY-MM-DD or Date).
#' @param name_col Name of the column in `feature` that holds the feature identifier.
#'   This column can have any name (e.g., `"atoll"`, `"name"`, `"site"`, `"reef"`, `"id"`).
#' @param out_col Name of the output column used to store the feature identifier.
#'   Default is `"feature"`. Set to `"atoll"` if you want an `atoll` column.
#' @param summarise_daily If TRUE (default), return daily mean DHW for the bbox.
#'   If FALSE, return raw gridded DHW values for the bbox.
#' @param timeout_sec Request timeout (seconds).
#' @param pause_sec Pause between yearly requests (seconds).
#' @param verbose If TRUE, prints progress messages (feature + year).
#'
#' @return
#' If `summarise_daily = TRUE`: tibble with columns `{out_col}`, `date`, `avg_dhw`.
#' If `summarise_daily = FALSE`: tibble with columns `{out_col}`, `date`, `latitude`,
#' `longitude`, `dhw`.
#'
#' @examples
#' \dontrun{
#' # AOIs is an sf object with a column identifying each feature.
#' # The identifier column does NOT need to be named "atoll".
#'
#' # ---- Example: single feature ----
#' jemo <- AOIs[AOIs$name == "Jemo", ]
#'
#' jemo_dhw <- get_crw_dhw_sf(
#'   jemo,
#'   start = "2015-01-01", end = "2024-12-31",
#'   name_col = "name",
#'   out_col  = "feature"
#' )
#'
#' # ---- Example: two features ----
#' subset <- AOIs[AOIs$name %in% c("Jemo", "Taka"), ]
#'
#' dhw_two <- purrr::map_dfr(seq_len(nrow(subset)), \(i)
#'   get_crw_dhw_sf(
#'     subset[i, ],
#'     start = "2015-01-01", end = "2024-12-31",
#'     name_col = "name",
#'     out_col  = "feature"
#'   )
#' )
#' }
#'
#' @export
get_crw_dhw_sf <- function(feature,
                           start = "2015-01-01", end = "2024-12-31",
                           name_col = "atoll",
                           out_col = "feature",
                           summarise_daily = TRUE,
                           timeout_sec = 300,
                           pause_sec = 0.2,
                           verbose = TRUE) {

  # Contract checks
  if (!inherits(feature, "sf")) stop("feature must be an sf object")
  if (nrow(feature) != 1) stop("feature must be a single-row sf object (one feature)")
  if (!name_col %in% names(feature)) stop(glue::glue("Column '{name_col}' not found in feature"))
  if (!is.character(out_col) || length(out_col) != 1 || !nzchar(out_col)) {
    stop("out_col must be a single, non-empty string")
  }

  feature <- sf::st_transform(feature, 4326)
  bb <- sf::st_bbox(feature)
  feature_name <- as.character(feature[[name_col]][1])

  if (isTRUE(verbose)) message(glue::glue("Fetching DHW for {feature_name}..."))

  dat <- get_crw_dhw_bbox(
    lat_min = bb["ymin"], lat_max = bb["ymax"],
    lon_min = bb["xmin"], lon_max = bb["xmax"],
    start = start, end = end,
    timeout_sec = timeout_sec,
    pause_sec = pause_sec,
    verbose = verbose
  )

  if (nrow(dat) == 0) {
    if (isTRUE(summarise_daily)) {
      out <- tibble::tibble(
        date = as.Date(NA),
        avg_dhw = NA_real_
      )
      out[[out_col]] <- feature_name
      return(out[, c(out_col, "date", "avg_dhw")])
    }

    out <- tibble::tibble(
      date = as.Date(character()),
      latitude = numeric(),
      longitude = numeric(),
      dhw = numeric()
    )
    out[[out_col]] <- character()
    return(out[, c(out_col, "date", "latitude", "longitude", "dhw")])
  }

  if (!isTRUE(summarise_daily)) {
    out <- dat |>
      dplyr::select(date, latitude, longitude, dhw)
    out[[out_col]] <- feature_name
    return(out[, c(out_col, "date", "latitude", "longitude", "dhw")])
  }

  out <- dat |>
    dplyr::group_by(date) |>
    dplyr::summarise(avg_dhw = mean(dhw, na.rm = TRUE), .groups = "drop")

  out[[out_col]] <- feature_name
  out[, c(out_col, "date", "avg_dhw")]
}

# ---- Internal helpers --------------------------------------------------------

#' Build an ERDDAP griddap URL for CRW DHW daily data
#' @keywords internal
#' @noRd
crw_dhw_url <- function(lat_min, lat_max, lon_min, lon_max, start, end) {

  # guardrails: catch swapped axes early
  stopifnot(abs(lat_min) <= 90, abs(lat_max) <= 90)
  stopifnot(abs(lon_min) <= 360, abs(lon_max) <= 360)

  lat0 <- min(lat_min, lat_max)
  lat1 <- max(lat_min, lat_max)
  lon0 <- min(lon_min, lon_max)
  lon1 <- max(lon_min, lon_max)

  t0 <- paste0(as.Date(start), "T12:00:00Z")
  t1 <- paste0(as.Date(end),   "T12:00:00Z")

  q <- glue::glue(
    "degree_heating_week[({t0}):1:({t1})]",
    "[({lat0}):1:({lat1})]",
    "[({lon0}):1:({lon1})]"
  )

  glue::glue(
    "https://coastwatch.noaa.gov/erddap/griddap/noaacrwdhwDaily.csv?{URLencode(q, reserved = TRUE)}"
  )
}

#' Fetch CRW DHW gridded values for a single ERDDAP URL
#' @keywords internal
#' @noRd
crw_fetch_dhw <- function(url, timeout_sec = 300) {

  txt <- httr2::request(url) |>
    httr2::req_user_agent("R/httr2 NOAA-CRW-DHW") |>
    httr2::req_timeout(timeout_sec) |>
    httr2::req_perform() |>
    httr2::resp_body_string()

  readr::read_csv(I(txt), show_col_types = FALSE, skip = 1) |>
    rlang::set_names(c("date", "latitude", "longitude", "dhw")) |>
    dplyr::transmute(
      date      = as.Date(substr(date, 1, 10)),
      latitude  = as.numeric(latitude),
      longitude = as.numeric(longitude),
      dhw       = as.numeric(dhw)
    )
}
