# Pristine Seas Color Palettes
# Internal data - not exported ---------------------------------------------

# Hierarchical regions palette (region -> subregions)
ps_regions <- list(

  region_1 = c(
    subregion_1 = "#153a5c",
    subregion_2 = "#2f6f9b",
    subregion_3 = "#8bb7dd"
  ),

  region_2 = c(
    subregion_1 = "#094f33",
    subregion_2 = "#2f8f5f",
    subregion_3 = "#8fd0b5"
  ),

  region_3 = c(
    subregion_1 = "#6a2f2f",
    subregion_2 = "#a35353",
    subregion_3 = "#e1a3a3"
  ),

  region_4 = c(
    subregion_1 = "#3e285f",
    subregion_2 = "#6d4fa3",
    subregion_3 = "#c1b0e2"
  ),

  region_5 = c(
    subregion_1 = "#8c5414",
    subregion_2 = "#c68436",
    subregion_3 = "#f0d2ad"
  )
)

# derived region-level and subregion-level palettes
ps_region_palette    <- vapply(ps_regions, function(x) x[1], character(1))
ps_subregion_palette <- unlist(ps_regions, use.names = TRUE)

ps_palettes <- list(

  # depth strata
  depth_strata = c(
    supershallow = "#9DEFFF",
    shallow      = "#8FB8D8",
    deep         = "#264E86",
    superdeep    = "#0B1026"
  ),

  # exposure
  exposure = c(
    windward  = "#7C1D18",
    exposed   = "#A8443A",
    channel   = "#1F4E79",
    leeward   = "#4F97A3",
    sheltered = "#AAD6CE",
    lagoon    = "#6FE6D2",
    unknown   = "#CFCFCF"
  ),

  # benthic functional groups
  functional_groups = c(
    hard_coral                   = "#1C2C54",
    cca                          = "#FF9FB2",
    soft_coral                   = "#7FD1E8",
    algae_erect                  = "#1F8A3F",
    algae_encrusting             = "#7FBF9B",
    algae_canopy                 = "#6B5A2B",
    sponges                      = "#D95D39",
    other                        = "#5B3F6B",
    cyanobacteria                = "#111111",
    turf                         = "#3A2A1C",
    "sediment | rubble | barren" = "#C9C9C9"
  ),

  # reef fish trophic groups
  trophic_group = c(
    shark                     = "#8B0000",
    top_predator              = "#CFAE43",
    lower_carnivore           = "#2F5068",
    "herbivore | detritivore" = "#0B6B3A",
    planktivore               = "#7FC8F8"
  ),

  # hierarchical regions (list)
  regions   = ps_regions,

  # one color per region (named by region)
  region    = ps_region_palette,

  # one color per subregion (flattened, e.g. "region_1.subregion_1")
  subregion = ps_subregion_palette,

  # UVS habitat types
  uvs_habitats = c(
    fore_reef     = "#E26B47",
    back_reef     = "#F39C6B",
    patch_reef    = "#F4A7B9",
    pinnacle_reef = "#C23B55",
    reef_flat     = "#4FC3D5",
    channel_pass  = "#2F6FA3",
    reef_pavement = "#B19A7A",
    bank          = "#CFAF7A",
    rocky_reef    = "#6B7078",
    wall          = "#3E4A52",
    kelp_forest   = "#2E6A3B",
    seagrass      = "#7BBF3F"
  )

)


# Public API ---------------------------------------------------------------

