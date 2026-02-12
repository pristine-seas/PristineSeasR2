# Get standardized Pristine Seas Google Drive paths

Returns normalized local paths to the Pristine Seas Science Google Drive
folder structure:

## Usage

``` r
ps_science_paths(mustWork = FALSE)
```

## Arguments

- mustWork:

  Logical. If `TRUE`, the function errors when the SCIENCE folder is not
  found. If `FALSE` (default), a warning is issued and a best-guess path
  is returned.

## Value

A named list with normalized paths:

- science:

  Path to `Pristine Seas/SCIENCE`

- datasets:

  Path to `SCIENCE/datasets`

- expeditions:

  Path to `SCIENCE/expeditions`

- projects:

  Path to `SCIENCE/projects`

## Details

    My Drive/
    └── Pristine Seas/
        └── SCIENCE/
            ├── datasets/
            ├── expeditions/
            └── projects/

The function works on Mac and Windows and avoids hard-coded user paths.

Path resolution order:

1.  If the environment variable `PS_SCIENCE_PATH` is set, it is used as
    the SCIENCE folder.

2.  Otherwise, the function detects the local Google Drive "My Drive"
    directory and searches for `"Pristine Seas/SCIENCE"`.

3.  If multiple matches exist, an `ngs.org` account is preferred.

This function requires Google Drive for Desktop with the
`Pristine Seas/SCIENCE` folder synced locally.

For non-standard setups (e.g., custom drive letters, CI, or shared
machines), set an environment variable in `.Renviron`:

    PS_SCIENCE_PATH=G:/My Drive/Pristine Seas/SCIENCE

All returned paths use forward slashes for cross-platform compatibility.

## Examples

``` r
if (FALSE) { # \dontrun{
paths <- get_drive_paths()

paths$science
paths$datasets

readr::read_csv(file.path(paths$datasets, "fish", "blt_data.csv"))
} # }
```
