# Find the Pristine Seas SCIENCE folder on this machine

Returns the local paths to the shared `Pristine Seas/SCIENCE` folder and
its `datasets`, `expeditions` and `projects` subfolders, wherever Google
Drive for Desktop has put them. Works on macOS and Windows, with ngs.org
or personal accounts, and whether the folder sits in *My Drive*, in a
*Shared drive*, or reaches you through a shortcut.

`get_drive_paths()` is the original name, kept as a plain alias so
existing scripts keep working.

## Usage

``` r
ps_science_paths(quiet = FALSE)

get_drive_paths()
```

## Arguments

- quiet:

  Logical. Suppress the message naming which folder was chosen when
  several qualify.

## Value

A named list of paths with forward slashes: `science`, `datasets`,
`expeditions`, `projects`.

## Details

If `PS_SCIENCE_PATH` (or the option `PristineSeasR2.science_path`) is
set, it is used as is; pointing it at a missing folder is an error.
Otherwise every Google Drive root on the machine is searched: *My
Drive*, each *Shared drive*, and the shortcut targets Drive keeps for
folders shared with you. A hit must contain at least one of the three
subfolders. When several qualify, an ngs.org account wins, then a live
account over a stale `(date)` copy left by a re-login. If nothing
qualifies, the error lists every location searched and how to fix it.

## Examples

``` r
if (FALSE) { # \dontrun{
paths <- ps_science_paths()
list.files(paths$expeditions)

# For an unusual setup, once, in .Renviron (usethis::edit_r_environ()):
# PS_SCIENCE_PATH="D:/Drive/Pristine Seas/SCIENCE"
} # }
```
