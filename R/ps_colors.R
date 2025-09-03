# Pristine Seas Color Palettes
# Internal data - not exported
ps_palettes <- list(

  # Reef fish trophic groups
  trophic_group = c("shark"                 = "#BB4430",
                    "top_predator"          = "#ED9B40",
                    "lower_carnivore"       = "#7EBDC2",
                    "herbivore_detritivore" = "#04724D",
                    "planktivore"           = "#FF9FB2"),

  # Depth strata
  depth_strata = c("supershallow" = "#A8DADC",
                   "shallow"      = "#457B9D",
                   "deep"         = "#1D3557"),

  # Site exposure conditions
  exposure = c("windward"  = "#B22222",
               "exposed"   = "#CD5C5C",
               "channel"   = "#4682B4",
               "leeward"   = "#87CEEB",
               "sheltered" = "#98D8C8",
               "lagoon"    = "#F7DC6F",
               "unknown"   = "#D3D3D3"),

  # UVS habitat types
  uvs_habitats = c("fore_reef"     = "#FF6347",
                   "back_reef"     = "#FFA07A",
                   "patch_reef"    = "#FF8C69",
                   "pinnacle_reef" = "#DC143C",
                   "reef_flat"     = "#87CEEB",
                   "reef_pavement" = "#DEB887",
                   "bank"          = "#F4A460",
                   "rocky_reef"    = "#708090",
                   "wall"          = "#2F4F4F",
                   "channel_pass"  = "#4682B4",
                   "kelp_forest"   = "#228B22",
                   "seagrass"      = "#9ACD32"),

  # Functional groups
  functional_groups = c("hard_coral"             = "#FF6B47",
                        "cca"                    = "#E6A8D2",
                        "cyanobacteria"          = "#03071e",
                        "soft_coral"             = "#3399cc",
                        "sponges"                = "#ffcb69",
                        "erect_algae"            = "#007f5f",
                        "encrusting_algae"       = "#80b918",
                        "turf"                   = "#936639",
                        "sediment|rubble|barren" = "#d3d3d3",
                        "other"                  = "#6f4e7c")
)


#' Get Pristine Seas Colors
#'
#' @param palette Character. Palette name
#' @return Named vector of hex color codes
#' @examples
#' \dontrun{
#' ps_colors("trophic_group")
#' ps_colors("functional_groups")
#'
#' # Use in ggplot2
#' scale_color_manual(values = ps_colors("trophic_group"))
#' }
#' @export
ps_colors <- function(palette) {

  if (!palette %in% names(ps_palettes)) {
    stop("Available palettes: trophic_group, depth_strata, exposure, uvs_habitats, functional_groups")
  }

  return(ps_palettes[[palette]])
}
