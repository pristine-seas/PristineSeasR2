# Thermal stress (DHW) from NOAA Coral Reef Watch

This vignette shows how to retrieve **NOAA Coral Reef Watch Degree
Heating Week (DHW)** (°C-weeks) from NOAA’s ERDDAP servers using
**PristineSeasR2**.

**DHW** is a cumulative measure of heat stress that integrates both
intensity and duration of anomalous temperatures. It is widely used as a
high-level indicator of bleaching risk and historical thermal exposure.

You can query DHW using:

- [`get_crw_dhw_bbox()`](https://pristine-seas.github.io/PristineSeasR2/reference/get_crw_dhw_bbox.md)
  for a numeric bounding box (lat/lon), or
- [`get_crw_dhw_sf()`](https://pristine-seas.github.io/PristineSeasR2/reference/get_crw_dhw_sf.md)
  for an `sf` feature (the function derives a bbox from the geometry).

By default,
[`get_crw_dhw_sf()`](https://pristine-seas.github.io/PristineSeasR2/reference/get_crw_dhw_sf.md)
returns a **daily mean DHW** across all grid cells within the feature’s
bounding box

- `summarise_daily = TRUE` **(default)** - daily mean DHW time series
  (recommended for comparisons)
- `summarise_daily = FALSE` - raw gridded values (one row per grid cell
  per day), useful for QC or spatial heterogeneity checks

> Practical note: these helpers query by **bounding box**. This is
> typically stable at the CRW grid resolution and is fast and robust for
> atoll or island scale comparisons.

## Query by coords (numeric bbox)

Use
[`get_crw_dhw_bbox()`](https://pristine-seas.github.io/PristineSeasR2/reference/get_crw_dhw_bbox.md)
when you already know your bounding box in WGS84 (EPSG:4326). This
returns **gridded** values (lat/lon pixels) for each day.

``` r
# Bounding box for Jemo Island, Marshall Islands
lat_min <- 10.0547
lat_max <- 10.1306
lon_min <- 169.5001
lon_max <- 169.5905

dhw_grid <- get_crw_dhw_bbox(lat_min = lat_min,
                             lat_max = lat_max,
                             lon_min = lon_min,
                             lon_max = lon_max,
                             start   = "2023-01-01",
                             end     = "2025-12-31",
                             verbose = TRUE)
#>   Fetching 2023...
#>   Fetching 2024...
#>   Fetching 2025...

head(dhw_grid)
#> # A tibble: 6 × 4
#>   date       latitude longitude   dhw
#>   <date>        <dbl>     <dbl> <dbl>
#> 1 2023-01-01     10.1      170.     0
#> 2 2023-01-01     10.1      170.     0
#> 3 2023-01-01     10.1      170.     0
#> 4 2023-01-01     10.1      170.     0
#> 5 2023-01-02     10.1      170.     0
#> 6 2023-01-02     10.1      170.     0
```

#### Summarize by day (daily mean across the bbox)

A common pattern is to collapse the gridded output into a single daily
mean DHW time series, which is what
[`get_crw_dhw_sf()`](https://pristine-seas.github.io/PristineSeasR2/reference/get_crw_dhw_sf.md)
does by default.

``` r
dhw_daily <- dhw_grid |>
  group_by(date) |>
  summarise(avg_dhw = mean(dhw, na.rm = TRUE), .groups = "drop")

head(dhw_daily)
#> # A tibble: 6 × 2
#>   date       avg_dhw
#>   <date>       <dbl>
#> 1 2023-01-01       0
#> 2 2023-01-02       0
#> 3 2023-01-03       0
#> 4 2023-01-04       0
#> 5 2023-01-05       0
#> 6 2023-01-06       0
```

## Query by `sf` feature (recommended)

Use
[`get_crw_dhw_sf()`](https://pristine-seas.github.io/PristineSeasR2/reference/get_crw_dhw_sf.md)
when you have an `sf` polygon (atoll, reef area, MPA boundary, site
footprint, etc.). The function will:

1.  transform the geometry to WGS84 (EPSG:4326)
2.  compute the bounding box
3.  query ERDDAP in yearly chunks
4.  **return a daily mean DHW time series by default**
    (`summarise_daily = TRUE`)

``` r
# Create sf features for Samoa islands from bounding box coordinates

# Savaii
savaii <- st_as_sfc(st_bbox(c(xmin = -172.87, xmax = -172.12, 
                              ymin = -13.90, ymax = -13.31), 
                            crs = 4326)) |>
  st_as_sf() |>
  mutate(island = "Savaii")

# Upolu  
upolu <- st_as_sfc(st_bbox(c(xmin = -172.12, xmax = -171.34,
                             ymin = -14.16, ymax = -13.63),
                           crs = 4326)) |>
  st_as_sf() |>
  mutate(island = "Upolu")

# Combine
AOIs <- bind_rows(savaii, upolu)
AOIs
#> Simple feature collection with 2 features and 1 field
#> Geometry type: POLYGON
#> Dimension:     XY
#> Bounding box:  xmin: -172.87 ymin: -14.16 xmax: -171.34 ymax: -13.31
#> Geodetic CRS:  WGS 84
#>   island                              x
#> 1 Savaii POLYGON ((-172.87 -13.9, -1...
#> 2  Upolu POLYGON ((-172.12 -14.16, -...
```

### Single AOI example

``` r
savaii_dhw <- get_crw_dhw_sf(feature  = savaii,
                             start    = "2023-01-01",
                             end      = "2024-12-31",
                             name_col = "island",
                             out_col  = "island",
                             summarise_daily = TRUE,
                             verbose  = TRUE)
#> Fetching DHW for Savaii...
#>   Fetching 2023...
#>   Fetching 2024...

savaii_dhw
#> # A tibble: 731 × 3
#>    island date       avg_dhw
#>    <chr>  <date>       <dbl>
#>  1 Savaii 2023-01-01       0
#>  2 Savaii 2023-01-02       0
#>  3 Savaii 2023-01-03       0
#>  4 Savaii 2023-01-04       0
#>  5 Savaii 2023-01-05       0
#>  6 Savaii 2023-01-06       0
#>  7 Savaii 2023-01-07       0
#>  8 Savaii 2023-01-08       0
#>  9 Savaii 2023-01-09       0
#> 10 Savaii 2023-01-10       0
#> # ℹ 721 more rows
```

## Multiple AOIs

For multiple features, iterate over rows and bind results. This keeps
the core function simple (one feature in, one feature out) while still
supporting batch workflows.

``` r
dhw_samoa <- map_dfr(seq_len(nrow(AOIs)), \(i) {
  get_crw_dhw_sf(feature  = AOIs[i, ],
                 start    = "2023-01-01",
                 end      = "2025-12-31",
                 name_col = "island",
                 out_col  = "island",
                 summarise_daily = TRUE,
                 verbose  = TRUE)
})
#> Fetching DHW for Savaii...
#>   Fetching 2023...
#>   Fetching 2024...
#>   Fetching 2025...
#> Fetching DHW for Upolu...
#>   Fetching 2023...
#>   Fetching 2024...
#>   Fetching 2025...

dhw_samoa
#> # A tibble: 2,192 × 3
#>    island date       avg_dhw
#>    <chr>  <date>       <dbl>
#>  1 Savaii 2023-01-01       0
#>  2 Savaii 2023-01-02       0
#>  3 Savaii 2023-01-03       0
#>  4 Savaii 2023-01-04       0
#>  5 Savaii 2023-01-05       0
#>  6 Savaii 2023-01-06       0
#>  7 Savaii 2023-01-07       0
#>  8 Savaii 2023-01-08       0
#>  9 Savaii 2023-01-09       0
#> 10 Savaii 2023-01-10       0
#> # ℹ 2,182 more rows
```

## Plotting DHW time series

This plot visualizes the daily mean DHW histories for both islands. The
horizontal reference lines are common heuristics:

- **4 DHW**: elevated bleaching risk
- **8 DHW**: severe bleaching / high mortality risk

These are rules of thumb and should be interpreted with context
(seasonality, species composition, local adaptation, survey
observations).

``` r
x_annot <- min(dhw_samoa$date, na.rm = TRUE)

dhw_samoa |>
  ggplot(aes(x = date, y = avg_dhw, color = island)) +
  geom_line(linewidth = 0.9, alpha = 0.85) +
  geom_hline(yintercept = 4, linetype = "dashed", color = "grey30", linewidth = 0.5) +
  geom_hline(yintercept = 8, linetype = "dotted", color = "grey30", linewidth = 0.5) +
  annotate("text", x = x_annot, y = 4.5, label = "Bleaching threshold (~4 DHW)",
           size = 3, color = "grey30", hjust = 0) +
  annotate("text", x = x_annot, y = 8.5, label = "Severe threshold (~8 DHW)",
           size = 3, color = "grey30", hjust = 0) +
  scale_color_manual(values = c("Savaii" = "#2E6F95", "Upolu" = "#E07A5F")) +
  scale_x_date(date_breaks = "3 months", date_labels = "%Y-%m") +
  scale_y_continuous(name = "DHW (°C-weeks)", limits = c(0, NA)) +
  labs(title = "Thermal stress histories: Samoa",
       subtitle = "NOAA Coral Reef Watch Degree Heating Weeks (DHW)",
       x = NULL,
       color = NULL,
       caption = "Source: NOAA Coral Reef Watch via ERDDAP") +
  theme_ps()
```

![](crw-dhw_files/figure-html/plot-dhw-1.png)
