
<!-- README.md is generated from README.Rmd. Please edit that file -->

# PristineSeasR2 <img src="man/figures/logo.png" align="right" height="110" alt="" />

<p class="subtitle">

The science toolkit of National Geographic Pristine Seas
</p>

<!-- badges: start -->

[![R-CMD-check](https://github.com/pristine-seas/PristineSeasR2/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/pristine-seas/PristineSeasR2/actions/workflows/R-CMD-check.yaml)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

PristineSeasR2 is built for the [Pristine
Seas](https://www.nationalgeographic.org/society/our-programs/pristine-seas/)
research team and the collaborators and partners who work with us. Its
tools carry an expedition’s data the whole way, from raw field sheets to
the shared database to the report. It standardizes how we organize,
check, and present expedition data, helping us reduce errors and keep
our science rigorous, transparent, and reproducible.

## Installation

``` r
# install.packages("pak")
pak::pak("pristine-seas/PristineSeasR2")
```

## From field sheet to report

The tools follow an expedition’s data through its life: set up and
prepare the expedition, work at sea, process and check the data, explore
it, and publish figures, maps and tables that read as one family.

<details>

<summary>

Show code
</summary>

``` r
library(PristineSeasR2)
library(dplyr)
library(ggplot2)
```

</details>

### 1. Set up and prepare

Before the ship leaves, `create_expedition()` gives every expedition the
same folder tree on the shared Drive, so raw field sheets, processed
data and analysis-ready outputs are always where the next person expects
them.

<details>

<summary>

Show code
</summary>

``` r
create_expedition("VUT-2025")
#> Created 11 expedition folders
#> Created README.md
```

</details>

    VUT-2025/
    ├── data/
    │   ├── primary/
    │   │   ├── raw/          unmodified field data
    │   │   ├── processed/    QA/QC applied
    │   │   └── output/       analysis-ready
    │   └── secondary/        external sources
    ├── documents/  figures/  gis/  media/
    ├── presentations/  reports/  references/
    └── README.md

`ps_science_paths()` finds the shared Drive on any team member’s
machine, Mac or Windows, and returns the paths to `SCIENCE` and its
`datasets`, `expeditions` and `projects` folders, so scripts carry no
hard-coded paths.

<details>

<summary>

Show code
</summary>

``` r
paths <- ps_science_paths()

paths$expeditions
#> [1] ".../My Drive/Pristine Seas/SCIENCE/expeditions"
```

</details>

Planning also means knowing what the reefs have been through.
`get_crw_dhw_sf()` pulls NOAA Coral Reef Watch degree heating weeks for
any survey area, so the team goes in with a picture of recent thermal
stress and what to expect on the reef. The [thermal stress
article](https://pristine-seas.github.io/PristineSeasR2/articles/crw-dhw.html)
walks through it.

### 2. At sea

Tools for the field, for logging dives, stations and observations as
they happen, are the next thing this package will hold.

### 3. Process and QA/QC

Back from the field, the data is cleaned, checked against the
vocabularies and matched to the World Register of Marine Species before
anything is analysed.

Field sheets spell taxa many ways. `clean_field_names()` brings them to
one form, and can log every change it made.

<details>

<summary>

Show code
</summary>

``` r
clean_field_names(c("ACROPORA SP.", 
                    "Porites cf. lobata", 
                    "Pocillopora (damicornis)",
                    "Stylophora  pistillata"), 
                  auto_approve = TRUE)
```

</details>

    #> [1] "Acropora"              "Porites lobata"        "Pocillopora"          
    #> [4] "Stylophora pistillata"

`get_taxonomic_ranks()` fills in the classification for each accepted
AphiaID, one row per taxon, straight from WoRMS.

<details>

<summary>

Show code
</summary>

``` r
get_taxonomic_ranks(c(125286, 254941), 
                    ranks = c("phylum", "class", "order", "family"))
```

</details>

    #> # A tibble: 2 × 5
    #>   accepted_aphia_id phylum        class        order           family       
    #>               <dbl> <chr>         <chr>        <chr>           <chr>        
    #> 1            125286 Cnidaria      Octocorallia Malacalcyonacea Clavulariidae
    #> 2            254941 Echinodermata Asteroidea   Valvatida       Oreasteridae

`stratify()` turns depths into the standard survey strata, and
`station_suffix()` turns the strata into the suffixes that name a
station, the same way on every expedition.

<details>

<summary>

Show code
</summary>

``` r
depths_m <- c(2, 8, 12, 22, 45)

stratify(depths_m)
```

</details>

    #> [1] "supershallow" "shallow"      "shallow"      "deep"         "superdeep"

<details>

<summary>

Show code
</summary>

``` r
station_suffix(stratify(depths_m))
```

</details>

    #> [1] "05m" "10m" "10m" "20m" "30m"

The controlled vocabularies in `allowed_vocab`, and `validate_vocab()`,
which stops the pipeline on the first non-standard value, catch errors
before they spread into the analysis.

<details>

<summary>

Show code
</summary>

``` r
names(allowed_vocab)
```

</details>

    #> [1] "trophic_group"     "depth_strata"      "exposure"         
    #> [4] "uvs_habitats"      "functional_groups"

<details>

<summary>

Show code
</summary>

``` r
allowed_vocab$trophic_group
```

</details>

    #> [1] "shark"                   "top_predator"           
    #> [3] "lower_carnivore"         "herbivore | detritivore"
    #> [5] "planktivore"

<details>

<summary>

Show code
</summary>

``` r
validate_vocab(c("shark", "top_predator", "planktivore"), "trophic_group")
```

</details>

<details>

<summary>

Show code
</summary>

``` r
validate_vocab(c("shark", "apex_predator"), "trophic_group")
```

</details>

    #> Error:
    #> ! Invalid values found in 'trophic_group'
    #> Found 1 invalid value(s): apex_predator
    #> Allowed values: shark, top_predator, lower_carnivore, herbivore | detritivore, planktivore

### 4. Explore

Once the data is processed, `explore_uvs_sites()` puts every site on an
interactive map, coloured by region, subregion, habitat or exposure,
with the field notes in each popup, so the team can review a survey
together before anything is written up. One call, one design, every
expedition. The same family of maps covers fish biomass, benthic cover,
invertebrates and recruits with `explore_fish_biomass()`,
`explore_benthic_cover()`, `explore_invert_density()` and
`explore_recruit_density()`, and satellite vessel detections with
`explore_s2_detections()`.

<details>

<summary>

Show code
</summary>

``` r
sites <- read_csv("data/primary/output/uvs/VUT_2025_uvs_sites.csv")

# Regions and subregions differ every expedition, so their colours are set once
# in the expedition's setup script. Habitat and exposure use the house palettes.
explore_uvs_sites(sites,
                  region_palette    = c(Torba = "#4E8FA8", Shefa = "#C98A3D"),
                  subregion_palette = c(Gaua = "#DCA04F", `Mota Lava` = "#005F87",
                                        `Reef Islands` = "#A5DBE0", `Tongoa/Kuwae Crater` = "#8E81CE",
                                        Ureparapara = "#6F3F1B", `Vot Tande` = "#40AE82"),
                  title             = "Vanuatu 2025 survey sites",
                  export_path       = "figures/uvs_sites.html")
```

</details>

<img src="man/figures/README-uvs-sites.jpg" alt="" width="100%" />

### 5. Publish

Every figure, map and table draws on the same palettes and themes, so a
report from any expedition reads as Pristine Seas. `theme_ps()` sets
charts on warm paper and `theme_ps_map()` sets maps on deep water, and
both share the same type, the same palettes through `scale_fill_ps()`
and `scale_color_ps()`, and the same legend geometry, so they can sit
side by side on a page and read as a pair.

<details>

<summary>

Show code
</summary>

``` r
# Each station carries its total biomass and the share of each trophic group.
# Station values are averaged to the site, then sites to the island.
groups <- c(pct_shark = "shark", pct_top_predator = "top_predator", pct_lower_carni = "lower_carnivore",
            pct_herbi_detri = "herbivore | detritivore", pct_plankti = "planktivore")

by_island <- stations |>
  tidyr::pivot_longer(all_of(names(groups)), names_to = "trophic_group", values_to = "pct") |>
  mutate(trophic_group = groups[trophic_group], biomass = avg_biomass_gm2 * pct / 100) |>
  summarise(biomass = mean(biomass), .by = c(subregion, ps_site_id, trophic_group)) |>
  summarise(biomass = mean(biomass), .by = c(subregion, trophic_group)) |>
  mutate(share = biomass / sum(biomass), .by = subregion) |>
  mutate(subregion     = reorder(subregion, biomass, sum),
         trophic_group = factor(trophic_group, rev(names(ps_colors("trophic_group"))))) |>
  # label a segment only when it is wide enough to hold the number, in dark or
  # light text depending on how light the segment's own colour is
  mutate(label = ifelse(biomass >= 12, sprintf("%.0f%%", 100 * share), ""),
         text  = ifelse(farver::get_channel(ps_colors("trophic_group")[as.character(trophic_group)], "l", space = "lab") > 60,
                        ps_ink("chart")[["title"]], ps_ink("chart")[["canvas"]]))

n_sites <- sites |> count(subregion) |> tibble::deframe()
totals  <- by_island |> summarise(total = sum(biomass), .by = subregion)

ggplot(by_island, aes(biomass, subregion, fill = trophic_group)) +
  geom_col(width = 0.72, position = position_stack(reverse = TRUE),
           colour = ps_ink("chart")[["canvas"]], linewidth = 0.4) +
  geom_text(aes(label = label, colour = text, group = trophic_group),
            position = position_stack(vjust = 0.5, reverse = TRUE),
            size = 3.1, family = ps_font_default()) +
  geom_text(data = totals, aes(total, subregion, label = round(total)), inherit.aes = FALSE,
            hjust = -0.3, size = 3.1, colour = ps_ink("chart")[["muted"]], family = ps_font_default()) +
  scale_fill_ps("trophic_group", labels = \(x) gsub("_", " ", x)) +
  scale_colour_identity() +
  scale_x_continuous(breaks = seq(0, 300, 100), minor_breaks = seq(0, 300, 50),
                     expand = expansion(mult = c(0, 0.06))) +
  scale_y_discrete(labels = \(x) paste0(x, " (", n_sites[x], ")")) +
  labs(title    = "Fish biomass by trophic group",
       subtitle = "Tongoa/Kuwae Crater carries 70% more fish biomass than any other island, and the only sharks",
       caption  = "Pristine Seas Vanuatu 2025 expedition, underwater visual surveys. Station biomass averaged to site, then to island.",
       x = expression(Biomass~(g/m^2)), y = NULL, fill = NULL) +
  theme_ps() +
  theme(legend.position = "bottom",
        panel.grid.major.y = element_blank(),
        panel.grid.minor.x = element_line(colour = ps_ink("chart")[["grid"]], linewidth = 0.2))
```

</details>

<img src="man/figures/README-chart-1.svg" alt="" width="100%" />

A survey site map for the report is one call. `map_uvs_sites()` takes
the standard sites table, fits the frame to the sites chosen, and draws
them on satellite imagery with habitat as shape and exposure as fill, a
compass rose, a scale bar and a locator globe, all in the house style.
Here, the sites of Bikar Atoll from the bundled `rmi_2023_uvs_sites`.

<details>
<summary>Show code</summary>

``` r
map_uvs_sites(rmi_2023_uvs_sites, region = "Bikar")
```

</details>

<img src="man/figures/README-map-1.png" alt="" width="100%" />

Tables follow the same idea. `gt_theme_ps()` turns a summary into the
house table, with optional group columns, spanners and heat-filled
cells.

<details>

<summary>

Show code
</summary>

``` r
stations |>
  summarise(stations = n(), transects = sum(n_transects), biomass = mean(avg_biomass_gm2),
            .by = c(region, subregion, ps_site_id)) |>
  summarise(sites = n(), stations = sum(stations), transects = sum(transects), biomass = mean(biomass),
            .by = c(region, subregion)) |>
  gt_theme_ps(groupname_col = "region", rowname_col = "subregion",
              col_labels   = c(sites = "Sites", stations = "Stations",
                               transects = "Transects", biomass = "Mean biomass (g/m²)"),
              heatmap_cols = "biomass") |>
  gt::fmt_number(columns = "biomass", decimals = 0) |>
  gt::tab_options(table.background.color = ps_ink("chart")[["canvas"]])
```

</details>

<img src="man/figures/README-effort-table.png" alt="" width="70%" style="display: block; margin: auto;" />

## Getting help

Open an [issue](https://github.com/pristine-seas/PristineSeasR2/issues)
for bugs and requests. The package is developed by the Pristine Seas
science team and is under active development, so the API may still
change between minor versions.

<p align="center">

<img src="man/figures/wordmark.png" width="360" alt="National Geographic Pristine Seas" />
</p>
