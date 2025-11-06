prep_data <- function(lang = "english") {
  # TODO: Assign this elsewhere?
  sdmEvalToolCore::sdmevaltool_options(base = "../misc/base")

  path_data <- file.path(
    sdmEvalToolCore::sdmevaltool_options()$base,
    "sdm_evaluation_db.sqlite"
  )

  db <- DBI::dbConnect(path_data, drv = RSQLite::SQLite())
  tbl_models <- dplyr::tbl(db, "models") |>
    dplyr::collect()
  tbl_species <- dplyr::tbl(db, "species") |>
    dplyr::collect() |>
    dplyr::mutate(
      species_display = paste0(
        .data[[paste0(lang, "_name")]],
        " (",
        .data$scientific_name,
        ")"
      )
    )
  tbl_materials <- dplyr::tbl(db, "materials") |>
    dplyr::collect()

  list(
    "tbl_models" = tbl_models,
    "tbl_species" = tbl_species,
    "tbl_materials" = tbl_materials
  )
}


expand_list <- function(l, env = rlang::caller_env()) {
  rlang::env_bind(env, !!!l)
}

expand_dots <- function(..., env = rlang::caller_env()) {
  rlang::env_bind(env, !!!list(...))
}

#' Load files
#'
#' @param name Character. File name.
#' @param ext Character. File extension.
#' @param ... `model_id`, `species_id`, or `deployment_id` for the "Model", "Species", or "Deployment"
#'   to read
#'
#' @returns Loaded file as an R object
#'
#' @export
#' @examplesIf have_data()
#' prep_files("observations", species_id = "BBWO", model_id = "bam_v5_can71")
#' #prep_files("model_metadata", model_id = "bam_v5_can71")
#' prep_files("predictor_metadata", model_id = "bam_v5_can71")
#' #prep_files("predictor_raster", model_id = "bam_v5_can71")
#' prep_files("spatial_prediction", species_id = "BBWO", model_id = "bam_v5_can71")
#' prep_files("model_summary", species_id = "BBWO", model_id = "bam_v5_can71")
#' prep_files("model_fit", species_id = "BBWO", model_id = "bam_v5_can71")

prep_files <- function(component, ext, ...) {
  expand_dots(...)

  # For developer
  if (exists("model_id") && exists("species_id") && exists("dep")) {
    stop(
      "Incorrect usage: Cannot supply 'model_id', 'species_id', and ",
      "'deployment_id' all together"
    )
  }

  path <- dplyr::filter(
    sdmEvalToolCore::components,
    .data$component == .env$component
  ) |>
    #TODO: Is there a reason to have a sub list? i.e. 1?
    purrr::pluck("upload", 1, "output", "path")

  # For the user
  if (exists("model_id")) {
    validate(need(model_id, "Please select a model"))
  }
  if (exists("species_id")) {
    validate(need(model_id, "Please select a model"))
    validate(need(species_id, "Please select a species"))
  }
  if (exists("deployment_id")) {
    validate(need(deployment_id, "Please select a Deployment"))
  }

  path <- sdmEvalToolCore::make_target_path(path, data = list(...))

  validate(need(
    file.exists(path),
    paste0(
      pretty(component),
      " doesn't exist. Have you supplied the correct base path?\n",
      path
    )
  ))

  sdmEvalToolCore::read_file(path)
}

pretty <- function(x) {
  x |>
    stringr::str_replace_all("_", " ") |>
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
