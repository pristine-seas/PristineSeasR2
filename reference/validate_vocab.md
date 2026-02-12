# Validate Values Against Allowed Vocabularies

Checks whether all values conform to Pristine Seas standardized
vocabularies. Use early in data processing pipelines to catch
non-standard entries before analysis. Stops with an informative error if
invalid values are found.

## Usage

``` r
validate_vocab(x, vocab)
```

## Arguments

- x:

  Character vector of values to validate.

- vocab:

  Character string naming the vocabulary to validate against. One of:
  `"trophic_group"`, `"depth_strata"`, `"exposure"`, `"uvs_habitats"`,
  `"functional_groups"`.

## Value

Returns `TRUE` invisibly if all values are valid. Stops with an error if
any invalid values are found.

## Details

This function is designed as a gatekeeper for data quality. Place it
early in your pipeline to ensure data conforms to standards before
analysis.

**On success:** Prints a confirmation message and returns `TRUE`
invisibly.

**On failure:** Stops with an error listing:

- Number and identity of invalid values

- All allowed values for reference

For filtering data (rather than validating), use `%in%` directly:

    df |> filter(trophic %in% allowed_vocab$trophic_group)

## See also

[allowed_vocab](https://pristine-seas.github.io/PristineSeasR2/reference/allowed_vocab.md)
for the vocabularies and their definitions

## Examples

``` r
# Successful validation (prints message, returns TRUE invisibly)
validate_vocab(c("shark", "planktivore"), "trophic_group")
#> ✓ 2 valid value(s) for 'trophic_group'

# NAs trigger a warning
validate_vocab(c("shallow", NA, "deep"), "depth_strata")
#> Warning: Found 1 NA value(s) in 'depth_strata'
#> ✓ 2 valid value(s) for 'depth_strata'
#> Warning: Found 1 NA value(s) in 'depth_strata'
#> ✓ All 3 values valid for 'depth_strata'

# Use in a processing pipeline
if (FALSE) { # \dontrun{
raw_data <- read.csv("fish_surveys.csv")

# Validate before proceeding
validate_vocab(raw_data$trophic_group, "trophic_group")
validate_vocab(raw_data$depth_strata, "depth_strata")

# Continue with clean data...
} # }

# Invalid values trigger an error
if (FALSE) { # \dontrun{
validate_vocab(c("shark", "apex_predator"), "trophic_group")
#> Error: Invalid values found in 'trophic_group'
#> Found 1 invalid value: apex_predator
#> Allowed values: shark, top_predator, lower_carnivore, ...
} # }

# Filtering (don't use validate_vocab, use %in% directly)
if (FALSE) { # \dontrun{
df |> filter(habitat %in% allowed_vocab$uvs_habitats)
} # }
```
