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

  Numeric vector. Average depth measurements in meters

## Value

Character vector with depth stratum labels: "surface", "supershallow",
"shallow", "deep", "superdeep", or NA

## Details

Standard Pristine Seas depth strata:

- Surface: exactly 0m

- Supershallow: 0.1 - 6m

- Shallow: 6.1 - 14m

- Deep: 14.1 - 30m

- Superdeep: \> 30m

- NA: missing or invalid depth values

## Examples

``` r
if (FALSE) { # \dontrun{
# Stratify survey depths
depths <- c(0, 3, 8, 12, 18, 25, 35, 45)
stratify(depths)
# Returns: "surface" "supershallow" "shallow" "shallow" "deep" "deep" "superdeep" "superdeep"

# Use with data frame
survey_data$depth_stratum <- stratify(survey_data$avg_depth_m)
} # }
```
