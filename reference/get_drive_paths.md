# Get Standardized Paths for the Science Team in Google Drive

This function returns the correct file path to the `"SCIENCE"` folder
within `"Pristine Seas"` in Google Drive Desktop, ensuring compatibility
across Mac and Windows. It automatically searches for an `ngs.org`
Google Drive account first, but will default to another account if
needed.

## Usage

``` r
get_drive_paths()
```

## Value

A named list with full paths to `"SCIENCE"`, `"datasets"`,
`"expeditions"`, and `"projects"`.

## Examples

``` r
if (FALSE) { # \dontrun{
# Get paths for the SCIENCE folder and subfolders
paths <- get_drive_paths()
print(paths$science)      # Path to SCIENCE folder
print(paths$datasets)     # Path to datasets folder
print(paths$expeditions)  # Path to expeditions folder
print(paths$projects)     # Path to projects folder
} # }
```
