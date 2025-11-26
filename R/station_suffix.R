#' Get Station Suffix from Depth Strata
#'
#' Converts depth strata to standardized station suffixes for consistent station ID creation.
#'
#' @param depth_strata Character vector of depth strata from stratify()
#' @return Character vector of station suffixes
#' @details
#' Standard suffix mapping:
#' - surface: "00m"
#' - supershallow: "05m"
#' - shallow: "10m"
#' - deep: "20m"
#' - superdeep: "30m"
#' @examples
#' \dontrun{
#' # Basic usage
#' depths <- c(0, 3, 8, 15, 25, 35)
#' strata <- stratify(depths)
#' station_suffix(strata)
#' # Returns: "00m" "05m" "10m" "20m" "20m" "30m"
#'
#' # Complete workflow
#' survey_data$depth_strata <- stratify(survey_data$station_depth_m)
#' survey_data$station_suffix <- station_suffix(survey_data$depth_strata)
#' }
#' @export
station_suffix <- function(depth_strata) {
  # Standard suffix mapping
  suffix_map <- c("surface"      = "00m",
                  "supershallow" = "05m",
                  "shallow"      = "10m",
                  "deep"         = "20m",
                  "superdeep"    = "30m")

  # Convert strata to suffixes
  result <- suffix_map[depth_strata]

  # Handle any unmatched values
  unmatched <- is.na(result) & !is.na(depth_strata)
  if (any(unmatched)) {
    warning("Unknown depth strata found: ",
            paste(unique(depth_strata[unmatched]), collapse = ", "))
  }

  return(as.character(result))
}
