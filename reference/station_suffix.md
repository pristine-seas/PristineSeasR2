# Get Station Suffix from Depth Strata

Converts depth strata to standardized station suffixes for consistent
station ID creation.

## Usage

``` r
station_suffix(depth_strata)
```

## Arguments

- depth_strata:

  Character vector of depth strata from stratify()

## Value

Character vector of station suffixes

## Details

Standard suffix mapping:

- surface: "00m"

- supershallow: "05m"

- shallow: "10m"

- deep: "20m"

- superdeep: "30m"

## Examples

``` r
if (FALSE) { # \dontrun{
# Basic usage
depths <- c(0, 3, 8, 15, 25, 35)
strata <- stratify(depths)
station_suffix(strata)
# Returns: "00m" "05m" "10m" "20m" "20m" "30m"

# Complete workflow
survey_data$depth_strata <- stratify(survey_data$station_depth_m)
survey_data$station_suffix <- station_suffix(survey_data$depth_strata)
} # }
```
