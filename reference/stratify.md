# Stratify Depths into Standard Categories

Converts depth measurements in meters to standardized Pristine Seas
depth strata categories using fixed thresholds for consistency across
all projects.

## Usage

``` r
stratify(avg_depth_m)
```

## Arguments

- avg_depth_m:

  Numeric vector. Average depth measurements in meters.

## Value

Character vector with depth stratum labels.

## Depth Strata

|                |             |
|----------------|-------------|
| Stratum        | Depth Range |
| `surface`      | 0m          |
| `supershallow` | 0.1 – 6m    |
| `shallow`      | 6.1 – 14m   |
| `deep`         | 14.1 – 30m  |
| `superdeep`    | \> 30m      |

## See also

[`station_suffix()`](https://pristine-seas.github.io/PristineSeasR2/reference/station_suffix.md)
to convert strata to station ID suffixes

## Examples

``` r
# Stratify survey depths
depths <- c(0, 3, 8, 12, 18, 25, 35, 45)
stratify(depths)
#> [1] "surface"      "supershallow" "shallow"      "shallow"      "deep"        
#> [6] "deep"         "superdeep"    "superdeep"   

# Combine with station_suffix for IDs
station_suffix(stratify(depths))
#> [1] "00m" "05m" "10m" "10m" "20m" "20m" "30m" "30m"

# Typical workflow
survey_data <- data.frame(ps_station_id = c("RMI_2023_uvs_01", "RMI_2023_uvs_01", "RMI_2023_uvs_02", "RMI_2023_uvs_02"),
                          depth_m       = c(12, 21, 5, 12))

survey_data$depth_strata <- stratify(survey_data$depth_m)
survey_data$suffix <- station_suffix(survey_data$depth_strata)
survey_data
#>     ps_station_id depth_m depth_strata suffix
#> 1 RMI_2023_uvs_01      12      shallow    10m
#> 2 RMI_2023_uvs_01      21         deep    20m
#> 3 RMI_2023_uvs_02       5 supershallow    05m
#> 4 RMI_2023_uvs_02      12      shallow    10m
```
