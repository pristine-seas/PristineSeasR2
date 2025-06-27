#' Get Standardized Paths for the Science Team in Google Drive
#'
#' This function returns the correct file path to the `"SCIENCE"` folder within `"Pristine Seas"`
#' in Google Drive Desktop, ensuring compatibility across Mac and Windows.
#' It automatically searches for an `ngs.org` Google Drive account first, but will
#' default to another account if needed.
#'
#' @return A named list with full paths to `"SCIENCE"`, `"datasets"`, `"expeditions"`, and `"projects"`.
#' @examples
#' \dontrun{
#' # Get paths for the SCIENCE folder and subfolders
#' paths <- get_drive_paths()
#' print(paths$science)      # Path to SCIENCE folder
#' print(paths$datasets)     # Path to datasets folder
#' print(paths$expeditions)  # Path to expeditions folder
#' print(paths$projects)     # Path to projects folder
#' }
#'
#' @export
get_drive_paths <- function() {

  # Detect OS
  os_type <- Sys.info()["sysname"]

  if (os_type == "Darwin") {  # Mac
    # List all Google Drive accounts
    drive_base <- list.dirs("~/Library/CloudStorage/", recursive = FALSE, full.names = TRUE)
    drive_paths <- drive_base[grep("GoogleDrive-", drive_base)]

    if (length(drive_paths) == 0) {
      stop("Google Drive not found on Mac. Is Google Drive Desktop installed?")
    }

    # Try to find an "ngs.org" account first
    ngs_drive <- grep("ngs.org", drive_paths, value = TRUE)

    # Select ngs.org account if found, otherwise use the first available account
    selected_drive <- ifelse(length(ngs_drive) > 0, ngs_drive[1], drive_paths[1])
    base_path <- file.path(selected_drive, "My Drive", "Pristine Seas", "SCIENCE")

  } else if (os_type == "Windows") {  # Windows
    # Detect user home directory
    user_home <- Sys.getenv("USERPROFILE")

    # Possible Google Drive locations
    possible_paths <- list.dirs(user_home, recursive = FALSE, full.names = TRUE)
    drive_paths <- possible_paths[grep("Google Drive", possible_paths)]

    if (length(drive_paths) == 0) {
      stop("Google Drive not found on Windows. Is Google Drive Desktop installed?")
    }

    # Try to find an "ngs.org" account first
    ngs_drive <- grep("ngs.org", drive_paths, value = TRUE)

    # Select ngs.org account if found, otherwise use the first available account
    selected_drive <- ifelse(length(ngs_drive) > 0, ngs_drive[1], drive_paths[1])
    base_path <- file.path(selected_drive, "My Drive", "Pristine Seas", "SCIENCE")

  } else {
    stop("Unsupported OS. This function works only on Mac and Windows.")
  }

  # Check if SCIENCE folder exists
  if (!dir.exists(base_path)) {
    warning("SCIENCE folder not found at: ", base_path,
            "\nPlease ensure Google Drive is synced and the folder structure exists.")
  }

  # Define subfolder paths
  paths <- list(
    science = normalizePath(base_path, winslash = "/", mustWork = FALSE),
    datasets = normalizePath(file.path(base_path, "datasets"), winslash = "/", mustWork = FALSE),
    expeditions = normalizePath(file.path(base_path, "expeditions"), winslash = "/", mustWork = FALSE),
    projects = normalizePath(file.path(base_path, "projects"), winslash = "/", mustWork = FALSE)
  )

  return(paths)
}
