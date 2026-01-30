prep_data <- function() {
  # TODO: Assign this elsewhere?
  if (is.null(sdmevaltool_options()$base)) {
    sdmevaltool_options(base = "../misc/base")
  }

  con <- withr::local_db_connection(db_connect())
  tbl_models <- db_read_models(con)
  tbl_species <- db_read_species(con)
  tbl_deployments <- dplyr::tbl(con, "deployments") |> dplyr::collect()

  list(
    "tbl_deployments" = tbl_deployments,
    "tbl_models" = tbl_models,
    "tbl_species" = tbl_species
  )
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
#' @param deployment_type Character. Type of data to load ("deployment_questions" or "deployment_subunits")
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


#' Prepare Evaluation Questions
#'
#' Reads, combines and prepares questions for use in UIs. `model_id` and
#' `species_id` required to create `material_id`.
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
#' # Return all questions
#' prep_questions(NULL, "deployment1", "bam_v5_can71", "BBWO")
#'
#' # Return component specific questions
#' prep_questions("observations", "deployment1", "bam_v5_can71", "BBWO")
#' prep_questions("model_fit", "deployment1", "bam_v5_can71")
#' prep_questions("model_summary", "deployment1", "bam_v5_can71")
#'
#' prep_questions(c("model_summary", "model_fit"), "deployment1", "bam_v5_can71")
#'
#' prep_questions("predictor_raster", "deployment1", "bam_v5_can71")

prep_questions <- function(
  component_id = NULL,
  deployment_id,
  model_id,
  species_id
) {
  if (
    missing(species_id) ||
      is.null(species_id) ||
      species_id == "" ||
      species_id == "ALL"
  ) {
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
    dplyr::rename("label" = lang()) |>
    #TODO: Remove this if numbering changes
    dplyr::mutate(part = dplyr::if_else(part > 0, part - 1, part)) |>
    dplyr::mutate(
      values = stringr::str_split(.data$values, ", ?"),
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
        .data$part,
        sep = "_"
      )
    )
}

fetch_questions <- function(deployment_id, component_id) {
  # Do we have a valid set of deployment questions? If not use defaults
  q <- tryCatch(
    prep_deployments(deployment_id, "deployment_questions"),
    error = \(x) sdmEvalToolCore::default_questions
  )

  if (!is.null(component_id)) {
    q <- dplyr::filter(q, .data$component %in% .env$component_id)
  }

  q
}

#' Fetch and format submitted evaluations
#'
#' @param user_id Character. ID of the user who created the evaluation to fetch.
#' @param con DB connection
#'
#' @returns Data frame of evaluation details
#'
#' @export
#' @examplesIf have_data()
#' prep_evaluations(c("draper", "okoye"))
#' prep_evaluations("holden")
#' prep_evaluations("okoye")
#' prep_evaluations("TESTUSER")

prep_evaluations <- function(user_id, deployment_id = NULL) {
  con <- withr::local_db_connection(db_connect())
  db_read_evaluations(con, deployment_id = deployment_id, user_id = user_id) |>
    dplyr::select(
      "deployment_id",
      "material_id",
      "evaluation_create_user",
      "evaluation_body"
    ) |>
    dplyr::mutate(
      answers = purrr::map(.data$evaluation_body, evals_extract),
      evals = purrr::map(.data$answers, evals_answered)
    ) |>
    tidyr::unnest("evals")
}


#' Save evaluations
#'
#' @param questions Questions
#' @param input_list Input list
#'
#' @export
#' @examples
#' q <- prep_questions("observations", "deployment1", "bam_v5_can71", "BBWO")
#' a <- list(c("id1", "id2"), c(NULL), "testing", "", "", "", "") |>
#'   rlang::set_names(q$id)
#' # answers <- purrr::map(list(input), \(x) x[[questions_init()$id]])
save_evaluations <- function(questions, input_list) {
  r <- response_to_json(questions, input_list)
}

response_to_json <- function(questions, input_list) {
  a <- input_list |>
    names() |>
    stringr::str_subset("-show", negate = TRUE)

  r <- questions$id |>
    purrr::map(\(x) {
      keep <- stringr::str_subset(a, x)
      value <- stringr::str_remove(keep, glue::glue("{x}-"))
      if (length(keep) > 1) {
        r <- purrr::map2(keep, value, \(k, v) {
          list(value = v, subunits = unname(a[[k]]))
        })
      } else {
        browser()
        r <- input_list[[keep]]
      }
      r
    })

  questions <- dplyr::mutate(questions, response = r)

  jsonlite::toJSON(questions, auto_unbox = TRUE)
}
