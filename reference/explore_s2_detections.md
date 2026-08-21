# Explore Sentinel-2 Vessel Detections, With The Imagery Behind Each One

Builds the standard Pristine Seas Sentinel-2 detection map: one marker
per detection on satellite imagery, a popup carrying the model's scores
and the scene the detection came from, and — behind a **View Sentinel-2
thumbnail** link — the crop itself, opened full-size with a red ring
marking the exact detection position. Arrow keys step through every
detection in turn, so a few hundred candidates can be reviewed without
going back to the map.

Crops are rendered by Earth Engine, cached to `cache_dir`, and inlined
into the page, which is what lets the exported map travel: send the HTML
to a colleague and it opens with no Earth Engine account, no
credentials, and no access to the data behind it. Only the basemap is
fetched live.

Earth Engine is contacted **only for crops not already cached**, so a
map whose cache is warm needs no credentials at all and builds in about
a second.

## Usage

``` r
explore_s2_detections(
  detections,
  cache_dir = NULL,
  buffer_m = 500,
  view = "ocean",
  embed = TRUE,
  boundary = NULL,
  boundary_color = "#B6D94C",
  matched_color = "#4EC9E8",
  unmatched_color = "#8A949E",
  gallery = TRUE,
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

  A detection table, or a path to a CSV of one — such as a pull from
  GFW's `detect_scene_match_pipe` tables. Must include `detect_id`,
  `detect_lat`, `detect_lon`, `scene_id`, `presence_score` and
  `cloud_score`. Optional columns used when present: `detect_timestamp`,
  `length_m_inferred`, `matched` (logical), and `mmsi` — or `ssvid`,
  GFW's name for the same number on AIS data. Each adds a line to the
  popup and the crop's caption; `matched`, or `ssvid` standing in for
  it, is also what splits the markers into matched and unmatched, and
  the MMSI is what makes a matched detection a vessel you can look up
  rather than just an object on the water.

- cache_dir:

  Directory the crops are cached in, one PNG per detection. Defaults to
  a session temporary directory, which means every crop is pulled again
  next session — pass a real path for anything you intend to re-render.

- buffer_m:

  Half-width of the crop, in metres: the frame is twice this across.
  Default `500`, so a 1 km view in which a 30 m hull is three pixels.

- view:

  Which stretch to render: `"ocean"` (the default, and the one that
  separates a hull from a wave crest), `"natural"`, `"nir"`, or
  `"false_colour"`. Give it more than one and each detection is shown in
  all of them, side by side — `c("ocean", "nir")` is the useful pair,
  since water absorbs near-infrared almost entirely and anything solid
  comes back bright. Every extra view is another crop to render, cache
  and inline, so the cost and the file size scale with the number asked
  for.

- embed:

  Inline each crop into the page as a `data:` URI. `TRUE`, the default,
  and the only setting that produces a map worth sending anyone. `FALSE`
  links to the Earth Engine URLs instead — lighter, but the map stops
  working when those expire, which takes days.

- boundary:

  Optional `sf` polygon drawn over the imagery, e.g. an MPA.

- boundary_color:

  Colour of that outline. Default `"#B6D94C"`.

- matched_color, unmatched_color:

  Marker colours for detections matched to AIS and detections not
  matched.

- gallery:

  Give the exported map a second pane: every detection as a thumbnail,
  ordered by detection score, linked both ways to the map. Clicking a
  thumbnail flies the map there and opens the crop; opening a marker's
  popup scrolls the gallery to its thumbnail. `TRUE` by default, and it
  adds nothing to the file — the thumbnails are crops the page already
  carries. The widget this function *returns* is always the plain map,
  since a two-pane dashboard wants a full window rather than a report's
  figure column.

- legend_title:

  Heading over the legend. Defaults to the detection count.

- title:

  Map title shown in the banner on the *exported* map only (see
  `export_path`) — not on the widget this returns, since an inline
  report already has its own heading. Required if `export_path` is
  supplied.

- subtitle:

  Small text under that title. `""` hides it.

- export_path:

  If supplied, a self-contained standalone HTML copy is saved here. This
  is the shareable artefact, and with `embed = TRUE` it is the whole
  tool in one file.

- ee_project, ee_python, ee_asset_home:

  Passed to
  [`ee_connect()`](https://pristine-seas.github.io/PristineSeasR2/reference/ee_connect.md)
  if — and only if — a crop has to be rendered. `ee_project` is required
  in that case.

## Value

A `leaflet` htmlwidget. Print it to display it inline; or ignore the
return value and use `export_path`, which is usually the better read
since the map wants a full window.

## Examples

``` r
if (FALSE) { # \dontrun{
explore_s2_detections(
  detections  = s2_detections,
  cache_dir   = file.path(gfw_dir, "s2_thumbs"),
  boundary    = mpa,
  title       = "Sentinel-2 detections in Bikar-Bokak since designation",
  export_path = file.path(fig_dir, "s2_detections.html"),
  ee_project  = "pristine-seas"
)
} # }
```
