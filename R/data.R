#' Underwater visual survey sites of the 2023 Marshall Islands expedition
#'
#' @description
#' The sites surveyed by the Pristine Seas expedition to the northern atolls
#' of the Marshall Islands in 2023, one row per site, in the standard shape
#' the package's UVS functions expect. Bundled so examples, articles and tests
#' have a real expedition to draw on without a database or Drive connection.
#'
#' A dated snapshot of the canonical table in BigQuery
#' (`pristine-seas.uvs.sites`), taken by the script in `data-raw/`. The team
#' lead and the free-text field notes are left in the database; every column
#' the figures use is here.
#'
#' @format A tibble with 60 rows and 13 columns:
#' \describe{
#'   \item{ps_site_id}{Site identifier, `RMI_2023_uvs_001` to `_060`.}
#'   \item{exp_id}{Expedition identifier, `RMI_2023` throughout.}
#'   \item{region, subregion}{The atoll: Bikar, Bokak, Bikini or Rongerik.
#'     Each atoll was its own region on this expedition, so the two agree.}
#'   \item{locality}{A named place within the atoll, where one was recorded.}
#'   \item{date, time}{When the survey began, local. `time` is an `hms`.}
#'   \item{latitude, longitude}{Position in decimal degrees, WGS84.}
#'   \item{site_name}{The team's short name for the site, such as `BKR-6`.}
#'   \item{habitat}{`fore_reef`, `back_reef` or `patch_reef`, from
#'     [allowed_vocab]`$uvs_habitats`.}
#'   \item{exposure}{`windward`, `leeward` or `lagoon`, from
#'     [allowed_vocab]`$exposure`.}
#'   \item{in_mpa}{Whether the site lies inside a marine protected area.}
#' }
#'
#' @source Pristine Seas expedition database, `pristine-seas.uvs.sites`,
#'   expedition `RMI_2023`.
#'
#' @seealso [map_uvs_sites()] and [explore_uvs_sites()], which take this table
#'   as their `sites`.
#'
#' @examples
#' rmi_2023_uvs_sites
#'
#' table(rmi_2023_uvs_sites$region, rmi_2023_uvs_sites$habitat)
"rmi_2023_uvs_sites"
