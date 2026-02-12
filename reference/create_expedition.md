# Create New Pristine Seas Expedition Structure

Creates a comprehensive standardized folder structure for Pristine Seas
expeditions in the expeditions folder of the science drive. Expedition
names follow the convention ISO3-YEAR (e.g., CHL-2024).

## Usage

``` r
create_expedition(expedition_name, create_readme = TRUE)
```

## Arguments

- expedition_name:

  Character string. Name of the expedition following ISO3-YEAR format

- create_readme:

  Logical. Whether to create a README.md file with expedition template
  (default: TRUE)

## Value

Character string. Path to the created expedition folder

## Examples

``` r
if (FALSE) { # \dontrun{
# Create an expedition (standard naming: ISO3-YEAR)
create_expedition("CHL-2024")

# Create expedition without README
create_expedition("MEX-2024", create_readme = FALSE)
} # }
```
