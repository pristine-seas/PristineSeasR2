# Connect to Google Earth Engine

Opens the `rgee` connection that
[`explore_s2_detections()`](https://pristine-seas.github.io/PristineSeasR2/reference/explore_s2_detections.md)
renders its crops through, working around two things that otherwise make
`rgee` unusable from a knitr chunk:

- `rgee` asks Earth Engine for the account's legacy asset root, but the
  `earthengine-api` no longer answers that call — it returns nothing
  whether or not a home exists. `rgee` then prompts for a folder name,
  and [`readline()`](https://rdrr.io/r/base/readline.html) returns `""`
  instantly in a non-interactive chunk, so the prompt loops on an answer
  it will never get. Supplying `asset_home` skips the lookup entirely.

- `reticulate` does not read `EARTHENGINE_PYTHON` — that variable is
  `rgee`'s — and defaults to its own managed environment, which has no
  `earthengine-api`. `rgee` then reports the interpreter it *wanted*
  rather than the one in use, so the error names a Python that does have
  the package. Binding the interpreter before `rgee` touches Python at
  all avoids it.

Calling this more than once in a session is free: the connection is
opened on the first call and remembered.

## Usage

``` r
ee_connect(
  project,
  python = Sys.getenv("EARTHENGINE_PYTHON"),
  asset_home = NULL,
  force = FALSE
)
```

## Arguments

- project:

  Earth Engine cloud project to bill and authenticate against, e.g.
  `"pristine-seas"`.

- python:

  Path to a Python interpreter that has `earthengine-api` installed.
  Defaults to the `EARTHENGINE_PYTHON` environment variable; pass `""`
  to leave `reticulate`'s own choice alone.

- asset_home:

  The account's Earth Engine asset root, e.g. `"users/jsmith"`.
  Optional, and only needed if `rgee` stalls on the asset root prompt
  described above.

- force:

  Re-open the connection even if one was already made this session.
  Default `FALSE`.

## Value

`TRUE`, invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
ee_connect(project = "pristine-seas", asset_home = "users/jsmith")
} # }
```
