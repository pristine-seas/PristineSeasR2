# rmi_2023_uvs_blt_stations ----------------------------------------------------
# The fish belt-transect stations of the 2023 Marshall Islands expedition, as a
# dated snapshot of the canonical table in BigQuery, for the package's
# examples, articles and tests. Rerun to refresh; the pull is the provenance.
#
# One row per station (a site and a depth stratum), with survey effort, fish
# abundance and biomass, and the share of biomass in each trophic group. The
# divers' names and the free-text notes stay in the database.

library(bigrquery)
library(dplyr)

options(gargle_oauth_email = TRUE)

sql <- "
  SELECT ps_station_id, ps_site_id, exp_id, region, subregion, locality,
         habitat, exposure, depth_strata, depth_m,
         n_transects, survey_dist_m, survey_area_m2,
         n_taxa, avg_taxa, total_count, avg_count, avg_density_m2, avg_biomass_gm2,
         pct_shark, pct_top_predator, pct_lower_carni, pct_herbi_detri, pct_plankti
  FROM `pristine-seas.uvs.blt_stations`
  WHERE exp_id = 'RMI_2023'
  ORDER BY ps_station_id
"

rmi_2023_uvs_blt_stations <- bq_project_query("pristine-seas", sql) |>
  bq_table_download() |>
  as_tibble()

stopifnot(nrow(rmi_2023_uvs_blt_stations) == 104L,
          all(rmi_2023_uvs_blt_stations$ps_site_id %in% PristineSeasR2::rmi_2023_uvs_sites$ps_site_id),
          all(rmi_2023_uvs_blt_stations$depth_strata %in% PristineSeasR2::allowed_vocab$depth_strata))

usethis::use_data(rmi_2023_uvs_blt_stations, overwrite = TRUE, compress = "xz")
