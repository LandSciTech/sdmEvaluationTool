#fmt: skip
utils::globalVariables(c(
  # Passed to modules as ...
  # Inputs
  "model_id", "species_id", "deployment_id",
  # Tables
  "tbl_models", "tbl_species", "tbl_deployments",
  # Other
  "opts",
  "completed", "id", "id_spatial", "label", 
  "layers", "part", "show_clicked",
  "show_spatial_ids", "status", "type", "values"
))


.onLoad <- function(libname, pkgname) {
    # TODO: Change this, just for development right now
    sdmevaltool_options(base = "../misc/base")
}
