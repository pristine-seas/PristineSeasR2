# Map underwater visual survey sites

Draws the standard Pristine Seas site map for a report: the sites of a
region or subregion on satellite imagery, a reference map or a clean
drawn coastline, each marker taking its shape from the habitat
([`ps_shapes()`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_shapes.md))
and its fill from the exposure
([`ps_colors()`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_colors.md)),
set on
[`theme_ps_map()`](https://pristine-seas.github.io/PristineSeasR2/reference/theme_ps_map.md)
with a compass rose, a scale bar and a locator globe kept quiet enough
not to compete with the geography. One call, one design, every
expedition.

The frame is fitted to the sites chosen: their bounding box, padded by a
fraction of its larger side, and never narrower than `min_span`
kilometres so a tight cluster of sites still shows the reef around it.
To adjust it, widen or tighten `expand`, or set the frame outright with
`extent`. Tiles are fetched at the zoom that gives the frame's longer
side about 2000 pixels, enough for a full-page figure, and cached for
the session, so redrawing a map is quick.

## Usage

``` r
map_uvs_sites(
  sites,
  region = NULL,
  subregion = NULL,
  expand = 0.25,
  min_span = 3,
  extent = NULL,
  basemap = c("esri", "mapbox", "coast", "natgeo"),
  mapbox_token = Sys.getenv("MAPBOX_TOKEN"),
  zoom = NULL,
  label_sites = FALSE,
  locator = TRUE,
  title = "Underwater visual survey sites",
  subtitle = NULL,
  caption = NULL,
  base_size = 12,
  export = NULL,
  width = 8,
  height = NULL
)
```

## Arguments

- sites:

  A site-level data frame, one row per site, such as the validated UVS
  sites table. Must include `ps_site_id`, `longitude`, `latitude`,
  `region`, `subregion`, `habitat` and `exposure`. Habitat and exposure
  must follow the vocabulary in
  [allowed_vocab](https://pristine-seas.github.io/PristineSeasR2/reference/allowed_vocab.md);
  a missing exposure is drawn as `"unknown"`.

- region, subregion:

  Character. Which sites to draw. Either may name one or several values;
  `subregion` is matched within `region` when both are given. `NULL`
  (the default) places no restriction, so with neither set the whole
  table is drawn. A name that matches no site is an error that lists the
  names available.

- expand:

  Numeric. Margin around the sites, as a fraction of the larger side of
  their bounding box, added on every side. Default 0.25. Raise it to
  show more sea around the sites, lower it to tighten the frame.

- min_span:

  Numeric. The narrowest the map may be, in kilometres, on either axis.
  Default 3.

- extent:

  The frame, set outright: `c(xmin, ymin, xmax, ymax)` in degrees of
  longitude and latitude, or an `sf` bbox in any projection. Overrides
  `expand` and `min_span`. `NULL` (the default) fits the frame to the
  sites. Every map carries the frame it drew as `attr(p, "extent")`, in
  degrees, so the usual way to nudge one is to start from that and move
  an edge.

- basemap:

  What the sites are drawn on: `"esri"` (World Imagery, the default),
  `"mapbox"` (Satellite, needs a token), `"coast"` (Global Islands
  coastline, no imagery) or `"natgeo"` (the National Geographic World
  Map, for regional views). See the Basemaps section.

- mapbox_token:

  Character. A Mapbox access token, used only when `basemap = "mapbox"`.
  Defaults to the `MAPBOX_TOKEN` environment variable.

- zoom:

  Integer. Tile zoom level for the tiled basemaps. `NULL` (the default)
  picks the level that gives the frame's longer side about 2000 pixels,
  within what each provider reliably serves; one level up doubles that,
  and quadruples the fetch. A value given here is honoured up to the
  provider's hard limit. Ignored by `basemap = "coast"`.

- label_sites:

  Logical. Label each marker with its site number, the digits that end
  `ps_site_id` (so `RMI_2023_uvs_007` reads `7`), placed by **ggrepel**
  so labels never sit on a marker, on each other or on the globe. An id
  with no trailing digits is shown whole. Default `FALSE`.

- locator:

  Logical. Inset a small globe, the hemisphere centred on the map with a
  rectangle outlining the frame, so a reader who does not know the
  archipelago can place it. It takes the top right corner unless a site
  sits there, then the top left, then the bottom right; the compass rose
  takes the next free corner. Land comes from Natural Earth through
  **rnaturalearth**. Default `TRUE`.

- title, subtitle, caption:

  Character. The title block. The subtitle defaults to the place drawn
  and its site count; the caption to the credit for the basemap drawn,
  which each provider's terms ask for.

- base_size:

  Numeric. Base font size in points, passed to
  [`theme_ps_map()`](https://pristine-seas.github.io/PristineSeasR2/reference/theme_ps_map.md).
  Default 12.

- export:

  Character. A file path to save the map to as well as returning it,
  typically a `.pdf` for the report; any extension
  [`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html)
  knows is accepted. A PDF is vector for everything but the imagery,
  which is embedded at its fetched resolution; the house typeface is
  embedded where R can draw through Cairo and set in Helvetica
  otherwise. `NULL` (the default) saves nothing.

- width, height:

  Numeric. Size of the exported figure in inches. `width` defaults to 8;
  `height` to `NULL`, which sets it from the frame's own proportions so
  the map is neither stretched nor padded.

## Value

A ggplot object, with the frame it drew as `attr(p, "extent")`. Print
it, or save it with
[`ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html); the
theme carries its own canvas, so no `bg` is needed. When `export` is
given the file is written first and the map returned invisibly.

## Basemaps

Four to choose from, and the right one differs map by map:

- `"esri"`, the default: Esri World Imagery. Needs no account. A
  consistent mosaic wherever Esri had a clear pass.

- `"mapbox"`: Mapbox Satellite. Often a fresher, sharper Maxar scene
  where Esri has cloud, and needs an access token. Rather than pass it
  to every call, keep it in `.Renviron` as `MAPBOX_TOKEN` and it is
  picked up from there: `usethis::edit_r_environ()`, then a line
  `MAPBOX_TOKEN=pk.xxxx`.

- `"coast"`: no imagery at all. Land from the USGS, Esri and WCMC Global
  Islands database, Landsat-derived polygons for every island on Earth,
  drawn in the theme's land ink on its water, with the graticule
  showing. The quiet option when the imagery is cloudy or the sites are
  the point. Polygons are fetched from UNEP-WCMC's map service for the
  frame drawn, so nothing needs to be on disk.

- `"natgeo"`: the National Geographic World Map, Esri's reference map in
  the Society's cartographic style, with shaded relief, bathymetry and
  place names. Light-toned, so the marks flip to dark ink on it. Made
  for the regional view: a whole region or expedition, where the names
  matter and a single island's reef would be too small to see. Its
  content is only whole to zoom 9 over the open ocean, so the automatic
  zoom stops there and a frame under about 200 km draws soft. Where a
  deeper level turns out to have content, ask for it with `zoom`.

The caption credits whichever source drew the map, as each provider's
terms ask.

## What it needs

The annotations come from **ggspatial**, and tiled basemaps from
**maptiles** and **tidyterra**, none of which install with this package;
**ggrepel** is added when `label_sites = TRUE` and **rnaturalearth**
with **rnaturalearthdata** when `locator = TRUE`. The first call offers
to install whichever is missing. Every basemap is fetched live, so an
internet connection is needed.

## Building on it

The return value is an ordinary ggplot, so anything the map lacks can be
added the usual way: a
[`labs()`](https://ggplot2.tidyverse.org/reference/labs.html) to change
the wording, a
[`geom_sf()`](https://ggplot2.tidyverse.org/reference/ggsf.html) for an
MPA boundary. Take colours for those layers from
[`ps_ink()`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_ink.md)
so they sit in the same key as the canvas.

## See also

[`explore_uvs_sites()`](https://pristine-seas.github.io/PristineSeasR2/reference/explore_uvs_sites.md)
for the interactive map,
[`theme_ps_map()`](https://pristine-seas.github.io/PristineSeasR2/reference/theme_ps_map.md)
for the canvas,
[`ps_shapes()`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_shapes.md)
and
[`ps_colors()`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_colors.md)
for the marker encoding.

## Examples

``` r
if (FALSE) { # \dontrun{
map_uvs_sites(rmi_2023_uvs_sites, region = "Bikar")

# Straight to the report
map_uvs_sites(rmi_2023_uvs_sites, region = "Bikar", export = "figures/bikar_sites.pdf")
} # }
```
