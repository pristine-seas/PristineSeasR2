#' Create New Pristine Seas Project Structure
#'
#' Creates a simple standardized folder structure for Pristine Seas projects in the
#' projects folder of the science drive.
#'
#' @param project_name Character string. Name of the new project (use "prj-" prefix by convention)
#' @return Character string. Path to the created project folder
#' @examples
#' \dontrun{
#' # Create a project
#' create_project("prj-coral-reef-assessment")
#'
#' # Create another project
#' create_project("prj-fish-surveys")
#' }
#' @export
create_project <- function(project_name) {

  # Input validation
  if (missing(project_name) || is.null(project_name) || project_name == "") {
    stop("project_name is required and cannot be empty")
  }

  if (!is.character(project_name) || length(project_name) != 1) {
    stop("project_name must be a single character string")
  }

  # Clean project name (remove invalid characters, convert spaces/underscores to dashes)
  clean_name <- gsub("[^a-zA-Z0-9_-]", "-", project_name)  # Convert invalid chars to dashes
  clean_name <- gsub("[_]", "-", clean_name)  # Convert underscores to dashes
  clean_name <- gsub("-+", "-", clean_name)  # Remove multiple dashes
  clean_name <- gsub("^-|-$", "", clean_name)  # Remove leading/trailing dashes

  if (clean_name != project_name) {
    message("Project name cleaned from '", project_name, "' to '", clean_name, "'")
  }

  # Get drive paths
  drive_paths <- get_drive_paths()

  # Create full project path
  project_folder <- file.path(drive_paths$projects, clean_name)

  # Check if project already exists
  if (dir.exists(project_folder)) {
    stop("Project folder already exists: ", project_folder)
  }

  # Create main project folder
  dir.create(project_folder, recursive = TRUE)
  message("Created project folder: ", project_folder)

  # Create simple folder structure
  folders <- c("data", "figures", "docs", "presentations")

  # Create folders
  for (folder in folders) {
    folder_path <- file.path(project_folder, folder)
    dir.create(folder_path, recursive = TRUE)
  }

  message("Created data/, figures/, docs/, and presentations/ folders")
  message("\n** Project '", clean_name, "' created successfully!")
  message("Location: ", project_folder)

  return(invisible(project_folder))
}
