#fmt: skip
utils::globalVariables(c(
  # Passed to modules as ...
  # Inputs
  "model_id", "species_id", "deployment_id",
  # Tables
  "tbl_models", "tbl_species", "tbl_deployments",
  # Other
  "opts", "abandoned", "overview_update", "overview_inputs", "unsaved",
  "completed", "id", "id_spatial", "label", "input_id_ns",
  "layers", "part", "show_clicked", "response", "width", 
  "show_spatial_ids", "status", "type", "values", "hssr"
))

.onAttach <- function(libname, pkgname) {
  ver <- read.dcf(
    file = system.file("DESCRIPTION", package = pkgname),
    fields = c("Version")
  )
  packageStartupMessage(paste(pkgname, ver[1]))
  invisible(NULL)
}
