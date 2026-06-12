#fmt: skip
utils::globalVariables(c(
  # To avoid CRAN NOTES
  # Generally, use .data$VAR or "VAR" in NSE tidyverse functions to avoid notes
  # Only define things here if they cannot be defined otherwise, including:
  # 
  # - variables passed to modules as `...` 
  # - lists which are expanded into variables cannot be otherwise defined

  # Inputs
  "model_id", "species_id", "deployment_id",
  
  # Other
  "opts", "abandoned", "overview_update", "overview_inputs", "unsaved",
  "completed", "id", "id_spatial", "label", "input_id_ns",
  "layers", "part", "show_clicked", "response", "width", 
  "show_spatial_ids", "map_views",
  
  "values" # Spatial inputs
))

.onAttach <- function(libname, pkgname) {
  ver <- read.dcf(
    file = system.file("DESCRIPTION", package = pkgname),
    fields = c("Version")
  )
  packageStartupMessage(paste(pkgname, ver[1]))
  invisible(NULL)
}
