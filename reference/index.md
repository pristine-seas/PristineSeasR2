# Package index

## Expedition setup

The shared Drive, the standard folder tree, and who is on the team.

- [`create_expedition()`](https://pristine-seas.github.io/PristineSeasR2/reference/create_expedition.md)
  : Create New Pristine Seas Expedition Structure
- [`create_expedition_readme()`](https://pristine-seas.github.io/PristineSeasR2/reference/create_expedition_readme.md)
  : Create Expedition README Template
- [`create_project()`](https://pristine-seas.github.io/PristineSeasR2/reference/create_project.md)
  : Create New Pristine Seas Project Structure
- [`ps_science_paths()`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_science_paths.md)
  [`get_drive_paths()`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_science_paths.md)
  : Find the Pristine Seas SCIENCE folder on this machine
- [`ps_researchers`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_researchers.md)
  : Scientists Lookup Table

## Vocabularies and validation

The controlled vocabularies survey data must follow, and the tools that
hold it to them.

- [`allowed_vocab`](https://pristine-seas.github.io/PristineSeasR2/reference/allowed_vocab.md)
  : Allowed Vocabularies
- [`validate_vocab()`](https://pristine-seas.github.io/PristineSeasR2/reference/validate_vocab.md)
  : Validate Values Against Allowed Vocabularies
- [`clean_field_names()`](https://pristine-seas.github.io/PristineSeasR2/reference/clean_field_names.md)
  : Clean Taxonomic Field Names from Benthic LPI Surveys
- [`validate_and_export_csv()`](https://pristine-seas.github.io/PristineSeasR2/reference/validate_and_export_csv.md)
  : Validate a Data Frame's Columns Against a BigQuery Table, Then
  Export to CSV
- [`stratify()`](https://pristine-seas.github.io/PristineSeasR2/reference/stratify.md)
  : Stratify Depths into Standard Categories
- [`station_suffix()`](https://pristine-seas.github.io/PristineSeasR2/reference/station_suffix.md)
  : Get Station Suffix from Depth Strata

## Exploration maps

Interactive maps of a survey while the expedition is still at sea. One
design, every protocol.

- [`explore_uvs_sites()`](https://pristine-seas.github.io/PristineSeasR2/reference/explore_uvs_sites.md)
  : Build the Interactive UVS Sites Map (Color-By
  Region/Subregion/Habitat/Exposure)

- [`explore_fish_biomass()`](https://pristine-seas.github.io/PristineSeasR2/reference/explore_fish_biomass.md)
  : Build the Interactive Fish Survey Results Map (Metric Toggle by
  Site)

- [`explore_benthic_cover()`](https://pristine-seas.github.io/PristineSeasR2/reference/explore_benthic_cover.md)
  : Build the Interactive Benthic Cover Map (Pie Charts by Site)

- [`explore_invert_density()`](https://pristine-seas.github.io/PristineSeasR2/reference/explore_invert_density.md)
  : Build the Interactive Invertebrate Survey Results Map (Metric Toggle
  by Site)

- [`explore_recruit_density()`](https://pristine-seas.github.io/PristineSeasR2/reference/explore_recruit_density.md)
  : Build the Interactive Recruit Density Map (Circle Markers by Site)

- [`default_benthic_cover_groups()`](https://pristine-seas.github.io/PristineSeasR2/reference/default_benthic_cover_groups.md)
  :

  Standard Benthic Cover Groups for
  [`explore_benthic_cover()`](https://pristine-seas.github.io/PristineSeasR2/reference/explore_benthic_cover.md)

## Report maps

Survey sites on satellite imagery, in the house style, for the page.

- [`map_uvs_sites()`](https://pristine-seas.github.io/PristineSeasR2/reference/map_uvs_sites.md)
  : Map underwater visual survey sites

## Satellite detections

Global Fishing Watch vessel detections, each with the imagery it was
made from.

- [`explore_s1_detections()`](https://pristine-seas.github.io/PristineSeasR2/reference/explore_s1_detections.md)
  : Explore Sentinel-1 detections
- [`explore_s2_detections()`](https://pristine-seas.github.io/PristineSeasR2/reference/explore_s2_detections.md)
  : Explore Sentinel-2 Vessel Detections, With The Imagery Behind Each
  One
- [`ee_connect()`](https://pristine-seas.github.io/PristineSeasR2/reference/ee_connect.md)
  : Connect to Google Earth Engine

## Figures and tables

One design in two inks. Charts on paper, maps on water, and the house
table styles.

- [`theme_ps()`](https://pristine-seas.github.io/PristineSeasR2/reference/theme_ps.md)
  : Pristine Seas chart theme
- [`theme_ps_map()`](https://pristine-seas.github.io/PristineSeasR2/reference/theme_ps_map.md)
  : Pristine Seas map theme
- [`ps_ink()`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_ink.md)
  [`ps_theme_colors()`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_ink.md)
  : The Ink Behind The Themes
- [`ps_font_default()`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_font_default.md)
  : The Pristine Seas house typeface
- [`guide_ps_colourbar()`](https://pristine-seas.github.io/PristineSeasR2/reference/guide_ps_colourbar.md)
  : A colourbar proportioned for Pristine Seas figures
- [`gt_theme_ps()`](https://pristine-seas.github.io/PristineSeasR2/reference/gt_theme_ps.md)
  : Pristine Seas gt Theme for Summary Tables
- [`gt_theme_ps_light()`](https://pristine-seas.github.io/PristineSeasR2/reference/gt_theme_ps_light.md)
  [`light_gt()`](https://pristine-seas.github.io/PristineSeasR2/reference/gt_theme_ps_light.md)
  : The Light, Compact Pristine Seas gt Style

## Colour and shape

The data palettes and the habitat shapes, and the ggplot2 scales that
use them.

- [`ps_colors()`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_colors.md)
  : Get Pristine Seas colors
- [`ps_habitat_colors()`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_habitat_colors.md)
  : Assign the habitat palette to the habitats a trip sampled
- [`ps_show_palette()`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_show_palette.md)
  : Preview a Pristine Seas palette
- [`scale_fill_ps()`](https://pristine-seas.github.io/PristineSeasR2/reference/scale_fill_ps.md)
  : Discrete fill scale using Pristine Seas palettes
- [`scale_color_ps()`](https://pristine-seas.github.io/PristineSeasR2/reference/scale_color_ps.md)
  : Discrete color scale using Pristine Seas palettes
- [`ps_shapes()`](https://pristine-seas.github.io/PristineSeasR2/reference/ps_shapes.md)
  : Get Pristine Seas shapes
- [`scale_shape_ps()`](https://pristine-seas.github.io/PristineSeasR2/reference/scale_shape_ps.md)
  : Discrete shape scale using Pristine Seas shape palettes

## Environment and taxonomy

Context from outside the survey.

- [`get_crw_dhw_bbox()`](https://pristine-seas.github.io/PristineSeasR2/reference/get_crw_dhw_bbox.md)
  : Fetch NOAA CRW DHW (Degree Heating Week) for a bounding box (bbox)

- [`get_crw_dhw_sf()`](https://pristine-seas.github.io/PristineSeasR2/reference/get_crw_dhw_sf.md)
  :

  Fetch NOAA CRW DHW for an `sf` feature's bounding box

- [`get_taxonomic_ranks()`](https://pristine-seas.github.io/PristineSeasR2/reference/get_taxonomic_ranks.md)
  : Get Higher Taxonomic Ranks from WoRMS by AphiaID

## Data

A real expedition to try the tools on.

- [`rmi_2023_uvs_sites`](https://pristine-seas.github.io/PristineSeasR2/reference/rmi_2023_uvs_sites.md)
  : Underwater visual survey sites of the 2023 Marshall Islands
  expedition

## Package

- [`PristineSeasR2`](https://pristine-seas.github.io/PristineSeasR2/reference/PristineSeasR2-package.md)
  [`PristineSeasR2-package`](https://pristine-seas.github.io/PristineSeasR2/reference/PristineSeasR2-package.md)
  : PristineSeasR2: The Science Toolkit of National Geographic Pristine
  Seas
