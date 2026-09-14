# Fish belt-transect stations of the 2023 Marshall Islands expedition

The fish belt-transect (BLT) stations surveyed by the Pristine Seas
expedition to the northern atolls of the Marshall Islands in 2023, one
row per station, in the standard shape the package's UVS functions
expect. A station is one site at one depth stratum. Bundled alongside
[rmi_2023_uvs_sites](https://pristine-seas.github.io/PristineSeasR2/reference/rmi_2023_uvs_sites.md)
so examples, articles and tests have real survey results to draw on
without a database or Drive connection.

A dated snapshot of the canonical table in BigQuery
(`pristine-seas.uvs.blt_stations`), taken by the script in `data-raw/`.
The divers' names and the free-text notes are left in the database.

## Usage

``` r
rmi_2023_uvs_blt_stations
```

## Format

A tibble with 104 rows and 24 columns:

- ps_station_id:

  Station identifier: the site's `ps_site_id` with the depth suffix from
  [`station_suffix()`](https://pristine-seas.github.io/PristineSeasR2/reference/station_suffix.md),
  such as `RMI_2023_uvs_001_10m`.

- ps_site_id, exp_id, region, subregion, locality, habitat, exposure:

  As in
  [rmi_2023_uvs_sites](https://pristine-seas.github.io/PristineSeasR2/reference/rmi_2023_uvs_sites.md).

- depth_strata:

  `shallow` or `deep`, from
  [allowed_vocab](https://pristine-seas.github.io/PristineSeasR2/reference/allowed_vocab.md)`$depth_strata`.

- depth_m:

  Station depth in metres.

- n_transects, survey_dist_m, survey_area_m2:

  Survey effort: the number of transects, and the distance and area they
  covered.

- n_taxa, avg_taxa:

  Taxa recorded across the station and per transect.

- total_count, avg_count, avg_density_m2:

  Fish counted across the station, per transect, and per square metre.

- avg_biomass_gm2:

  Mean fish biomass, grams per square metre.

- pct_shark, pct_top_predator, pct_lower_carni, pct_herbi_detri,
  pct_plankti:

  Share of biomass in each trophic group, in percent, in the order of
  [allowed_vocab](https://pristine-seas.github.io/PristineSeasR2/reference/allowed_vocab.md)`$trophic_group`.

## Source

Pristine Seas expedition database, `pristine-seas.uvs.blt_stations`,
expedition `RMI_2023`.

## See also

[rmi_2023_uvs_sites](https://pristine-seas.github.io/PristineSeasR2/reference/rmi_2023_uvs_sites.md)
for the sites these stations belong to.

## Examples

``` r
rmi_2023_uvs_blt_stations
#> # A tibble: 104 × 24
#>    ps_station_id    ps_site_id exp_id region subregion locality habitat exposure
#>    <chr>            <chr>      <chr>  <chr>  <chr>     <chr>    <chr>   <chr>   
#>  1 RMI_2023_uvs_00… RMI_2023_… RMI_2… Bikar  Bikar     NA       fore_r… leeward 
#>  2 RMI_2023_uvs_00… RMI_2023_… RMI_2… Bikar  Bikar     NA       fore_r… leeward 
#>  3 RMI_2023_uvs_00… RMI_2023_… RMI_2… Bikar  Bikar     NA       fore_r… leeward 
#>  4 RMI_2023_uvs_00… RMI_2023_… RMI_2… Bikar  Bikar     NA       fore_r… leeward 
#>  5 RMI_2023_uvs_00… RMI_2023_… RMI_2… Bikar  Bikar     NA       fore_r… leeward 
#>  6 RMI_2023_uvs_00… RMI_2023_… RMI_2… Bikar  Bikar     NA       fore_r… leeward 
#>  7 RMI_2023_uvs_00… RMI_2023_… RMI_2… Bikar  Bikar     NA       fore_r… leeward 
#>  8 RMI_2023_uvs_00… RMI_2023_… RMI_2… Bikar  Bikar     NA       fore_r… leeward 
#>  9 RMI_2023_uvs_00… RMI_2023_… RMI_2… Bikar  Bikar     NA       fore_r… leeward 
#> 10 RMI_2023_uvs_00… RMI_2023_… RMI_2… Bikar  Bikar     NA       fore_r… leeward 
#> # ℹ 94 more rows
#> # ℹ 16 more variables: depth_strata <chr>, depth_m <dbl>, n_transects <int>,
#> #   survey_dist_m <dbl>, survey_area_m2 <dbl>, n_taxa <int>, avg_taxa <dbl>,
#> #   total_count <int>, avg_count <dbl>, avg_density_m2 <dbl>,
#> #   avg_biomass_gm2 <dbl>, pct_shark <dbl>, pct_top_predator <dbl>,
#> #   pct_lower_carni <dbl>, pct_herbi_detri <dbl>, pct_plankti <dbl>

# mean biomass by atoll, station to site to atoll
if (FALSE) { # \dontrun{
library(dplyr)
rmi_2023_uvs_blt_stations |>
  summarise(biomass = mean(avg_biomass_gm2), .by = c(region, ps_site_id)) |>
  summarise(biomass = mean(biomass), .by = region)
} # }
```
