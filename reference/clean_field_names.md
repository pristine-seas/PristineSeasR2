# Clean Taxonomic Field Names from Benthic LPI Surveys

Interactively cleans and standardizes taxonomic names from benthic Line
Point Intercept (LPI) surveys. The function processes names through
multiple cleaning steps, asking for user approval at each stage to
prevent unintended data loss.

This function is specifically designed for marine benthic taxonomy and
implements field-tested rules for handling taxonomic uncertainty
markers, species-level designations, and common field survey artifacts.

## Usage

``` r
clean_field_names(x, return_log = FALSE, auto_approve = FALSE)
```

## Arguments

- x:

  Character vector of taxonomic names to clean

- return_log:

  Logical. If `TRUE`, returns a list with both cleaned names and a data
  frame logging all changes. If `FALSE` (default), returns only the
  cleaned character vector. Default: `FALSE`

- auto_approve:

  Logical. If `TRUE`, applies all cleaning steps without interactive
  prompts. Use with caution - recommended only after reviewing changes
  with `auto_approve = FALSE` first. Default: `FALSE`

## Value

If `return_log = FALSE` (default): A character vector of cleaned
taxonomic names, with `NA` for entries that were completely removed.

If `return_log = TRUE`: A list with two elements:

- cleaned:

  Character vector of cleaned taxonomic names

- log:

  Data frame with columns `step`, `original`, `cleaned`, and `rule`
  documenting all changes made

## Details

### Cleaning Steps

The function applies the following transformations in sequence:

#### 1. Remove Parentheses and Quotes

Removes content in parentheses and quotation marks (including nested):

- `Pocillopora (damicornis)` → `Pocillopora`

- `Pocillopora ((nested))` → `Pocillopora`

- `Turbinaria "mesenterina"` → `Turbinaria`

#### 2. Truncate at sp./spp.

Removes species-level uncertainty markers and keeps only genus:

- `Acropora sp.` → `Acropora`

- `Porites spp` → `Porites`

Pattern matching uses word boundaries to avoid truncating valid names
(e.g., "Dispar" is preserved).

#### 3. Handle Uncertainty Markers

**aff. (affinis)** - Strong uncertainty, drops epithet:

- `Montipora aff. capitata` → `Montipora`

- `Montipora Aff. capitata` → `Montipora`

- Indicates the specimen is similar to but likely not the named species

**cf. (confer)** - Mild uncertainty, keeps epithet:

- `Porites cf. lobata` → `Porites lobata`

- Indicates comparison with named species, higher confidence

#### 4. Handle Unknown + Taxonomic Group

Converts "unknown" + group to proper higher taxonomy:

- `Unknown coral` → `Scleractinia`

- `Unknown sponge` → `Porifera`

- `Unidentified` alone → `NA`

#### 5. Remove '-like' Qualifiers

Removes qualifiers indicating morphological similarity:

- `Millepora-like` → `Millepora`

- `Millepora-like organism` → `Millepora`

- Handles various dash types: `-`, `–`, `—`

#### 6. Standardize Capitalization

Converts to proper taxonomic case (genus capitalized, epithet
lowercase):

- `ACROPORA PALMATA` → `Acropora palmata`

- `porites lobata` → `Porites lobata`

#### 7. Whitespace Cleanup

Removes extra spaces and trims leading/trailing whitespace

### Interactive Workflow

At each step, the function:

1.  Shows proposed changes with before/after comparison

2.  Displays up to 20 examples (with count of additional changes)

3.  Prompts for approval (y/n)

4.  Applies changes only if approved

This interactive approach allows taxonomic experts to review each
transformation and ensure no valid taxonomic names are corrupted.

## References

Sigovini, M., Keppel, E., & Tagliapietra, D. (2016). Open Nomenclature
in the biodiversity era. *Methods in Ecology and Evolution*, 7(10),
1217-1225.

Bengtson, P. (1988). Open nomenclature. *Palaeontology*, 31, 223-227.

## Author

Juan Mayorga

## Examples

``` r
# Basic usage with auto-approve
taxa <- c(
  "ACROPORA SP.",
  "Porites cf. lobata",
  "Montipora aff. capitata",
  "Pocillopora (damicornis)",
  "Unknown coral",
  "Millepora-like",
  "Stylophora  pistillata"
)

cleaned <- clean_field_names(taxa, auto_approve = TRUE)

# With logging for reproducibility
result <- clean_field_names(taxa, return_log = TRUE, auto_approve = TRUE)
cleaned_names <- result$cleaned
change_log <- result$log

if (FALSE) { # \dontrun{
# Interactive mode (prompts for approval at each step)
cleaned_interactive <- clean_field_names(taxa)

# Export log for methods section
write.csv(change_log, "taxonomy_cleaning_log.csv", row.names = FALSE)

# Clean a data frame column
library(dplyr)
df <- data.frame(
  site = c("A", "B", "C"),
  taxon = c("Acropora sp.", "Porites cf. lutea", "Unknown")
)

df_clean <- df %>%
  mutate(taxon_clean = clean_field_names(taxon, auto_approve = TRUE))
} # }
```
