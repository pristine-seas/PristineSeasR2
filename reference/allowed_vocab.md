# Allowed Vocabularies

Standardized vocabularies for Pristine Seas data collection and
analysis. Use with
[`validate_vocab()`](https://pristine-seas.github.io/PristineSeasR2/reference/validate_vocab.md)
to check data conformance.

## Usage

``` r
allowed_vocab
```

## Format

A named list containing vocabulary vectors for different data fields

## Details

### trophic_group

Fish trophic classifications:

- shark:

  All sharks

- top_predator:

  Large predatory fish excluding sharks

- lower_carnivore:

  Mid-level carnivorous fish

- herbivore \| detritivore:

  Plant and detritus feeding fish

- planktivore:

  Plankton feeding fish

### depth_strata

Survey depth categories:

- surface:

  0m depth (surface observations)

- supershallow:

  0.1 - 6m depth

- shallow:

  6.1 - 14m depth

- deep:

  14.1 - 30m depth

- superdeep:

  \> 30m depth

### exposure

Site exposure conditions:

- windward:

  Exposed to prevailing swell or wind; typically high wave energy and
  surge

- leeward:

  Sheltered side of reef or island protected from prevailing swell

- lagoon:

  Located inside a reef or atoll, generally protected from direct wave
  action

- channel:

  Within a reef pass or surge channel; often features strong tidal
  currents

- sheltered:

  Protected from wave energy by a bay or other geomorphic feature

- exposed:

  Generally high energy due to wave or swell exposure; used where
  windward/leeward doesn't apply

- unknown:

  Exposure not determined or insufficient data to classify

### uvs_habitats

Underwater visual survey habitat classifications:

- fore_reef:

  Seaward-facing outer slope of coral reef

- back_reef:

  Lagoon-facing side behind the reef crest

- reef_flat:

  Horizontal shallow zone near the crest

- patch_reef:

  Isolated reef outcrop within lagoon or sand plain

- pinnacle_reef:

  Steep-sided, often isolated coral structures

- bank:

  Flat-topped offshore feature with reef or rocky habitat

- rocky_reef:

  Non-coral reef formed from rock, with reef biota

- reef_pavement:

  Flat, low-relief hard-bottom reef surface

- channel_pass:

  Channel through reef system with strong flow

- wall:

  Vertical or steep reef drop-off

- kelp_forest:

  Dense canopy-forming macroalgae habitat

- seagrass:

  Dominant seagrass bed habitat

### functional_groups

Benthic functional group classifications:

- hard_coral:

  Hard coral colonies and structures (Scleractinia)

- soft_coral:

  Soft coral colonies, sea fans, and gorgonians

- algae_erect:

  Erect/branching macroalgae (fleshy and calcareous)

- algae_encrusting:

  Encrusting algal forms (non-coralline)

- algae_canopy:

  Kelp, Sargassum, and other large canopy-forming macroalgae

- cca:

  Crustose coralline algae

- turf:

  Algal turf matrices (\< 2cm height)

- cyanobacteria:

  Cyanobacterial mats and films

- seagrass:

  Seagrass species

- sponges:

  Sponge communities and structures (Porifera)

- bryozoans:

  Bryozoan colonies

- ascidians:

  Tunicates and sea squirts

- hydrozoans:

  Hydrozoan colonies (fire corals, hydroids)

- other_cnidarians:

  Other cnidarians (anemones, zoanthids, corallimorphs)

- sediment \| rubble \| barren:

  Sediment, rubble, or barren substrate

- eam:

  Epilithic algal matrix (turf + detritus + microbes)

- worms:

  Tube worms and other sessile polychaetes

- echinoderms:

  Sessile echinoderms (crinoids, urchins in crevices)

- molluscs:

  Sessile molluscs (giant clams, oysters, vermetids)

- forams:

  Large benthic foraminifera

- barnacles:

  Barnacle assemblages

- other:

  Other functional groups not classified above

## See also

[`validate_vocab()`](https://pristine-seas.github.io/PristineSeasR2/reference/validate_vocab.md)
to validate data against these vocabularies

## Examples

``` r
# View available vocabularies
names(allowed_vocab)
#> [1] "trophic_group"     "depth_strata"      "exposure"         
#> [4] "uvs_habitats"      "functional_groups"

# Get valid trophic groups
allowed_vocab$trophic_group
#> [1] "shark"                   "top_predator"           
#> [3] "lower_carnivore"         "herbivore | detritivore"
#> [5] "planktivore"            

# Get valid depth strata
allowed_vocab$depth_strata
#> [1] "surface"      "supershallow" "shallow"      "deep"         "superdeep"   

# Check if a value is valid
"shark" %in% allowed_vocab$trophic_group
#> [1] TRUE
```
