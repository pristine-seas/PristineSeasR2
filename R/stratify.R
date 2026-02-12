#' Stratify Depths into Standard Categories
#'
#' Converts depth measurements in meters to standardized Pristine Seas depth
#' strata categories using fixed thresholds for consistency across all projects.
#'
#' @param avg_depth_m Numeric vector. Average depth measurements in meters.
#'
#' @return Character vector with depth stratum labels.
#'
#' @section Depth Strata:
#' | Stratum | Depth Range |
#' |---------|-------------|
#' | `surface` | 0m |
#' | `supershallow` | 0.1 – 6m |
#' | `shallow` | 6.1 – 14m |
#' | `deep` | 14.1 – 30m |
#' | `superdeep` | > 30m |
#'
#' @seealso [station_suffix()] to convert strata to station ID suffixes
#'
#' @examples
#' # Stratify survey depths
#' depths <- c(0, 3, 8, 12, 18, 25, 35, 45)
#' stratify(depths)
#'
#' # Combine with station_suffix for IDs
#' station_suffix(stratify(depths))
#'
#' # Typical workflow
#' survey_data <- data.frame(ps_station_id = c("RMI_2023_uvs_01", "RMI_2023_uvs_01", "RMI_2023_uvs_02", "RMI_2023_uvs_02"),
#'                           depth_m       = c(12, 21, 5, 12))
#'
#' survey_data$depth_strata <- stratify(survey_data$depth_m)
#' survey_data$suffix <- station_suffix(survey_data$depth_strata)
#' survey_data
#'
#' @importFrom dplyr case_when
#' @export
stratify <- function(avg_depth_m) {
  dplyr::case_when(
    avg_depth_m == 0 ~ "surface",
    avg_depth_m <= 6 ~ "supershallow",
    avg_depth_m <= 14 ~ "shallow",
    avg_depth_m <= 30 ~ "deep",
    avg_depth_m > 30 ~ "superdeep",
    TRUE ~ NA_character_
  )
}
