#' Load material files
#'
#' @param component_id Character. Component ID
#' @param model_id Character. Model ID
#' @param species_id Character. Species ID
#'
#' @returns Loaded file as an R object, material settings returned as an attribute.
#'
#' @export
#' @examplesIf have_data()
#' prep_materials("observations", species_id = "BBWO", model_id = "bam_v5_can71")
#' prep_materials("model_metadata", model_id = "bam_v5_can71")
#' prep_materials("predictor_metadata", model_id = "bam_v5_can71")
#' #prep_materials("predictor_raster", model_id = "bam_v5_can71")
#' prep_materials("spatial_prediction", species_id = "BBWO", model_id = "bam_v5_can71")
#' prep_materials("model_summary", species_id = "BBWO", model_id = "bam_v5_can71")
#' prep_materials("model_fit", species_id = "BBWO", model_id = "bam_v5_can71")
#'
#'
#' # Expect Errors
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

  ms <- prep_material_settings(component_id, model_id, species_id)

  out <- prep_files(
    path,
    name = component_id,
    model_id = model_id,
    species_id = species_id
  )
  attr(out, "material_settings") <- ms
  out
}

#' Prepare Material Settings
#'
#' @param component_id Character. Component ID
#' @param model_id Character. Model ID
#' @param species_id Character. Species ID
#'
#' @returns A list with material settings
#'
#' @export
#' @examplesIf have_data()
#' prep_material_settings("observations", species_id = "BBWO", model_id = "bam_v5_can71")
#' prep_material_settings("predictor_metadata", model_id = "bam_v5_can71")
#' prep_material_settings("spatial_prediction", species_id = "BBWO", model_id = "bam_v5_can71")
#' prep_material_settings("model_summary", species_id = "BBWO", model_id = "bam_v5_can71")
#' prep_material_settings("model_fit", species_id = "BBWO", model_id = "bam_v5_can71")
#' prep_material_settings("model_metadata", model_id = "bam_v5_can71")

prep_material_settings <- function(component_id, model_id, species_id = NULL) {
  con <- withr::local_db_connection(db_connect_check())
  mt <- dplyr::tbl(con, "materials") |>
    dplyr::filter(
      component_id == .env$component_id,
      model_id == .env$model_id
    ) |>
    dplyr::collect()
  if (!is.null(species_id)) {
    if (is.na(species_id)) {
      mt <- mt |>
        dplyr::filter(
          is.na(species_id)
        )
    } else {
      mt <- mt |>
        dplyr::filter(
          species_id == .env$species_id
        )
    }
  }

  if (length(mt$material_settings)) {
    r <- jsonlite::fromJSON(mt$material_settings)
  } else {
    r <- NULL
  }

  r
}

#' Get Material Settings
#'
#' @param x Object.
#'
#' @returns The value of the material settings attribute
#'
#' @export

get_material_settings <- function(x) {
  attr(x, "material_settings")
}

#' Create tooltip from material settings
#'
#' @param material R Object depending on the type of material loaded. May have
#'   attributes such as 'material_settings'.
#'
#' @returns bslib tooltip output from [sdm_tooltip()].
#'
#' @export

tt_material_settings <- function(material) {
  if (is_ready(material) && !is.null(material)) {
    if ("material_settings" %in% names(attributes(material))) {
      tt <- get_material_settings(material)$legend[["en"]]
    } else {
      tt <- material$legend[["en"]]
    }
    tt <- sdm_tooltip(tt)
  } else {
    tt <- NULL
  }
  tt
}

#' Prepare Deployments
#'
#' @param deployment_id Character. Deployment ID
#' @param deployment_type Character. Type of data to load
#' ("deployment_questions" or "deployment_subunits")
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

  if (deployment_type == "deployment_questions") {
    dep <- dplyr::mutate(
      dep,
      french = as.character(.data$french),
      french = tidyr::replace_na(.data$french, "")
    ) |>
      # CLEANUP: This shouldn't be in the data
      dplyr::select(-dplyr::any_of("X"))
  }

  dep
}

#' Generic file prep
#'
#' @param path Character. File path to fetch.
#' @param name Character. Name of data for messaging
#' @param ... Named model, species, etc. values. See `data` from
#' [sdmEvalToolCore::make_target_path()].
#'
#' @returns File contents depending on file type (see [sdmEvalToolCore::read_file()]
#'
#' @export

