#' Clean Taxonomic Field Names from Benthic LPI Surveys
#'
#' @description
#' Interactively cleans and standardizes taxonomic names from benthic Line Point
#' Intercept (LPI) surveys. The function processes names through multiple cleaning
#' steps, asking for user approval at each stage to prevent unintended data loss.
#'
#' This function is specifically designed for marine benthic taxonomy and implements
#' field-tested rules for handling taxonomic uncertainty markers, species-level
#' designations, and common field survey artifacts.
#'
#' @param x Character vector of taxonomic names to clean
#' @param return_log Logical. If `TRUE`, returns a list with both cleaned names
#'   and a data frame logging all changes. If `FALSE` (default), returns only
#'   the cleaned character vector. Default: `FALSE`
#' @param auto_approve Logical. If `TRUE`, applies all cleaning steps without
#'   interactive prompts. Use with caution - recommended only after reviewing
#'   changes with `auto_approve = FALSE` first. Default: `FALSE`
#'
#' @details
#' ## Cleaning Steps
#'
#' The function applies the following transformations in sequence:
#'
#' ### 1. Remove Parentheses and Quotes
#' Removes content in parentheses and quotation marks (including nested):
#' - `Pocillopora (damicornis)` → `Pocillopora`
#' - `Pocillopora ((nested))` → `Pocillopora`
#' - `Turbinaria "mesenterina"` → `Turbinaria`
#'
#' ### 2. Truncate at sp./spp.
#' Removes species-level uncertainty markers and keeps only genus:
#' - `Acropora sp.` → `Acropora`
#' - `Porites spp` → `Porites`
#'
#' Pattern matching uses word boundaries to avoid truncating valid names
#' (e.g., "Dispar" is preserved).
#'
#' ### 3. Handle Uncertainty Markers
#'
#' **aff. (affinis)** - Strong uncertainty, drops epithet:
#' - `Montipora aff. capitata` → `Montipora`
#' - `Montipora Aff. capitata` → `Montipora`
#' - Indicates the specimen is similar to but likely not the named species
#'
#' **cf. (confer)** - Mild uncertainty, keeps epithet:
#' - `Porites cf. lobata` → `Porites lobata`
#' - Indicates comparison with named species, higher confidence
#'
#' ### 4. Handle Unknown + Taxonomic Group
#' Converts "unknown" + group to proper higher taxonomy:
#' - `Unknown coral` → `Scleractinia`
#' - `Unknown sponge` → `Porifera`
#' - `Unidentified` alone → `NA`
#'
#' ### 5. Remove '-like' Qualifiers
#' Removes qualifiers indicating morphological similarity:
#' - `Millepora-like` → `Millepora`
#' - `Millepora-like organism` → `Millepora`
#' - Handles various dash types: `-`, `–`, `—`
#'
#' ### 6. Standardize Capitalization
#' Converts to proper taxonomic case (genus capitalized, epithet lowercase):
#' - `ACROPORA PALMATA` → `Acropora palmata`
#' - `porites lobata` → `Porites lobata`
#'
#' ### 7. Whitespace Cleanup
#' Removes extra spaces and trims leading/trailing whitespace
#'
#' ## Interactive Workflow
#'
#' At each step, the function:
#' 1. Shows proposed changes with before/after comparison
#' 2. Displays up to 20 examples (with count of additional changes)
#' 3. Prompts for approval (y/n)
#' 4. Applies changes only if approved
#'
#' This interactive approach allows taxonomic experts to review each
#' transformation and ensure no valid taxonomic names are corrupted.
#'
#' @return
#' If `return_log = FALSE` (default): A character vector of cleaned taxonomic names,
#' with `NA` for entries that were completely removed.
#'
#' If `return_log = TRUE`: A list with two elements:
#' \describe{
#'   \item{cleaned}{Character vector of cleaned taxonomic names}
#'   \item{log}{Data frame with columns `step`, `original`, `cleaned`, and `rule`
#'     documenting all changes made}
#' }
#'
#' @examples
#' # Basic usage with auto-approve
#' taxa <- c(
#'   "ACROPORA SP.",
#'   "Porites cf. lobata",
#'   "Montipora aff. capitata",
#'   "Pocillopora (damicornis)",
#'   "Unknown coral",
#'   "Millepora-like",
#'   "Stylophora  pistillata"
#' )
#'
#' cleaned <- clean_field_names(taxa, auto_approve = TRUE)
#'
#' # With logging for reproducibility
#' result <- clean_field_names(taxa, return_log = TRUE, auto_approve = TRUE)
#' cleaned_names <- result$cleaned
#' change_log <- result$log
#'
#' \dontrun{
#' # Interactive mode (prompts for approval at each step)
#' cleaned_interactive <- clean_field_names(taxa)
#'
#' # Export log for methods section
#' write.csv(change_log, "taxonomy_cleaning_log.csv", row.names = FALSE)
#'
#' # Clean a data frame column
#' library(dplyr)
#' df <- data.frame(
#'   site = c("A", "B", "C"),
#'   taxon = c("Acropora sp.", "Porites cf. lutea", "Unknown")
#' )
#'
#' df_clean <- df %>%
#'   mutate(taxon_clean = clean_field_names(taxon, auto_approve = TRUE))
#' }
#'
#' @references
#' Sigovini, M., Keppel, E., & Tagliapietra, D. (2016). Open Nomenclature in
#' the biodiversity era. \emph{Methods in Ecology and Evolution}, 7(10), 1217-1225.
#'
#' Bengtson, P. (1988). Open nomenclature. \emph{Palaeontology}, 31, 223-227.
#'
#' @author Juan Mayorga
#'
#' @importFrom utils head
#' @export
clean_field_names <- function(x, return_log = FALSE, auto_approve = FALSE) {

  # Input validation
  if (!is.character(x) && !is.factor(x)) {
    stop("Input must be a character vector or factor. Got: ", class(x)[1])
  }

  x <- as.character(x)
  x_original <- x  # Store original for comparison
  log_entries <- list()

  # Check for stringr (soft dependency)
  has_stringr <- requireNamespace("stringr", quietly = TRUE)

  # Helper: interactive step wrapper
  step <- function(label, transform_fun, rule_description = "") {
    if (!auto_approve) {
      cat("\n----------------------------------------\n")
      cat("STEP:", label, "\n")
      if (rule_description != "") {
        cat("RULE:", rule_description, "\n")
      }
      cat("----------------------------------------\n")
    }

    x_new <- transform_fun(x)

    # Identify changes
    idx <- which(x != x_new & !(is.na(x) & is.na(x_new)))

    if (length(idx) == 0) {
      if (!auto_approve) cat("\u2713 No changes needed.\n")
      return(x)
    }

    if (!auto_approve) {
      cat(sprintf("Found %d names to modify:\n", length(idx)))
      # Show up to 20 examples
      show_idx <- head(idx, 20)
      for (i in show_idx) {
        old_val <- if(is.na(x[i])) "NA" else paste0("'", x[i], "'")
        new_val <- if(is.na(x_new[i])) "NA" else paste0("'", x_new[i], "'")
        cat(sprintf("  %s \u2192 %s\n", old_val, new_val))
      }
      if (length(idx) > 20) {
        cat(sprintf("  ... and %d more\n", length(idx) - 20))
      }

      ans <- readline(prompt = "Apply this step? (y/n): ")
      apply_changes <- tolower(trimws(ans)) %in% c("y", "yes")
    } else {
      apply_changes <- TRUE
    }

    if (apply_changes) {
      if (return_log) {
        log_entries[[label]] <<- data.frame(
          step = label,
          original = x[idx],
          cleaned = x_new[idx],
          rule = rule_description,
          stringsAsFactors = FALSE
        )
      }
      x <- x_new
      if (!auto_approve) cat("\u2713 Changes applied\n")
    } else {
      if (!auto_approve) cat("\u2717 Changes skipped\n")
    }

    return(x)
  }

  # ============================================================
  # 1. Remove ALL parentheses and quotes (including nested)
  # ============================================================
  x <- step(
    "Remove parentheses and quotes",
    function(v) {
      # Remove nested parentheses iteratively
      while(any(grepl("\\([^()]*\\)", v, perl = TRUE))) {
        v <- gsub("\\([^()]*\\)", "", v, perl = TRUE)
      }
      # Remove quotes
      v <- gsub("\"[^\"]*\"", "", v)
      # Remove any empty parentheses left behind
      v <- gsub("\\(\\s*\\)", "", v)
      # Clean up stray parentheses
      v <- gsub("[()]", "", v)
      trimws(gsub("\\s+", " ", v))
    },
    "Remove (parentheses) and \"quotes\""
  )

  # ============================================================
  # 2. TRUNCATE AT sp. / spp. (keep ONLY genus)
  # ============================================================
  x <- step(
    "Truncate at 'sp.' or 'spp.'",
    function(v) {
      # Match "sp." or "spp." as whole word with word boundaries
      has_sp <- grepl("\\bspp?\\.?(\\s|$)", v, ignore.case = TRUE)
      v[has_sp] <- sub("\\s+spp?\\.?.*$", "", v[has_sp], ignore.case = TRUE)
      trimws(v)
    },
    "Genus sp./spp. \u2192 Genus only"
  )

  # ============================================================
  # 3. Handle 'aff.' uncertainty (ALL CASES)
  # ============================================================
  x <- step(
    "Handle 'aff.' uncertainty",
    function(v) {
      out <- v
      # Match aff/aff. in ANY case, extract only genus (first capitalized word)
      # Pattern: optional start, genus, whitespace, aff (any case), optional period, rest
      aff_pattern <- "^([A-Z][a-z]+)\\s+[Aa][Ff][Ff]\\.?\\s+.*$"
      has_aff <- grepl(aff_pattern, out)

      if (any(has_aff)) {
        out[has_aff] <- sub(aff_pattern, "\\1", out[has_aff])
      }
      trimws(out)
    },
    "aff. = strong uncertainty (genus only, any case)"
  )

  # ============================================================
  # 4. Handle 'cf.' uncertainty (remove token, keep epithet)
  # ============================================================
  x <- step(
    "Handle 'cf.' uncertainty",
    function(v) {
      # Remove cf/cf. in any case
      v <- gsub("\\s+[Cc][Ff]\\.?\\s+", " ", v)
      trimws(v)
    },
    "cf. = mild uncertainty (keep epithet, remove token)"
  )

  # ============================================================
  # 5. Handle unknown markers with taxonomic intelligence
  # ============================================================
  x <- step(
    "Handle unknown markers and map to higher taxonomy",
    function(v) {
      # Taxonomy mapping for common groups
      taxonomy_map <- c(
        "coral"       = "Scleractinia",
        "corals"      = "Scleractinia",
        "sponge"      = "Porifera",
        "sponges"     = "Porifera",
        "algae"       = "Algae",
        "alga"        = "Algae",
        "macroalgae"  = "Algae",
        "seaweed"     = "Algae",
        "fish"        = "Pisces",
        "crab"        = "Crustacea",
        "shrimp"      = "Crustacea",
        "lobster"     = "Crustacea",
        "urchin"      = "Echinoidea",
        "starfish"    = "Asteroidea",
        "seastar"     = "Asteroidea",
        "anemone"     = "Actiniaria",
        "jellyfish"   = "Cnidaria",
        "octopus"     = "Octopoda",
        "squid"       = "Teuthida",
        "mollusc"     = "Mollusca",
        "mollusk"     = "Mollusca",
        "snail"       = "Gastropoda",
        "clam"        = "Bivalvia",
        "worm"        = "Annelida",
        "tunicate"    = "Ascidiacea",
        "bryozoan"    = "Bryozoa"
      )

      out <- v

      # First, handle "unknown/unidentified X" pattern
      for (group in names(taxonomy_map)) {
        pattern <- paste0("\\b(unknown|unidentified|unk)\\s+", group, "\\b")
        has_group <- grepl(pattern, out, ignore.case = TRUE)
        if (any(has_group)) {
          out[has_group] <- taxonomy_map[group]
        }
      }

      # Then remove remaining unknown markers
      out <- gsub("\\b(unidentified|unknown|unk)\\b", "", out, ignore.case = TRUE)
      out <- gsub("\\?", "", out)
      out <- trimws(out)

      # Convert empty strings to NA
      out <- ifelse(out == "", NA_character_, out)

      out
    },
    "Unknown + group \u2192 higher taxonomy (e.g., 'Unknown coral' \u2192 'Scleractinia')"
  )

  # ============================================================
  # 6. Remove trailing 'like' qualifiers and descriptors
  # ============================================================
  x <- step(
    "Remove '-like' qualifiers and non-taxonomic descriptors",
    function(v) {
      # Remove -like and everything after it
      v <- gsub("[-\u2013\u2014]?\\s*like\\b.*$", "", v, ignore.case = TRUE)

      # Remove common non-taxonomic trailing words
      v <- gsub("\\s+(organism|species)\\b.*$", "", v, ignore.case = TRUE)

      trimws(v)
    },
    "Remove '-like', 'organism', 'species' suffixes"
  )

  # ============================================================
  # 7. Standardize capitalization (genus capitalized, epithet lowercase)
  # ============================================================
  x <- step(
    "Standardize capitalization (genus capitalized, epithet lowercase)",
    function(v) {
      if (has_stringr) {
        # Use stringr with custom logic
        v[!is.na(v)] <- vapply(v[!is.na(v)], function(name) {
          words <- stringr::str_split(name, "\\s+")[[1]]
          if (length(words) == 0) return(name)

          # First word (genus): Title case
          words[1] <- stringr::str_to_title(words[1])

          # Subsequent words (epithet, etc.): lowercase
          if (length(words) > 1) {
            words[2:length(words)] <- stringr::str_to_lower(words[2:length(words)])
          }

          paste(words, collapse = " ")
        }, character(1), USE.NAMES = FALSE)
      } else {
        # Base R alternative
        v[!is.na(v)] <- vapply(v[!is.na(v)], function(name) {
          words <- strsplit(name, "\\s+")[[1]]
          if (length(words) == 0) return(name)

          # First word (genus): capitalize first letter, rest lowercase
          words[1] <- paste0(
            toupper(substring(words[1], 1, 1)),
            tolower(substring(words[1], 2))
          )

          # Subsequent words (epithet, etc.): all lowercase
          if (length(words) > 1) {
            words[2:length(words)] <- tolower(words[2:length(words)])
          }

          paste(words, collapse = " ")
        }, character(1), USE.NAMES = FALSE)
      }
      v
    },
    "Genus capitalized, species epithet lowercase (Genus species)"
  )

  # ============================================================
  # 8. Final whitespace cleanup
  # ============================================================
  x <- step(
    "Final whitespace cleanup",
    function(v) {
      v <- gsub("\\s{2,}", " ", v)
      trimws(v)
    },
    "Remove extra spaces"
  )

  # ============================================================
  # SUMMARY
  # ============================================================
  if (!auto_approve) {
    cat("\n========================================\n")
    cat("CLEANING COMPLETE\n")
    cat("========================================\n")
    cat(sprintf("Total names:     %d\n", length(x)))
    cat(sprintf("Modified:        %d\n", sum(x_original != x, na.rm = TRUE)))
    cat(sprintf("Removed (\u2192 NA):  %d\n", sum(is.na(x) & !is.na(x_original))))
    cat(sprintf("Unchanged:       %d\n", sum(x_original == x, na.rm = TRUE)))
    cat("\n")
  }

  # Return results
  if (return_log) {
    if (length(log_entries) > 0) {
      log_df <- do.call(rbind, log_entries)
      rownames(log_df) <- NULL
    } else {
      log_df <- data.frame(
        step = character(0),
        original = character(0),
        cleaned = character(0),
        rule = character(0),
        stringsAsFactors = FALSE
      )
    }
    return(list(cleaned = x, log = log_df))
  } else {
    return(x)
  }
}
