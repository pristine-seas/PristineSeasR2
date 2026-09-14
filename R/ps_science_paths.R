# ps_science_paths.R -----------------------------------------------------------
# Find the shared Pristine Seas SCIENCE folder on any teammate's machine. Drive for Desktop has moved its mount point over the years, accounts differ (ngs.org, personal), shared folders arrive as shortcuts, and Windows and macOS lay it all out differently. So instead of assuming one layout we look everywhere the folder can be and take the best hit.

#' Find the Pristine Seas SCIENCE folder on this machine
#'
#' Returns the local paths to the shared `Pristine Seas/SCIENCE` folder and its `datasets`, `expeditions` and `projects` subfolders, wherever Google Drive for Desktop has put them. Works on macOS and Windows, with ngs.org or personal accounts, and whether the folder sits in *My Drive*, in a *Shared drive*, or reaches you through a shortcut.
#'
#' @details
#' If `PS_SCIENCE_PATH` (or the option `PristineSeasR2.science_path`) is set, it is used as is; pointing it at a missing folder is an error. Otherwise every Google Drive root on the machine is searched: *My Drive*, each *Shared drive*, and the shortcut targets Drive keeps for folders shared with you. A hit must contain at least one of the three subfolders. When several qualify, an ngs.org account wins, then a live account over a stale `(date)` copy left by a re-login. If nothing qualifies, the error lists every location searched and how to fix it.
#'
#' @param quiet Logical. Suppress the message naming which folder was chosen when several qualify.
#'
#' @return A named list of paths with forward slashes: `science`, `datasets`, `expeditions`, `projects`.
#'
#' @examples
#' \dontrun{
#' paths <- ps_science_paths()
#' list.files(paths$expeditions)
#'
#' # For an unusual setup, once, in .Renviron (usethis::edit_r_environ()):
#' # PS_SCIENCE_PATH="D:/Drive/Pristine Seas/SCIENCE"
#' }
#'
#' @export
ps_science_paths <- function(quiet = FALSE) {

  override <- getOption("PristineSeasR2.science_path", Sys.getenv("PS_SCIENCE_PATH"))
  if (nzchar(override)) {
    if (!dir.exists(override)) {
      stop("PS_SCIENCE_PATH points to a folder that does not exist:\n  ", override,
           "\nFix it in .Renviron (usethis::edit_r_environ()) or unset it to search Google Drive.", call. = FALSE)
    }
    return(.ps_science_list(override))
  }

  roots <- .ps_drive_roots()
  hits  <- .ps_science_candidates(roots)

  if (!length(hits)) {
    stop("Could not find 'Pristine Seas/SCIENCE' on this machine.\n",
         "Searched (My Drive, Shared drives and shortcuts under):\n",
         if (length(roots)) paste0("  - ", roots, collapse = "\n") else "  - no Google Drive folder found", "\n",
         "Fixes: make sure Google Drive for Desktop is signed in; add a shortcut to 'Pristine Seas' in My Drive; ",
         "or set PS_SCIENCE_PATH in .Renviron (usethis::edit_r_environ()).", call. = FALSE)
  }

  if (length(hits) > 1 && !quiet) {
    message("Several SCIENCE folders found; using\n  ", hits[1], "\nPassed over:\n",
            paste0("  ", hits[-1], collapse = "\n"), "\nSet PS_SCIENCE_PATH to choose explicitly.")
  }

  .ps_science_list(hits[1])
}

#' @rdname ps_science_paths
#' @description
#' `get_drive_paths()` is the original name, kept as a plain alias so existing scripts keep working.
#' @export
get_drive_paths <- function() {
  ps_science_paths()
}

# Internals --------------------------------------------------------------------

.ps_science_list <- function(base) {
  norm <- function(p) normalizePath(p, winslash = "/", mustWork = FALSE)
  list(science     = norm(base),
       datasets    = norm(file.path(base, "datasets")),
       expeditions = norm(file.path(base, "expeditions")),
       projects    = norm(file.path(base, "projects")))
}

# Every existing folder that can act as a Google Drive account root, i.e. may hold "My Drive", "Shared drives" or ".shortcut-targets-by-id".
.ps_drive_roots <- function(os = Sys.info()[["sysname"]], home = path.expand("~"),
                            userprofile = Sys.getenv("USERPROFILE")) {
  roots <- switch(os,
    Darwin = c(list.files(file.path(home, "Library", "CloudStorage"), "^GoogleDrive-", full.names = TRUE),
               "/Volumes/GoogleDrive", file.path(home, "Google Drive")),
    Windows = c(paste0(LETTERS, ":")[dir.exists(paste0(LETTERS, ":/My Drive"))],
                list.files(userprofile, "^(Google ?Drive|My Drive)", full.names = TRUE), userprofile),
    stop("Google Drive layouts are known for macOS and Windows only. Set PS_SCIENCE_PATH to the SCIENCE folder.", call. = FALSE))
  unique(roots[dir.exists(roots)])
}

# Qualifying SCIENCE folders under the given roots, best first, as normalized paths.
.ps_science_candidates <- function(roots) {
  if (!length(roots)) return(character(0))

  # Places a shared folder can sit: My Drive, the root itself (a mirrored folder), each Shared drive, and each shortcut target. The folder may be "Pristine Seas/SCIENCE" or a shortcut straight to SCIENCE.
  bases <- unlist(lapply(roots, function(r) c(
    file.path(r, "My Drive"), r,
    list.dirs(file.path(r, "Shared drives"), recursive = FALSE),
    list.dirs(file.path(r, ".shortcut-targets-by-id"), recursive = FALSE))))
  paths <- c(file.path(bases, "Pristine Seas", "SCIENCE"), file.path(bases, "SCIENCE"))
  paths <- paths[dir.exists(paths)]

  holds_content <- vapply(paths, function(p) any(dir.exists(file.path(p, c("datasets", "expeditions", "projects")))), logical(1))
  paths <- paths[holds_content]
  if (!length(paths)) return(character(0))

  # Rank: ngs.org account first, then a live account over a "(date)" re-login copy, then the newest. Shortcuts are symlinks, so the same folder can appear twice; keep one.
  root  <- vapply(paths, function(p) roots[startsWith(p, roots)][1], "")
  ngs   <- grepl("ngs\\.org", root, ignore.case = TRUE)
  stale <- grepl("\\(.*\\)$", basename(root))
  paths <- paths[order(!ngs, stale, -as.numeric(file.mtime(paths)))]
  unique(normalizePath(paths, winslash = "/", mustWork = FALSE))
}
