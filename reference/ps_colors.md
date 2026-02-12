# Get Pristine Seas colors

Retrieve Pristine Seas color palettes by name.

## Usage

``` r
ps_colors(palette = NULL)
```

## Arguments

- palette:

  Character. Name of the palette to retrieve. If `NULL`, returns the
  available palette names.

## Value

If `palette` is `NULL`, a character vector of palette names. Otherwise,
a named character vector of hex codes.

## Details

Palettes are returned as named character vectors of hex color codes.

## Examples

``` r
ps_colors()                    # list available palettes
#> [1] "depth_strata"      "exposure"          "trophic_group"    
#> [4] "functional_groups" "uvs_habitats"     
ps_colors("trophic_group")     # named vector
#>                   shark            top_predator         lower_carnivore 
#>               "#7A0010"               "#E0B83F"               "#8EC9F0" 
#> herbivore | detritivore             planktivore 
#>               "#1F7A4C"               "#B9A3E3" 
ps_colors("functional_groups") # named vector
#>                 hard_coral                        cca 
#>                  "#2E4A9E"                  "#FF7FA7" 
#>                 soft_coral                algae_erect 
#>                  "#6FD3E3"                  "#2FA84F" 
#>           algae_encrusting               algae_canopy 
#>                  "#8FCFA9"                  "#8A7A3A" 
#>                    sponges                      other 
#>                  "#E07A5F"                  "#7A5C8F" 
#>              cyanobacteria                       turf 
#>                  "#0B0B0B"                  "#4A3A2A" 
#> sediment | rubble | barren 
#>                  "#D9D9D9" 
```
