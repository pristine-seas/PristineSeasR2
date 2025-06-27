#' Create New Pristine Seas Expedition Structure
#'
#' Creates a comprehensive standardized folder structure for Pristine Seas expeditions
#' in the expeditions folder of the science drive. Expedition names follow the convention
#' ISO3-YEAR (e.g., CHL-2024).
#'
#' @param expedition_name Character string. Name of the expedition following ISO3-YEAR format
#' @param create_readme Logical. Whether to create a README.md file with expedition template (default: TRUE)
#' @return Character string. Path to the created expedition folder
#' @examples
#' \dontrun{
#' # Create an expedition (standard naming: ISO3-YEAR)
#' create_expedition("CHL-2024")
#'
#' # Create expedition without README
#' create_expedition("MEX-2024", create_readme = FALSE)
#' }
#' @export
create_expedition <- function(expedition_name, create_readme = TRUE) {

  # Input validation
  if (missing(expedition_name) || is.null(expedition_name) || expedition_name == "") {
    stop("expedition_name is required and cannot be empty")
  }

  if (!is.character(expedition_name) || length(expedition_name) != 1) {
    stop("expedition_name must be a single character string")
  }

  # Clean expedition name (convert spaces/underscores to dashes)
  clean_name <- gsub("[^a-zA-Z0-9_-]", "-", expedition_name)  # Convert invalid chars to dashes
  clean_name <- gsub("[_]", "-", clean_name)  # Convert underscores to dashes
  clean_name <- gsub("-+", "-", clean_name)  # Remove multiple dashes
  clean_name <- gsub("^-|-$", "", clean_name)  # Remove leading/trailing dashes

  if (clean_name != expedition_name) {
    message("Expedition name cleaned from '", expedition_name, "' to '", clean_name, "'")
  }

  # Get drive paths
  drive_paths <- get_drive_paths()

  # Create full expedition path
  expedition_folder <- file.path(drive_paths$expeditions, clean_name)

  # Check if expedition already exists
  if (dir.exists(expedition_folder)) {
    stop("Expedition folder already exists: ", expedition_folder)
  }

  # Create main expedition folder
  dir.create(expedition_folder, recursive = TRUE)
  message("Created expedition folder: ", expedition_folder)

  # Define comprehensive folder structure
  folders <- c(
    "data/primary/raw",           # Unmodified field data
    "data/primary/processed",     # QA/QC applied data
    "data/primary/output",        # Analysis-ready data
    "data/secondary",             # Data from external sources
    "documents",                  # Scouting and planning documents
    "figures",                    # Maps and visualizations
    "gis",                        # Spatial project
    "media",                      # Photos, videos
    "presentations",              # Slide decks
    "reports",                    # Expedition outputs
    "references"                  # Literature and resources
  )

  # Create all folders
  for (folder in folders) {
    folder_path <- file.path(expedition_folder, folder)
    dir.create(folder_path, recursive = TRUE)
  }

  message("Created ", length(folders), " expedition folders")

  # Create README.md if requested
  if (create_readme) {
    readme_content <- create_expedition_readme(clean_name)
    readme_path <- file.path(expedition_folder, "README.md")
    writeLines(readme_content, readme_path)
    message("Created README.md with expedition template")
  }

  message("\n** Expedition '", clean_name, "' created successfully!")
  message("Location: ", expedition_folder)
  message("Ready to plan your Pristine Seas expedition!")

  return(invisible(expedition_folder))
}

#' Create Expedition README Template
#' @keywords internal
create_expedition_readme <- function(expedition_name) {
  c(
    paste("#", expedition_name),
    "",
    "## Expedition Overview",
    "",
    "[Brief description of expedition objectives and scope]",
    "",
    "## Expedition Details",
    "",
    "**Expedition Leader:** [Name]  ",
    "**Science Leader:** [Name]  ",
    "**Partner Organization:** [Organization Name]  ",
    "**Start Date:** [YYYY-MM-DD]  ",
    "**End Date:** [YYYY-MM-DD]  ",
    "**Ship:** [Vessel Name]  ",
    "**Ship MMSI:** [MMSI Number]  ",
    "",
    "## Geographic Coverage",
    "",
    "**Regions and Subregions Visited:**",
    "",
    "- **[Region - Official Name]**",
    "  - [Subregion - Official Name]",
    "  - [Subregion - Official Name]",
    "",
    "- **[Region - Official Name]**",
    "  - [Subregion - Official Name]",
    "  - [Subregion - Official Name]",
    "",
    "- **[Region - Official Name]**",
    "  - [Subregion - Official Name]",
    "",
    "## Methods Used",
    "",
    "- [ ] BLT Fish Surveys",
    "- [ ] LPI (Line Point Intercept)",
    "- [ ] Inverts",
    "- [ ] Recruits",
    "- [ ] Photoquads",
    "- [ ] YSI",
    "- [ ] eDNA",
    "- [ ] Pelagic BRUVs",
    "- [ ] Seabed BRUVs",
    "- [ ] ROV",
    "- [ ] Submersible",
    "- [ ] Deep Sea Cams",
    "- [ ] Seabird Surveys",
    "- [ ] [Add other methods as needed]",
    "",
    "---",
    "",
    paste("*Expedition folder created on", Sys.Date(), "using PristineSeasR2*")
  )
}