#' Get Pristine Seas colors
#'
#' Access internal Pristine Seas color palettes by name.
#'
#' Available palettes include:
#'
#' \itemize{
#'   \item \code{depth_strata}
#'   \item \code{exposure}
#'   \item \code{functional_groups}
#'   \item \code{trophic_group}
#'   \item \code{uvs_habitats}
#'   \item \code{region}     (one color per region)
#'   \item \code{subregion}  (one color per subregion)
#'   \item \code{regions}    (hierarchical list: region -> subregions)
#' }
#'
#' @param palette Character. Name of the palette to retrieve.
#'
#' @return
#' A named character vector of hex color codes, or a named list
#' (for \code{palette = "regions"}).
#'
#' @examples
#' \dontrun{
#' # raw palettes -------------------------------------------------------
#' ps_colors("trophic_group")
#' ps_colors("functional_groups")
#'
#' # region-level vs subregion-level palettes --------------------------
#' library(ggplot2)
#' library(tibble)
#' library(dplyr)
#'
#' region_cols    <- ps_colors("region")
#' subregion_cols <- ps_colors("subregion")
#'
#' df_regions <- tibble(
#'   site      = paste0("site_", 1:9),
#'   region    = rep(names(region_cols), each = 3)[1:9],
#'   subregion = factor(
#'     sample(names(subregion_cols), 9, replace = TRUE),
#'     levels = names(subregion_cols)
#'   ),
#'   value     = runif(9, 10, 100)
#' )
#'
#' # region-level color (one color per region)
#' ggplot(df_regions, aes(x = region, y = value, fill = region)) +
#'   geom_col() +
#'   scale_fill_manual(values = region_cols) +
#'   labs(title = "Region-level palette") +
#'   theme_minimal()
#'
#' # subregion-level color (distinct shade per subregion)
#' ggplot(df_regions, aes(x = subregion, y = value, fill = subregion)) +
#'   geom_col() +
#'   scale_fill_manual(values = subregion_cols) +
#'   labs(title = "Subregion-level palette") +
#'   theme_minimal() +
#'   theme(axis.text.x = element_text(angle = 45, hjust = 1))
#' }
#'
#' @export
ps_colors <- function(palette) {

  if (!palette %in% names(ps_palettes)) {
    stop(
      "Unknown palette '", palette, "'. ",
      "Available palettes: ",
      paste(names(ps_palettes), collapse = ", ")
    )
  }

  ps_palettes[[palette]]
}


# ggplot2 helpers ----------------------------------------------------------

#' Discrete color scale using Pristine Seas palettes
#'
#' Convenience wrapper around \code{ggplot2::scale_color_manual()} that pulls
#' colors from the Pristine Seas palette system via \code{ps_colors()}.
#'
#' This is intended for discrete color aesthetics where factor levels in your
#' data match the names of a palette (for example, \code{trophic_group},
#' \code{functional_groups}, \code{region}, or \code{subregion}).
#'
#' @param palette Character. Palette name passed to \code{ps_colors()}.
#'   Should return a named vector (not the hierarchical \code{regions} list).
#' @param ... Additional arguments passed to \code{ggplot2::scale_color_manual()}.
#'
#' @return A ggplot2 color scale.
#'
#' @examples
#' \dontrun{
#' library(ggplot2)
#' library(tibble)
#'
#' df <- tibble(
#'   trophic_group = names(ps_colors("trophic_group")),
#'   x             = seq_along(trophic_group),
#'   y             = runif(length(trophic_group))
#' )
#'
#' ggplot(df, aes(x = x, y = y, color = trophic_group)) +
#'   geom_point(size = 3) +
#'   scale_color_ps("trophic_group") +
#'   theme_minimal()
#' }
#'
#' @export
scale_color_ps <- function(palette, ...) {

  cols <- ps_colors(palette)

  if (is.list(cols)) {
    stop(
      "Palette '", palette, "' is hierarchical (a list). ",
      "Use 'region' or 'subregion' for ggplot scales."
    )
  }

  ggplot2::scale_color_manual(values = cols,
                              breaks = names(cols),  # enforce default order
                              ...)
}


#' Discrete fill scale using Pristine Seas palettes
#'
#' Convenience wrapper around \code{ggplot2::scale_fill_manual()} that pulls
#' colors from the Pristine Seas palette system via \code{ps_colors()}.
#'
#' This is intended for discrete fill aesthetics where factor levels in your
#' data match the names of a palette (for example, \code{trophic_group},
#' \code{functional_groups}, \code{uvs_habitats}, \code{region},
#' or \code{subregion}).
#'
#' @inheritParams scale_color_ps
#'
#' @return A ggplot2 fill scale.
#'
#' @examples
#' \dontrun{
#' library(ggplot2)
#' library(tibble)
#'
#' df <- tibble(
#'   habitat = names(ps_colors("uvs_habitats")),
#'   value   = runif(length(habitat))
#' )
#'
#' ggplot(df, aes(x = habitat, y = value, fill = habitat)) +
#'   geom_col() +
#'   scale_fill_ps("uvs_habitats") +
#'   theme_minimal() +
#'   theme(axis.text.x = element_text(angle = 45, hjust = 1))
#' }
#'
#' @export
scale_fill_ps <- function(palette, ...) {

  cols <- ps_colors(palette)

  if (is.list(cols)) {
    stop(
      "Palette '", palette, "' is hierarchical (a list). ",
      "Use 'region' or 'subregion' for ggplot scales."
    )
  }

  ggplot2::scale_fill_manual(values = cols,
                             breaks = names(cols),  # enforce default order
                             ...)
}