prep_files <- function(path, name, ...) {
  path <- make_target_path(path, data = list(...))

  validate(need(
    file.exists(path),
    paste0(
      fmt_pretty(name),
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
#' @param user_id Character. User ID.
#'
#' @returns Data frame of questions
#'
#' @export
#' @examplesIf have_data()
#' # Return all questions
#' prep_questions("ALL", "deployment1", "bam_v5_can71", "BBWO")
#'
#' # Return component specific questions
#' prep_questions("observations", "deployment1", "bam_v5_can71", "BBWO")
#' prep_questions("model_fit", "deployment1", "bam_v5_can71")
#' prep_questions("model_summary", "deployment1", "bam_v5_can71")
#'
#' prep_questions(c("model_summary", "model_fit"), "deployment1", "bam_v5_can71")
#'
#' prep_questions("predictor_raster", "deployment1", "bam_v5_can71")
#'
#' # Return default questions
#' prep_questions("observations", "deployment_test", "bam_v5_can71", "BBWO")
#'
#' # Follow up questions
#' prep_questions("model_fit", "deployment2", "bam_v5_can71", "BBWO")
#' prep_questions("observations", "deployment1", "bam_v5_can71", "BBWO")
#'
#' # Add evaluations
#' #prep_questions("observations", "deployment1", "bam_v5_can71", "BBWO", "draper")
#' prep_questions("observations", "deployment1", "bam_v5_can71", "BBWO", "testuser")
#'
#' # For the abandon review
#' prep_questions("app", "deployment1",  "bam_v5_can71", "BBWO", "testuser")

prep_questions <- function(
  component_id,
  deployment_id,
  model_id,
  species_id,
  user_id = NULL
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

  q <- fetch_questions(deployment_id, component_id) |>
    dplyr::rename("label" = lang()) |>
    dplyr::select(-"followup_level") |>
    dplyr::mutate(
      material_id = paste(
        .env$model_id,
        .env$species_id,
        .data$component,
        sep = "_"
      ),
      question_id = paste(
        .env$deployment_id,
        .data$material_id,
        .data$order,
        .data$part,
        sep = "_"
      ),
      metadata_id = stringr::str_split(.data$metadata_id, ",( )?")
    )

  # Add any metadata - Only add those with actual data!
  meta <- prep_materials("model_metadata", model_id = model_id) |>
    dplyr::select("metadata_id", "element", "value") |>
    tidyr::drop_na()

  q <- q |>
    dplyr::mutate(
      metadata = purrr::map(.data$metadata_id, \(m) {
        dplyr::filter(meta, .data$metadata_id %in% .env$m)
      })
    )

  if (!is.null(user_id)) {
    # Get any existing evaluations
    e <- prep_evaluations(
      deployment_id = deployment_id,
      user_id = user_id
    ) |>
      tidyr::unnest("answers") |>
      dplyr::select(dplyr::any_of(c(
        "question_id",
        "response",
        "evaluation_create_user",
        "evaluation_create_time",
        "last_modified"
      )))

    # Add evaluations or NA placeholders to questions
    if (nrow(e) > 0) {
      q <- dplyr::left_join(q, e, by = "question_id")
    } else {
      q <- dplyr::mutate(
        q,
        response = NA_character_,
        evaluation_create_user = NA_character_,
        evaluation_create_time = as.POSIXct(NA),
        last_modified = as.POSIXct(NA)
      )
    }
  }

  q
}

#' Low-level function to read in questions.
#'
#' If deployment doesn't exist, uses [sdmEvalToolCore::default_questions()].
#'
#' @param deployment_id Character. Deployment ID
#' @param component_id Character. Component ID
#'
#' @returns Data frame of questions.
#'
#' @export
#' @examples
#' # Use default questions if deployment doesn't exist
#' fetch_questions("No deployment", "observations")
#'
#' if(have_data()) {
#'   fetch_questions("deployment1", "observations")
#' }
fetch_questions <- function(deployment_id, component_id) {
  # Do we have a valid set of deployment questions? If not use defaults

  q <- tryCatch(
    prep_deployments(deployment_id, "deployment_questions") |>
      dplyr::mutate(values = stringr::str_split(.data$values, ", ?")),
    error = \(x) sdmEvalToolCore::default_questions
  )

  if (any(component_id != "ALL")) {
    q <- dplyr::filter(q, .data$component %in% .env$component_id)
  }
  # TODO: Temporary until all questions updated
  if (!"metadata_id" %in% names(q)) {
    q$metadata_id <- NA_character_
  }

  q
}
