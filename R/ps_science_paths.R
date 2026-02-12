#' Get standardized Pristine Seas Google Drive paths
#'
#' Returns normalized local paths to the Pristine Seas Science Google Drive
#' folder structure:
#'
#' \preformatted{
#' My Drive/
#' └── Pristine Seas/
#'     └── SCIENCE/
#'         ├── datasets/
#'         ├── expeditions/
#'         └── projects/
#' }
#'
#' The function works on Mac and Windows and avoids hard-coded user paths.
#'
#' Path resolution order:
#' \enumerate{
#'   \item If the environment variable \code{PS_SCIENCE_PATH} is set, it is used
#'   as the SCIENCE folder.
#'   \item Otherwise, the function detects the local Google Drive "My Drive"
#'   directory and searches for \code{"Pristine Seas/SCIENCE"}.
#'   \item If multiple matches exist, an \code{ngs.org} account is preferred.
#' }
#'
#' @param mustWork Logical. If \code{TRUE}, the function errors when the SCIENCE
#'   folder is not found. If \code{FALSE} (default), a warning is issued and a
#'   best-guess path is returned.
#'
#' @return A named list with normalized paths:
#' \describe{
#'   \item{science}{Path to \code{Pristine Seas/SCIENCE}}
#'   \item{datasets}{Path to \code{SCIENCE/datasets}}
#'   \item{expeditions}{Path to \code{SCIENCE/expeditions}}
#'   \item{projects}{Path to \code{SCIENCE/projects}}
#' }
#'
#' @details
#' This function requires Google Drive for Desktop with the
#' \code{Pristine Seas/SCIENCE} folder synced locally.
#'
#' For non-standard setups (e.g., custom drive letters, CI, or shared machines),
#' set an environment variable in \code{.Renviron}:
#'
#' \preformatted{
#' PS_SCIENCE_PATH=G:/My Drive/Pristine Seas/SCIENCE
#' }
#'
#' All returned paths use forward slashes for cross-platform compatibility.
#'
#' @examples
#' \dontrun{
#' paths <- get_drive_paths()
#'
#' paths$science
#' paths$datasets
#'
#' readr::read_csv(file.path(paths$datasets, "fish", "blt_data.csv"))
#' }
#'
#' @export
ps_science_paths <- function(mustWork = FALSE) {

  norm <- function(p) normalizePath(p, winslash = "/", mustWork = FALSE)

  os <- Sys.info()[["sysname"]]
  is_mac <- identical(os, "Darwin")
  is_win <- identical(os, "Windows")

  # ---- 0) Optional override ----
  override <- Sys.getenv("PS_SCIENCE_PATH", unset = "")
  if (nzchar(override)) {
    base_path <- override

  } else {

    # ---- 1) Find candidate "My Drive" roots ----
    my_drive_roots <- character(0)

    if (is_mac) {

      cloud <- path.expand("~/Library/CloudStorage")
      if (dir.exists(cloud)) {
        accts <- list.dirs(cloud, recursive = FALSE, full.names = TRUE)
        gdrive <- accts[grepl("^GoogleDrive-", basename(accts))]
        my_drive_roots <- file.path(gdrive, "My Drive")
      }

    } else if (is_win) {

      # Common: Google Drive mounted as a drive letter containing "My Drive"
      drive_letters <- paste0(LETTERS, ":/")
      my_drive_roots <- file.path(drive_letters, "My Drive")
      my_drive_roots <- my_drive_roots[dir.exists(my_drive_roots)]

      # Fallbacks if not mounted as a drive letter
      if (length(my_drive_roots) == 0) {
        home <- Sys.getenv("USERPROFILE", unset = "")
        fallbacks <- c(
          file.path(home, "Google Drive", "My Drive"),
          file.path(home, "GoogleDrive", "My Drive")
        )
        my_drive_roots <- fallbacks[dir.exists(fallbacks)]
      }

    } else {
      stop("Unsupported OS. Mac and Windows only.", call. = FALSE)
    }

    if (length(my_drive_roots) == 0) {
      stop("Google Drive 'My Drive' folder not found. Is Google Drive Desktop installed and signed in?",
           call. = FALSE)
    }

    # ---- 2) Look for actual SCIENCE folder inside each root ----
    science_candidates <- file.path(my_drive_roots, "Pristine Seas", "SCIENCE")
    exists <- dir.exists(science_candidates)

    if (!any(exists)) {

      msg <- paste0(
        "Could not find 'Pristine Seas/SCIENCE' inside any detected Google Drive.\n",
        "Searched:\n- ", paste(norm(my_drive_roots), collapse = "\n- "), "\n\n",
        "Fixes:\n",
        " - Ensure the folder is synced locally, or\n",
        " - åSet PS_SCIENCE_PATH to the SCIENCE folder location."
      )

      if (isTRUE(mustWork)) stop(msg, call. = FALSE) else warning(msg, call. = FALSE)

      # Best guess fallback
      base_path <- file.path(my_drive_roots[1], "Pristine Seas", "SCIENCE")

    } else {

      hits <- science_candidates[exists]

      # Prefer ngs.org if multiple matches (mainly relevant on Mac)
      ngs <- hits[grepl("ngs\\.org", hits, ignore.case = TRUE)]
      base_path <- if (length(ngs) > 0) ngs[1] else hits[1]
    }
  }

  # ---- 3) Final existence check ----
  if (!dir.exists(base_path)) {
    msg <- paste0("SCIENCE folder not found at:\n  ", norm(base_path))
    if (isTRUE(mustWork)) stop(msg, call. = FALSE) else warning(msg, call. = FALSE)
  }

  # ---- 4) Return standardized paths ----
  list(
    science     = norm(base_path),
    datasets    = norm(file.path(base_path, "datasets")),
    expeditions = norm(file.path(base_path, "expeditions")),
    projects    = norm(file.path(base_path, "projects"))
  )
}
