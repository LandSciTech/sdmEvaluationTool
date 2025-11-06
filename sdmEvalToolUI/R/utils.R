prep_data <- function() {
  # TODO: Assign this elsewhere?
  sdmevaltool_options(base = "../misc/base")

  db <- db_connect()
  tbl_models <- db_read_models(db)
  tbl_species <- db_read_species(db)
  tbl_deployments <- dplyr::tbl(db, "deployments") |> dplyr::collect()

  list(
    "tbl_deployments" = tbl_deployments,
    "tbl_models" = tbl_models,
    "tbl_species" = tbl_species
  )
}


expand_list <- function(l, env = rlang::caller_env()) {
  rlang::env_bind(env, !!!l)
}

expand_dots <- function(..., env = rlang::caller_env()) {
  rlang::env_bind(env, !!!list(...))
}

#' Load material files
#'
#' @param component Character. Type of material to load.
#' @param model_id Character.
#' @param species_id Character.
#'
#' @returns Loaded file as an R object
#'
#' @export
#' @examplesIf have_data()
#' prep_materials("observations", species_id = "BBWO", model_id = "bam_v5_can71")
#' #prep_materials("model_metadata", model_id = "bam_v5_can71")
#' prep_materials("predictor_metadata", model_id = "bam_v5_can71")
#' #prep_materials("predictor_raster", model_id = "bam_v5_can71")
#' prep_materials("spatial_prediction", species_id = "BBWO", model_id = "bam_v5_can71")
#' prep_materials("model_summary", species_id = "BBWO", model_id = "bam_v5_can71")
#' prep_materials("model_fit", species_id = "BBWO", model_id = "bam_v5_can71")
#'
#' # Errors
#' # prep_materials("observations", model_id = "", species_id = "")
#' # prep_materials("observations", model_id = "bam_v5_can71", species_id = "")

prep_materials <- function(component_id, model_id, species_id = NULL) {
  path <- dplyr::filter(
    sdmEvalToolCore::components,
    .data$component == .env$component_id
  ) |>
    #TODO: Is there a reason to have a sub list? i.e. 1?
    purrr::pluck("upload", 1, "output", "path")

  validate_ids(model_id = model_id, species_id = species_id)

  prep_files(
    path,
    name = component_id,
    model_id = model_id,
    species_id = species_id
  )
}

#' Title
#'
#' @param deployment_id
#' @param type
#'
#' @returns
#'
#' @export
#' @examplesIf have_data()
#' prep_deployments("deployment1", "questions")
#' prep_deployments("deployment1", "subunits")
#' prep_deployments("deployment2", "questions")

prep_deployments <- function(deployment_id, type) {
  validate_ids(deployment_id = deployment_id)

  #TODO: Get this from sdmEvalToolCore?
  ext <- ifelse(type == "questions", "csv", "gpkg")
  path <- paste0("deployments/{deployment_id}/deployment_{type}.", ext)

  prep_files(
    path,
    name = paste("Deployment", type),
    deployment_id = deployment_id,
    type = type
  ) |>
    dplyr::mutate(
      french = as.character(.data$french),
      french = tidyr::replace_na(.data$french, "")
    ) |>
    # TODO: This shouldn't be in the data
    dplyr::select(-dplyr::any_of("X"))
}

prep_files <- function(path, name, ...) {
  path <- make_target_path(path, data = list(...))

  validate(need(
    file.exists(path),
    paste0(
      pretty(name),
      " doesn't exist. Have you supplied the correct base path?\n",
      path
    )
  ))

  read_file(path)
}

pretty <- function(x) {
  x |>
    stringr::str_replace_all("_", " ") |>
    stringr::str_remove_all("id") |>
    stringr::str_to_title()
}

#' Have local data?
#'
#' Checks whether the user has local data available for this tool.
#'
#' @returns TRUE/FALSE
#'
#' @export
#' @examples
#' have_data()
have_data <- function() {
  dir.exists(sdmEvalToolCore::sdmevaltool_options()$base)
}
