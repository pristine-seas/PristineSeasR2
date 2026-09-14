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

#' Fish belt-transect stations of the 2023 Marshall Islands expedition
#'
#' @description
#' The fish belt-transect (BLT) stations surveyed by the Pristine Seas
#' expedition to the northern atolls of the Marshall Islands in 2023, one row
#' per station, in the standard shape the package's UVS functions expect. A
#' station is one site at one depth stratum. Bundled alongside
#' [rmi_2023_uvs_sites] so examples, articles and tests have real survey
#' results to draw on without a database or Drive connection.
#'
#' A dated snapshot of the canonical table in BigQuery
#' (`pristine-seas.uvs.blt_stations`), taken by the script in `data-raw/`.
#' The divers' names and the free-text notes are left in the database.
#'
#' @format A tibble with 104 rows and 24 columns:
#' \describe{
#'   \item{ps_station_id}{Station identifier: the site's `ps_site_id` with the
#'     depth suffix from [station_suffix()], such as `RMI_2023_uvs_001_10m`.}
#'   \item{ps_site_id, exp_id, region, subregion, locality, habitat, exposure}{
#'     As in [rmi_2023_uvs_sites].}
#'   \item{depth_strata}{`shallow` or `deep`, from
#'     [allowed_vocab]`$depth_strata`.}
#'   \item{depth_m}{Station depth in metres.}
#'   \item{n_transects, survey_dist_m, survey_area_m2}{Survey effort: the
#'     number of transects, and the distance and area they covered.}
#'   \item{n_taxa, avg_taxa}{Taxa recorded across the station and per transect.}
#'   \item{total_count, avg_count, avg_density_m2}{Fish counted across the
#'     station, per transect, and per square metre.}
#'   \item{avg_biomass_gm2}{Mean fish biomass, grams per square metre.}
#'   \item{pct_shark, pct_top_predator, pct_lower_carni, pct_herbi_detri,
#'     pct_plankti}{Share of biomass in each trophic group, in percent, in the
#'     order of [allowed_vocab]`$trophic_group`.}
#' }
#'
#' @source Pristine Seas expedition database, `pristine-seas.uvs.blt_stations`,
#'   expedition `RMI_2023`.
#'
#' @seealso [rmi_2023_uvs_sites] for the sites these stations belong to.
#'
#' @examples
#' rmi_2023_uvs_blt_stations
#'
#' # mean biomass by atoll, station to site to atoll
#' \dontrun{
#' library(dplyr)
#' rmi_2023_uvs_blt_stations |>
#'   summarise(biomass = mean(avg_biomass_gm2), .by = c(region, ps_site_id)) |>
#'   summarise(biomass = mean(biomass), .by = region)
#' }
"rmi_2023_uvs_blt_stations"
