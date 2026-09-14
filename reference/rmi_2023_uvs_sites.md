# Underwater visual survey sites of the 2023 Marshall Islands expedition

The sites surveyed by the Pristine Seas expedition to the northern
atolls of the Marshall Islands in 2023, one row per site, in the
standard shape the package's UVS functions expect. Bundled so examples,
articles and tests have a real expedition to draw on without a database
or Drive connection.

A dated snapshot of the canonical table in BigQuery
(`pristine-seas.uvs.sites`), taken by the script in `data-raw/`. The
team lead and the free-text field notes are left in the database; every
column the figures use is here.

## Usage

``` r
rmi_2023_uvs_sites
```

## Format

A tibble with 60 rows and 13 columns:

- ps_site_id:

  Site identifier, `RMI_2023_uvs_001` to `_060`.

- exp_id:

  Expedition identifier, `RMI_2023` throughout.

- region, subregion:

  The atoll: Bikar, Bokak, Bikini or Rongerik. Each atoll was its own
  region on this expedition, so the two agree.

- locality:

  A named place within the atoll, where one was recorded.

- date, time:

  When the survey began, local. `time` is an `hms`.

- latitude, longitude:

  Position in decimal degrees, WGS84.

- site_name:

  The team's short name for the site, such as `BKR-6`.

- habitat:

  `fore_reef`, `back_reef` or `patch_reef`, from
  [allowed_vocab](https://pristine-seas.github.io/PristineSeasR2/reference/allowed_vocab.md)`$uvs_habitats`.

- exposure:

  `windward`, `leeward` or `lagoon`, from
  [allowed_vocab](https://pristine-seas.github.io/PristineSeasR2/reference/allowed_vocab.md)`$exposure`.

- in_mpa:

  Whether the site lies inside a marine protected area.

## Source

Pristine Seas expedition database, `pristine-seas.uvs.sites`, expedition
`RMI_2023`.

## See also

[`map_uvs_sites()`](https://pristine-seas.github.io/PristineSeasR2/reference/map_uvs_sites.md)
and
[`explore_uvs_sites()`](https://pristine-seas.github.io/PristineSeasR2/reference/explore_uvs_sites.md),
which take this table as their `sites`.

## Examples

``` r
rmi_2023_uvs_sites
#> # A tibble: 60 × 13
#>    ps_site_id       exp_id   region subregion locality date       time  latitude
#>    <chr>            <chr>    <chr>  <chr>     <chr>    <date>     <hms>    <dbl>
#>  1 RMI_2023_uvs_001 RMI_2023 Bikar  Bikar     NA       2023-08-31 3240…     12.2
#>  2 RMI_2023_uvs_002 RMI_2023 Bikar  Bikar     NA       2023-08-31 4110…     12.2
#>  3 RMI_2023_uvs_003 RMI_2023 Bikar  Bikar     NA       2023-08-31 5610…     12.2
#>  4 RMI_2023_uvs_004 RMI_2023 Bikar  Bikar     NA       2023-09-01 3120…     12.3
#>  5 RMI_2023_uvs_005 RMI_2023 Bikar  Bikar     NA       2023-09-01 3960…     12.3
#>  6 RMI_2023_uvs_006 RMI_2023 Bikar  Bikar     NA       2023-09-01 5400…     12.3
#>  7 RMI_2023_uvs_007 RMI_2023 Bikar  Bikar     NA       2023-09-02 3600…     12.2
#>  8 RMI_2023_uvs_008 RMI_2023 Bikar  Bikar     NA       2023-09-02 4860…     12.3
#>  9 RMI_2023_uvs_009 RMI_2023 Bikar  Bikar     NA       2023-09-03 3000…     12.2
#> 10 RMI_2023_uvs_010 RMI_2023 Bikar  Bikar     NA       2023-09-03 3870…     12.3
#> # ℹ 50 more rows
#> # ℹ 5 more variables: longitude <dbl>, site_name <chr>, habitat <chr>,
#> #   exposure <chr>, in_mpa <lgl>

table(rmi_2023_uvs_sites$region, rmi_2023_uvs_sites$habitat)
#>           
#>            back_reef fore_reef patch_reef
#>   Bikar            0        11          4
#>   Bikini           4        11          1
#>   Bokak            0        12          4
#>   Rongerik         0        10          3
```
