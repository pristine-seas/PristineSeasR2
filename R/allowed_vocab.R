#' Allowed Vocabularies
#'
#' Standardized vocabularies for Pristine Seas data collection and analysis.
#'
#' @format A named list containing vocabulary vectors for different data fields
#' @details
#' **trophic_group** - Fish trophic classifications:
#' - **shark** — All sharks
#' - **top_predator** — Large predatory fish excluding sharks
#' - **lower_carnivore** — Mid-level carnivorous fish
#' - **herbivore | detritivore** — Plant and detritus feeding fish
#' - **planktivore** — Plankton feeding fish
#'
#' **depth_strata** - Survey depth categories:
#' - **supershallow** — 0.1 - 6m depth
#' - **shallow** — 6.1 - 14m depth
#' - **deep** — 14.1 - 30m depth
#'
#' **exposure** - Site exposure conditions:
#' - **windward** — Exposed to prevailing swell or wind; typically high wave energy and surge
#' - **leeward** — Sheltered side of reef or island protected from prevailing swell
#' - **lagoon** — Located inside a reef or atoll, generally protected from direct wave action
#' - **channel** — Within a reef pass or surge channel; often features strong tidal currents
#' - **sheltered** — Protected from wave energy by a bay or other geomorphic feature
#' - **exposed** — Generally high energy due to wave or swell exposure; used where windward/leeward doesn't apply
#' - **unknown** — Exposure not determined or insufficient data to classify
#'
#' **uvs_habitats** - UVS habitat classifications:
#' - **fore_reef** — Seaward-facing outer slope of coral reef
#' - **back_reef** — Lagoon-facing side behind the reef crest
#' - **reef_flat** — Horizontal shallow zone near the crest
#' - **patch_reef** — Isolated reef outcrop within lagoon or sand plain
#' - **pinnacle_reef** — Steep-sided, often isolated coral structures
#' - **bank** — Flat-topped offshore feature with reef or rocky habitat
#' - **rocky_reef** — Non-coral reef formed from rock, with reef biota
#' - **reef_pavement** — Flat, low-relief hard-bottom reef surface
#' - **channel_pass** — Channel through reef system with strong flow
#' - **wall** — Vertical or steep reef drop-off
#' - **kelp_forest** — Dense canopy-forming macroalgae habitat
#' - **seagrass** — Dominant seagrass bed habitat
#'
#' **functional_groups** - Benthic functional group classifications:
#' - **hard_coral** — Hard coral colonies and structures
#' - **cca** — Crustose coralline algae
#' - **cyanobacteria** — Cyanobacterial mats and films
#' - **soft_coral** — Soft coral colonies and sea fans
#' - **sponges** — Sponge communities and structures
#' - **erect_algae** — Erect/branching macroalgae
#' - **encrusting_algae** — Encrusting algal forms
#' - **turf** — Algal turf matrices
#' - **sediment|rubble|barren** — Sediment, rubble, or barren substrate
#' - **other** — Other functional groups not classified above
#' @export
allowed_vocab <- list(trophic_group = c("shark",
                                        "top_predator",
                                        "lower_carnivore",
                                        "herbivore | detritivore",
                                        "planktivore"),

                      depth_strata = c("supershallow",
                                       "shallow",
                                       "deep"),

                      exposure = c("windward",
                                   "leeward",
                                   "lagoon",
                                   "channel",
                                   "sheltered",
                                   "exposed",
                                   "unknown"),

                      uvs_habitats = c("fore_reef",
                                       "back_reef",
                                       "reef_flat",
                                       "patch_reef",
                                       "pinnacle_reef",
                                       "bank",
                                       "rocky_reef",
                                       "reef_pavement",
                                       "channel_pass",
                                       "wall",
                                       "kelp_forest",
                                       "seagrass"),

                      functional_groups = c("hard_coral",
                                            "cca",
                                            "cyanobacteria",
                                            "soft_coral",
                                            "sponges",
                                            "erect_algae",
                                            "encrusting_algae",
                                            "turf",
                                            "sediment|rubble|barren",
                                            "eam",
                                            "other")
                      )
