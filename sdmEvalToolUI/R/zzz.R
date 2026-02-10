#fmt: skip
utils::globalVariables(c(
  # Passed to modules as ...
  # Inputs
  "model_id", "species_id", "deployment_id",
  # Tables
  "tbl_models", "tbl_species", "tbl_deployments",
  # Other
  "opts", "abandoned", "overview_update", "overview_inputs",
  "completed", "id", "id_spatial", "label", "input_id_ns",
  "layers", "part", "show_clicked", "response", "width", 
  "show_spatial_ids", "status", "type", "values"
))


.onLoad <- function(libname, pkgname) {
  # CLEANUP: Change this, just for development right now
  sdmevaltool_options(base = "../misc/base")
}
