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
ps_colors()                 # list available palettes
#> [1] "depth_strata"  "trophic_group" "benthic_cover" "exposure"     
#> [5] "habitat"      
ps_colors("trophic_group")  # named vector
#>                   shark            top_predator         lower_carnivore 
#>               "#75161D"               "#AC2D00"               "#B96310" 
#> herbivore | detritivore             planktivore 
#>               "#40AE82"               "#C1C2FA" 
ps_colors("benthic_cover")  # named vector
#>                 hard_coral                        cca 
#>                  "#FFCD16"                  "#E563A4" 
#>                    sponges                 soft_coral 
#>                  "#393A81"                  "#DE98E3" 
#>                      other           algae_encrusting 
#>                  "#BAB5B1"                  "#0D5F5B" 
#>                algae_erect               algae_canopy 
#>                  "#8EBB67"                  "#784620" 
#> sediment | rubble | barren                       turf 
#>                  "#E8DDB7"                  "#7B8563" 
#>              cyanobacteria 
#>                  "#2C2234" 
```
