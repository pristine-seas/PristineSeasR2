# get_taxonomic_ranks.R ---------------------------------------------------------
# Higher taxonomic ranks (kingdom -> genus) from WoRMS, by AphiaID
#
# Public API:
#   - get_taxonomic_ranks(): vectorized, tidy wrapper around worrms::wm_classification()
#
# Internal helpers (not exported / not documented):
#   - wm_classification_one()

#' Get Higher Taxonomic Ranks from WoRMS by AphiaID
#'
#' @description
#' Looks up the full taxonomic classification for one or more AphiaIDs from
#' the World Register of Marine Species ([WoRMS](https://www.marinespecies.org/))
#' via [worrms::wm_classification()], and reshapes it into one row per AphiaID
#' with one column per requested rank (`kingdom`, `phylum`, `class`, `order`,
#' `family`, `genus` by default).
#'
#' This is the lookup typically needed after matching field-recorded taxon
#' names against WoRMS (e.g. with [worrms::wm_records_names()]) to fill in
#' the higher-rank classification for taxa that are new to a reference table.
#'
#' @param aphia_ids Numeric (or coercible) vector of AphiaIDs to look up.
#'   `NA` values are returned as all-`NA` rows without an API call.
#' @param ranks Character vector of taxonomic ranks to return as columns, in
#'   the order they should appear in the output. Matched case-insensitively
#'   against WoRMS' rank labels. Defaults to
#'   `c("kingdom", "phylum", "class", "order", "family", "genus")`.
#'
#' @details
#' A failed lookup for one AphiaID — an invalid or retired ID, a name WoRMS
#' doesn't recognize, a network hiccup — never stops the whole batch: that
#' ID's row comes back with `NA` in every rank column rather than an error.
#' Failures are silent by design (no message per failed ID); check for
#' all-`NA` rows in the output if you need to audit them.
#'
#' Every rank named in `ranks` is guaranteed to appear as a column in the
#' output, even if *none* of the queried taxa have a value at that rank. A
#' naive pivot-to-wide reshape only creates a column for ranks that actually
#' show up in the data, which would silently drop that rank from the output
#' instead of reporting it as missing — this function fills it with `NA`
#' instead, so a downstream join on a fixed set of expected columns doesn't
#' fail just because this batch happened not to touch that rank.
#'
#' ## Parallelizing lookups
#' Lookups run one AphiaID at a time, through [furrr::future_map_dfr()] when
#' the \pkg{furrr} package is installed (falling back to [purrr::map_dfr()]
#' otherwise, which is always sequential). To parallelize, set a plan
#' *before* calling this function — the function itself never changes the
#' plan:
#' ```r
#' future::plan(future::multisession, workers = 4)
#' get_taxonomic_ranks(new_taxa$accepted_aphia_id)
#' ```
#' Without an explicit plan (or without \pkg{furrr} installed), lookups run
#' sequentially.
#'
#' @return A [tibble][tibble::tibble] with one row per element of
#'   `aphia_ids` and columns `accepted_aphia_id` followed by one column per
#'   entry in `ranks`.
#'
#' @seealso [clean_field_names()] to standardize taxon names before matching
#'   them against WoRMS; [worrms::wm_records_names()] for the name-matching
#'   step that typically precedes this lookup.
#'
#' @examples
#' \dontrun{
#' # sequential
#' get_taxonomic_ranks(c(125286, 254941))
#'
#' # only kingdom/phylum/class
#' get_taxonomic_ranks(c(125286, 254941), ranks = c("kingdom", "phylum", "class"))
#'
#' # parallel, e.g. for a large batch of newly-encountered taxa
#' future::plan(future::multisession, workers = 4)
#' get_taxonomic_ranks(new_taxa$accepted_aphia_id)
#' }
#'
#' @importFrom rlang .data
#' @export
get_taxonomic_ranks <- function(aphia_ids,
                                 ranks = c("kingdom", "phylum", "class",
                                           "order", "family", "genus")) {

  if (!requireNamespace("worrms", quietly = TRUE)) {
    stop("Package 'worrms' is required for get_taxonomic_ranks(). ",
         "Install it with install.packages('worrms').", call. = FALSE)
  }

  ranks <- unique(tolower(ranks))

  if (length(aphia_ids) == 0) {
    out <- tibble::tibble(accepted_aphia_id = numeric(0))
    for (col in ranks) out[[col]] <- character(0)
    return(out)
  }

  aphia_ids_num <- suppressWarnings(as.numeric(aphia_ids))
  bad <- is.na(aphia_ids_num) & !is.na(aphia_ids)
  if (any(bad)) {
    warning(sum(bad), " value(s) in `aphia_ids` could not be coerced to ",
            "numeric and will be returned as NA rows: ",
            paste(utils::head(aphia_ids[bad], 5), collapse = ", "),
            if (sum(bad) > 5) ", ..." else "", call. = FALSE)
  }
  aphia_ids <- aphia_ids_num

  has_furrr <- requireNamespace("furrr", quietly = TRUE)

  if (has_furrr) {
    results <- furrr::future_map_dfr(aphia_ids, wm_classification_one,
                                      .options = furrr::furrr_options(seed = TRUE))
  } else {
    results <- purrr::map_dfr(aphia_ids, wm_classification_one)
  }

  # guarantee every requested rank exists as a column, even if unobserved
  # across every queried taxon in this batch
  for (col in setdiff(ranks, names(results))) {
    results[[col]] <- NA_character_
  }

  dplyr::select(results, "accepted_aphia_id", dplyr::any_of(ranks))
}

wm_classification_one <- function(id) {
  if (is.na(id)) return(tibble::tibble(accepted_aphia_id = id))

  tryCatch({
    cls  <- worrms::wm_classification(id)
    vals <- stats::setNames(as.list(cls$scientificname), tolower(cls$rank))
    tibble::tibble(accepted_aphia_id = id, !!!vals)
  }, error = function(e) {
    tibble::tibble(accepted_aphia_id = id)
  })
}
