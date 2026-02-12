# Get Station Suffix from Depth Strata

Converts depth strata to standardized station suffixes for consistent
station ID creation across Pristine Seas expeditions.

## Usage

``` r
station_suffix(depth_strata)
```

## Arguments

- depth_strata:

  Character vector of depth strata from
  [`stratify()`](https://pristine-seas.github.io/PristineSeasR2/reference/stratify.md).

## Value

Character vector of station suffixes.

## Suffix Mapping

|                |         |
|----------------|---------|
| Stratum        | Suffix  |
| `surface`      | `"00m"` |
| `supershallow` | `"05m"` |
| `shallow`      | `"10m"` |
| `deep`         | `"20m"` |
| `superdeep`    | `"30m"` |

## See also

[`stratify()`](https://pristine-seas.github.io/PristineSeasR2/reference/stratify.md)
to convert depths to strata

## Examples

``` r
# Basic usage
depths <- c(0, 3, 8, 15, 25, 35)
strata <- stratify(depths)
station_suffix(strata)
#> [1] "00m" "05m" "10m" "20m" "20m" "30m"

# Build station IDs
site <- "PS-01"
suffixes <- station_suffix(stratify(c(5, 12, 25)))
paste0(site, "-", suffixes)
#> [1] "PS-01-05m" "PS-01-10m" "PS-01-20m"
#> "RMI_2023_uvs_01_05m" "RMI_2023_uvs_01_10m" "RMI_2023_uvs_01_20m"
```
