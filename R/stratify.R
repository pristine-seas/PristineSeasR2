#' Stratify Depths into Standard Categories
#'
#' Converts depth measurements in meters to standardized Pristine Seas depth
#' strata categories using fixed thresholds for consistency across all projects.
#'
#' @param avg_depth_m Numeric vector. Average depth measurements in meters
#' @return Character vector with depth stratum labels: "surface", "supershallow",
#'   "shallow", "deep", "superdeep", or NA
#' @details
#' Standard Pristine Seas depth strata:
#' - Surface: exactly 0m
#' - Supershallow: 0.1 - 6m
#' - Shallow: 6.1 - 14m
#' - Deep: 14.1 - 30m
#' - Superdeep: > 30m
#' - NA: missing or invalid depth values
#' @examples
#' \dontrun{
#' # Stratify survey depths
#' depths <- c(0, 3, 8, 12, 18, 25, 35, 45)
#' stratify(depths)
#' # Returns: "surface" "supershallow" "shallow" "shallow" "deep" "deep" "superdeep" "superdeep"
#'
#' # Use with data frame
#' survey_data$depth_stratum <- stratify(survey_data$avg_depth_m)
#' }
#' @importFrom dplyr case_when
#' @export
stratify <- function(avg_depth_m) {
  case_when(
    avg_depth_m == 0 ~ "surface",
    avg_depth_m <= 6 ~ "supershallow",
    avg_depth_m <= 14 ~ "shallow",
    avg_depth_m <= 30 ~ "deep",
    avg_depth_m > 30 ~ "superdeep",
    TRUE ~ NA_character_
  )
}
