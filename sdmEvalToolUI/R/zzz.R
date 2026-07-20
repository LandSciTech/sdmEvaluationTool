#fmt: skip
utils::globalVariables(c(
  # To avoid CRAN NOTES
  # Generally, use .data$VAR or "VAR" in NSE tidyverse functions to avoid notes
  # Only define things here if they cannot be defined otherwise, including:
  # 
  # - variables passed to modules as `...` 
  # - lists which are expanded into variables cannot be otherwise defined

  # Input args
  "model_id", "species_id", "deployment_id",
  "opts", "abandoned", "unsaved", "map_views",

  # spatial_selection list arg gives...
  "show_clicked", "show_spatial_ids",
 
  # inputs.R
  "label", "input_id_ns", "metadata_popover", "response", "width",  "values",

  # mod_page_overview_server.R
  "overview_update", "overview_inputs"
 
))

.onAttach <- function(libname, pkgname) {
  ver <- read.dcf(
    file = system.file("DESCRIPTION", package = pkgname),
    fields = c("Version")
  )
  packageStartupMessage(paste(pkgname, ver[1]))
  invisible(NULL)
}
