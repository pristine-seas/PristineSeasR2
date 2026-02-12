#' Validate Values Against Allowed Vocabularies
#'
#' Checks whether all values conform to Pristine Seas standardized vocabularies.
#' Use early in data processing pipelines to catch non-standard entries before
#' analysis. Stops with an informative error if invalid values are found.
#'
#' @param x Character vector of values to validate.
#' @param vocab Character string naming the vocabulary to validate against.
#'   One of: `"trophic_group"`, `"depth_strata"`, `"exposure"`,
#'   `"uvs_habitats"`, `"functional_groups"`.
#' @return Returns `TRUE` invisibly if all values are valid.
#'   Stops with an error if any invalid values are found.
#'
#' @details
#' This function is designed as a gatekeeper for data quality. Place it early
#' in your pipeline to ensure data conforms to standards before analysis.
#'
#' **On success:** Prints a confirmation message and returns `TRUE` invisibly.
#'
#' **On failure:** Stops with an error listing:
#' - Number and identity of invalid values
#' - All allowed values for reference
#'
#' For filtering data (rather than validating), use `%in%` directly:
#' ```
#' df |> filter(trophic %in% allowed_vocab$trophic_group)
#' ```
#'
#' @seealso [allowed_vocab] for the vocabularies and their definitions
#'
#' @examples
#' # Successful validation (prints message, returns TRUE invisibly)
#' validate_vocab(c("shark", "planktivore"), "trophic_group")
#'
#' # NAs trigger a warning
#' validate_vocab(c("shallow", NA, "deep"), "depth_strata")
#' #> Warning: Found 1 NA value(s) in 'depth_strata'
#' #> ✓ All 3 values valid for 'depth_strata'
#'
#' # Use in a processing pipeline
#' \dontrun{
#' raw_data <- read.csv("fish_surveys.csv")
#'
#' # Validate before proceeding
#' validate_vocab(raw_data$trophic_group, "trophic_group")
#' validate_vocab(raw_data$depth_strata, "depth_strata")
#'
#' # Continue with clean data...
#' }
#'
#' # Invalid values trigger an error
#' \dontrun{
#' validate_vocab(c("shark", "apex_predator"), "trophic_group")
#' #> Error: Invalid values found in 'trophic_group'
#' #> Found 1 invalid value: apex_predator
#' #> Allowed values: shark, top_predator, lower_carnivore, ...
#' }
#'
#' # Filtering (don't use validate_vocab, use %in% directly)
#' \dontrun{
#' df |> filter(habitat %in% allowed_vocab$uvs_habitats)
#' }
#'
#' @export
validate_vocab <- function(x, vocab) {


  # Validate vocab argument
  available_vocabs <- names(allowed_vocab)

  if (!vocab %in% available_vocabs) {
    stop(
      "Unknown vocabulary: '", vocab, "'\n",
      "Available: ", paste(available_vocabs, collapse = ", "),
      call. = FALSE
    )
  }

  # Get allowed values
  allowed <- allowed_vocab[[vocab]]

  # Coerce to character
  if (!is.character(x)) {
    x <- as.character(x)
  }

  # Identify invalid values (excluding NA for now)
  non_na_values <- x[!is.na(x)]
  invalid_values <- unique(non_na_values[!non_na_values %in% allowed])
  n_invalid <- sum(!non_na_values %in% allowed)

  # Warn about NAs
  n_na <- sum(is.na(x))
  if (n_na > 0) {
    warning(
      "Found ", n_na, " NA value(s) in '", vocab, "'",
      call. = FALSE
    )
  }

  # Error on invalid values
  if (length(invalid_values) > 0) {
    stop(
      "Invalid values found in '", vocab, "'\n",
      "Found ", n_invalid, " invalid value(s): ",
      paste(invalid_values, collapse = ", "), "\n",
      "Allowed values: ", paste(allowed, collapse = ", "),
      call. = FALSE
    )
  }


  # Success message
  n_valid <- length(non_na_values)
  message("\u2713 ", n_valid, " valid value(s) for '", vocab, "'")
  invisible(TRUE)
}
