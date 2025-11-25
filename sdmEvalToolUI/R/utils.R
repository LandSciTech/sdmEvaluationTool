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
#' @param component_id Character. Component ID
#' @param model_id Character. Model ID
#' @param species_id Character. Model ID
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
    .data$type == "material",
    .data$component == .env$component_id
  ) |>
    dplyr::pull(.data$path)

  if (stringr::str_detect(path, "species_id")) {
    validate_ids(model_id = model_id, species_id = species_id)
  } else {
    validate_ids(model_id = model_id)
  }

  prep_files(
    path,
    name = component_id,
    model_id = model_id,
    species_id = species_id
  )
}

#' Prepare Deployments
#'
#' @param deployment_id Character. Deployment ID
#' @param type Character. Type of data to load ("deployment_questions" or "deployment_subunits")
#'
#' @returns Data frame of deployments
#'
#' @export
#' @examplesIf have_data()
#' prep_deployments("deployment1", "deployment_questions")
#' prep_deployments("deployment1", "deployment_subunits")
#' prep_deployments("deployment2", "deployment_questions")

prep_deployments <- function(deployment_id, deployment_type) {
  path <- dplyr::filter(
    sdmEvalToolCore::components,
    .data$type == "deployment",
    .data$component == .env$deployment_type
  ) |>
    dplyr::pull(.data$path)

  validate_ids(deployment_id = deployment_id)

  dep <- prep_files(
    path,
    name = deployment_type,
    deployment_id = deployment_id
  )

  if (deployment_type != "deployment_subunits") {
    dep <- dplyr::mutate(
      dep,
      french = as.character(.data$french),
      french = tidyr::replace_na(.data$french, "")
    ) |>
      # TODO: This shouldn't be in the data
      dplyr::select(-dplyr::any_of("X"))
  }

  dep
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


#' Prepare Evaluation Questions
#'
#' Reads, combines and prepares questions for use in UIs.
#'
#' @param component_id Character. Component ID
#' @param deployment_id Character. Deployment ID
#' @param model_id Character. Model ID
#' @param species_id Character. Species ID
#'
#' @returns Data frame of questions
#'
#' @export
#' @examplesIf have_data()
#' prep_questions("test", "deployment1", "bam_v5_can71", "BBWO")
#' prep_questions("observations", "deployment1", "bam_v5_can71", "BBWO")
#' prep_questions("model_fit", "deployment1", "bam_v5_can71")

prep_questions <- function(
  component_id,
  deployment_id,
  model_id,
  species_id
) {
  if (missing(species_id) || species_id == "ALL") {
    validate_ids(
      deployment_id = deployment_id,
      model_id = model_id
    )
    species_id <- "ALL"
  } else {
    validate_ids(
      deployment_id = deployment_id,
      model_id = model_id,
      species_id = species_id
    )
  }

  q <- fetch_questions(deployment_id, component_id)

  q |>
    dplyr::rename("label" = sdmevaltool_options()$lang) |>
    dplyr::mutate(
      ui = dplyr::case_match(
        .data$type,
        "text" ~ "text_input",
        "heading" ~ "h2",
        "gold_standard" ~ "gold_standard_input",
        "ordinal" ~ "slider_input"
      ),
      material_id = paste(
        .env$model_id,
        .env$species_id,
        .data$component,
        sep = "_"
      ),
      id = paste(
        .env$deployment_id,
        .data$material_id,
        .data$order,
        sep = "_"
      )
    )
}

fetch_questions <- function(deployment_id, component_id) {
  q <- dplyr::rows_upsert(
    sdmEvalToolCore::default_questions,
    prep_deployments(deployment_id, "deployment_questions"),
    by = c("component", "order")
  )

  if (component_id != "test") {
    q <- dplyr::filter(q, .data$component == .env$component_id)
  }

  q
}

dummy_session <- list(ns = \(x) paste0("session-", x))

#' Temporarily skip examples
#'
#' Examples using @examplesIf, will fail if there is nothing to run (i.e.
#' becaues the example is commented out waiting for a working version).
#'
#' @returns Nothing
#'
#' @export
#' @examples
#' skip_eg()

skip_eg <- function() {
  invisible()
}


named_ids <- function(df_db, id = "id", name = "name") {
  pattern <- glue::glue("\\_{id}|\\_{name}")
  type <- stringr::str_subset(colnames(df_db), pattern)
  if (
    length(type) != 2 ||
      length(unique(stringr::str_remove(type, pattern))) != 1
  ) {
    stop("Non-matching id/name column pairs", call. = FALSE)
  }

  rlang::set_names(
    dplyr::pull(df_db, .data[[type[1]]]),
    dplyr::pull(df_db, .data[[type[2]]])
  )
}


set_options <- function(...) {
  # TODO: Perhaps integrate with sdmEvalToolCore?
  opts <- getOption("sdmevaltool_options")
  options("sdmevaltool_options" = utils::modifyList(opts, list(...)))
}

user_id <- function() {
  sdmevaltool_options()$user_id
}

user_role <- function() {
  sdmevaltool_options()$user_role
}
