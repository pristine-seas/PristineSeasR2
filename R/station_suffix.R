#' Get Station Suffix from Depth Strata
#'
#' Converts depth strata to standardized station suffixes for consistent
#' station ID creation across Pristine Seas expeditions.
#'
#' @param depth_strata Character vector of depth strata from [stratify()].
#'
#' @return Character vector of station suffixes.
#'
#' @section Suffix Mapping:
#' | Stratum | Suffix |
#' |---------|--------|
#' | `surface` | `"00m"` |
#' | `supershallow` | `"05m"` |
#' | `shallow` | `"10m"` |
#' | `deep` | `"20m"` |
#' | `superdeep` | `"30m"` |
#'
#' @seealso [stratify()] to convert depths to strata
#'
#' @examples
#' # Basic usage
#' depths <- c(0, 3, 8, 15, 25, 35)
#' strata <- stratify(depths)
#' station_suffix(strata)
#'
#' # Build station IDs
#' site <- "PS-01"
#' suffixes <- station_suffix(stratify(c(5, 12, 25)))
#' paste0(site, "-", suffixes)
#' #> "RMI_2023_uvs_01_05m" "RMI_2023_uvs_01_10m" "RMI_2023_uvs_01_20m"
#'
#' @export
station_suffix <- function(depth_strata) {

  suffix_map <- c(
    "surface"      = "00m",
    "supershallow" = "05m",
    "shallow"      = "10m",
    "deep"         = "20m",
    "superdeep"    = "30m"
  )

  result <- suffix_map[depth_strata]

  unmatched <- is.na(result) & !is.na(depth_strata)
  if (any(unmatched)) {
    warning(
      "Unknown depth strata found: ",
      paste(unique(depth_strata[unmatched]), collapse = ", "),
      call. = FALSE
    )
  }

  as.character(result)
}
