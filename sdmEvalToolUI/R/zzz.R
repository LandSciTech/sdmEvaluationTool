#fmt: skip
utils::globalVariables(c(
  # Passed to modules as ...
  # Inputs
  "model_id", "species_id", "deployment_id",
  # Tables
  "tbl_models", "tbl_species", "tbl_materials"
))


.onLoad <- function(libname, pkgname) {
  # TODO: Change this, just for development right now
  sdmEvalToolCore::sdmevaltool_options(base = "../misc/base")
}
