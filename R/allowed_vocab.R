#' Allowed Vocabularies
#'
#' Standardized vocabularies for Pristine Seas data collection and analysis.
#' Use with [validate_vocab()] to check data conformance.
#'
#' @format A named list containing vocabulary vectors for different data fields
#'
#' @details
#'
#' ## trophic_group
#' Fish trophic classifications:
#' \describe{
#'   \item{shark}{All sharks}
#'   \item{top_predator}{Large predatory fish excluding sharks}
#'   \item{lower_carnivore}{Mid-level carnivorous fish}
#'   \item{herbivore | detritivore}{Plant and detritus feeding fish}
#'   \item{planktivore}{Plankton feeding fish}
#' }
#'
#' ## depth_strata
#' Survey depth categories:
#' \describe{
#'   \item{surface}{0m depth (surface observations)}
#'   \item{supershallow}{0.1 - 6m depth}
#'   \item{shallow}{6.1 - 14m depth}
#'   \item{deep}{14.1 - 30m depth}
#'   \item{superdeep}{> 30m depth}
#' }
#'
#' ## exposure
#' Site exposure conditions:
#' \describe{
#'   \item{windward}{Exposed to prevailing swell or wind; typically high wave energy and surge}
#'   \item{leeward}{Sheltered side of reef or island protected from prevailing swell}
#'   \item{lagoon}{Located inside a reef or atoll, generally protected from direct wave action}
#'   \item{channel}{Within a reef pass or surge channel; often features strong tidal currents}
#'   \item{sheltered}{Protected from wave energy by a bay or other geomorphic feature}
#'   \item{exposed}{Generally high energy due to wave or swell exposure; used where windward/leeward doesn't apply}
#'   \item{unknown}{Exposure not determined or insufficient data to classify}
#' }
#'
#' ## uvs_habitats
#' Underwater visual survey habitat classifications:
#' \describe{
#'   \item{fore_reef}{Seaward-facing outer slope of coral reef}
#'   \item{back_reef}{Lagoon-facing side behind the reef crest}
#'   \item{reef_flat}{Horizontal shallow zone near the crest}
#'   \item{patch_reef}{Isolated reef outcrop within lagoon or sand plain}
#'   \item{pinnacle_reef}{Steep-sided, often isolated coral structures}
#'   \item{bank}{Flat-topped offshore feature with reef or rocky habitat}
#'   \item{rocky_reef}{Non-coral reef formed from rock, with reef biota}
#'   \item{reef_pavement}{Flat, low-relief hard-bottom reef surface}
#'   \item{channel_pass}{Channel through reef system with strong flow}
#'   \item{wall}{Vertical or steep reef drop-off}
#'   \item{kelp_forest}{Dense canopy-forming macroalgae habitat}
#'   \item{seagrass}{Dominant seagrass bed habitat}
#' }
#'
#' ## functional_groups
#' Benthic functional group classifications:
#' \describe{
#'   \item{hard_coral}{Hard coral colonies and structures (Scleractinia)}
#'   \item{soft_coral}{Soft coral colonies, sea fans, and gorgonians}
#'   \item{algae_erect}{Erect/branching macroalgae (fleshy and calcareous)}
#'   \item{algae_encrusting}{Encrusting algal forms (non-coralline)}
#'   \item{algae_canopy}{Kelp, Sargassum, and other large canopy-forming macroalgae}
#'   \item{cca}{Crustose coralline algae}
#'   \item{turf}{Algal turf matrices (< 2cm height)}
#'   \item{cyanobacteria}{Cyanobacterial mats and films}
#'   \item{seagrass}{Seagrass species}
#'   \item{sponges}{Sponge communities and structures (Porifera)}
#'   \item{bryozoans}{Bryozoan colonies}
#'   \item{ascidians}{Tunicates and sea squirts}
#'   \item{hydrozoans}{Hydrozoan colonies (fire corals, hydroids)}
#'   \item{other_cnidarians}{Other cnidarians (anemones, zoanthids, corallimorphs)}
#'   \item{sediment | rubble | barren}{Sediment, rubble, or barren substrate}
#'   \item{eam}{Epilithic algal matrix (turf + detritus + microbes)}
#'   \item{worms}{Tube worms and other sessile polychaetes}
#'   \item{echinoderms}{Sessile echinoderms (crinoids, urchins in crevices)}
#'   \item{molluscs}{Sessile molluscs (giant clams, oysters, vermetids)}
#'   \item{forams}{Large benthic foraminifera}
#'   \item{barnacles}{Barnacle assemblages}
#'   \item{other}{Other functional groups not classified above}
#' }
#'
#' @seealso [validate_vocab()] to validate data against these vocabularies
#'
#' @examples
#' # View available vocabularies
#' names(allowed_vocab)
#'
#' # Get valid trophic groups
#' allowed_vocab$trophic_group
#'
#' # Get valid depth strata
#' allowed_vocab$depth_strata
#'
#' # Check if a value is valid
#' "shark" %in% allowed_vocab$trophic_group
#'
#' @export
allowed_vocab <- list(
  trophic_group = c(
    "shark",
    "top_predator",
    "lower_carnivore",
    "herbivore | detritivore",
    "planktivore"
  ),

  depth_strata = c(
    "surface",
    "supershallow",
    "shallow",
    "deep",
    "superdeep"
  ),

  exposure = c(
    "windward",
    "leeward",
    "lagoon",
    "channel",
    "sheltered",
    "exposed",
    "unknown"
  ),

  uvs_habitats = c(
    "fore_reef",
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
    "seagrass"
  ),

  functional_groups = c(
    "hard_coral",
    "soft_coral",
    "algae_erect",
    "algae_encrusting",
    "algae_canopy",
    "cca",
    "turf",
    "cyanobacteria",
    "seagrass",
    "sponges",
    "bryozoans",
    "ascidians",
    "hydrozoans",
    "other_cnidarians",
    "sediment | rubble | barren",
    "eam",
    "worms",
    "echinoderms",
    "molluscs",
    "forams",
    "barnacles",
    "other"
  )
)
