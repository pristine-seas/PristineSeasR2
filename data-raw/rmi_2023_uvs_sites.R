# rmi_2023_uvs_sites ------------------------------------------------------------
# The underwater visual survey sites of the 2023 Marshall Islands expedition,
# as a dated snapshot of the canonical table in BigQuery, for the package's
# examples, articles and tests. Rerun to refresh; the pull is the provenance.
#
# BigQuery is the source of truth for expedition data, so the snapshot is
# taken from there rather than from a CSV on the shared Drive. The columns
# kept are the ones the package's figures use; the team lead and the free-text
# field notes stay in the database.

library(bigrquery)
library(dplyr)

options(gargle_oauth_email = TRUE)

sql <- "
  SELECT ps_site_id, exp_id, region, subregion, locality, date, time,
         latitude, longitude, site_name, habitat, exposure, in_mpa
  FROM `pristine-seas.uvs.sites`
  WHERE exp_id = 'RMI_2023'
  ORDER BY ps_site_id
"

rmi_2023_uvs_sites <- bq_project_query("pristine-seas", sql) |>
  bq_table_download() |>
  mutate(time = hms::as_hms(time)) |>
  as_tibble()

stopifnot(nrow(rmi_2023_uvs_sites) == 60L,
          all(rmi_2023_uvs_sites$habitat  %in% PristineSeasR2::allowed_vocab$uvs_habitats),
          all(is.na(rmi_2023_uvs_sites$exposure) |
              rmi_2023_uvs_sites$exposure %in% PristineSeasR2::allowed_vocab$exposure))

usethis::use_data(rmi_2023_uvs_sites, overwrite = TRUE, compress = "xz")
