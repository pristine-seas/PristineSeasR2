# Explore Sentinel-1 detections

An interactive map of radar vessel detections, one marker per detection,
each popup opening the Sentinel-1 crop the detection was made from and
marked at its exact centre.

The optical counterpart is
[`explore_s2_detections()`](https://pristine-seas.github.io/PristineSeasR2/reference/explore_s2_detections.md),
and the two share a cache format, an inspector overlay and an export
path. Two things differ. Crops are backscatter in decibels rather than a
visible-light composite, so the views are polarisations (`"vv"`,
`"vh"`). And markers are coloured by a caller-supplied class rather than
by whether AIS explained them, because over most water radar sees far
more shipping than fishing and the interesting question is which is
which.

## Usage

``` r
explore_s1_detections(
  detections,
  class_col = NULL,
  palette = NULL,
  cache_dir = NULL,
  buffer_m = 500,
  view = "vv",
  embed = TRUE,
  boundary = NULL,
  boundary_color = "#B6D94C",
  gallery = TRUE,
  gallery_order = "in the order given",
  legend_title = NULL,
  title = NULL,
  subtitle = "National Geographic Pristine Seas",
  export_path = NULL,
  ee_project = NULL,
  ee_python = Sys.getenv("EARTHENGINE_PYTHON"),
  ee_asset_home = NULL
)
```

## Arguments

- detections:

  A data frame, or a path to a CSV, with `detect_id`, `detect_lat`,
  `detect_lon` and `scene_id`. Used when present: `detect_timestamp` (or
  `when`), `length_m` (or `length_m_inferred`), a class column,
  `fishing_score`, `presence_score` and `matching_score` (GFW's own
  confidence in the AIS identity behind a match, NA where a detection
  has none). With `fishing_score`, the gallery and arrow-key order runs
  highest score first, as
  [`explore_s2_detections()`](https://pristine-seas.github.io/PristineSeasR2/reference/explore_s2_detections.md)
  already orders by `presence_score`; without it, rows are shown in the
  order they arrive.

- class_col:

  Name of the column colouring the markers. Defaults to `"fleet"` when
  present, then `"class"`; `NULL` draws every marker alike.

- palette:

  Named colours, one per class level. Names must match the values in
  `class_col`. Defaults to a grey ramp.

- cache_dir:

  Where crops are cached. Crops already cached need no Earth Engine
  credentials, which is what lets a colleague rebuild the map.

- buffer_m:

  Half-width of the crop, in metres. Sentinel-1 GRD is 10 m a pixel, so
  500 m gives a 100-pixel frame.

- view:

  One or more of `names(s1_views)`.

- embed:

  Cache and inline the crops as `data:` URIs. `FALSE` links to Earth
  Engine URLs, which expire within days.

- boundary:

  Optional `sf` outline drawn over the map.

- boundary_color, gallery, legend_title, title, subtitle, export_path:

  As in
  [`explore_s2_detections()`](https://pristine-seas.github.io/PristineSeasR2/reference/explore_s2_detections.md).

- gallery_order:

  Label shown under the contact sheet's count, describing the order it
  is actually in: by `fishing_score` when the column is present,
  otherwise the order rows arrive in.

- ee_project, ee_python, ee_asset_home:

  Earth Engine connection details, used only when a crop is missing from
  `cache_dir`.

## Value

A `leaflet` widget.
