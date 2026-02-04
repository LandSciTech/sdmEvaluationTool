prep_data <- function() {
  # CLEANUP: Still required?
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
#' # Add evaluations
#' prep_questions("observations", "deployment1", "bam_v5_can71", "BBWO", "draper")
#' prep_questions("observations", "deployment1", "bam_v5_can71", "BBWO", "testuser")

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
    #CLEANUP: Remove this if numbering changes
    dplyr::mutate(part = dplyr::if_else(part > 0, part - 1, part)) |>
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
      )
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
#' prep_evaluations("testuser")

prep_evaluations <- function(user_id, deployment_id = NULL) {
  con <- withr::local_db_connection(db_connect())

  db_read_evaluations(
    con,
    deployment_id = deployment_id,
    user_id = user_id
  ) |>
    dplyr::mutate(
      answers = purrr::map(.data$evaluation_body, evals_extract),
      answers = purrr::pmap(
        list(.data$deployment_id, .data$material_id, .data$answers),
        \(d, m, a) {
          if ("order" %in% names(a)) {
            a <- dplyr::mutate(
              a,
              question_id = paste(d, m, .data$order, .data$part, sep = "_")
            )
          }
          a
        }
      ),
      evals = purrr::map(.data$answers, evals_answered),
      last_modified = pmax(
        .data$evaluation_create_time,
        .data$evaluation_modify_time,
        na.rm = TRUE
      ) |>
        timestamp_from() |>
        fmt_time()
    ) |>
    dplyr::select(
      "deployment_id",
      "material_id",
      "last_modified",
      "evaluation_create_user",
      "evaluation_create_time",
      "evaluation_body",
      "answers",
      "evals"
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
#' q <- prep_questions("observations", "deployment_test", "bam_v5_can71", "BBWO")
#' a <- test_input_evals(q)
#' save_evaluations(q, a, user_id = "TESTUSER")
#' # Compare
#' e <- prep_evaluations(user_id = "TESTUSER")

save_evaluations <- function(questions, input_list, user_id) {
  con <- withr::local_db_connection(db_connect())

  evals <- questions |>
    dplyr::rename("component_id" = "component") |>
    dplyr::mutate(
      deployment_material_id = stringr::str_remove(
        .data$question_id,
        "_\\d+_\\d+$"
      ),
      deployment_id = stringr::str_extract(
        .data$question_id,
        paste0("^.+(?=_", .data$material_id, ")")
      )
    ) |>
    dplyr::summarize(
      evaluation_body = response_to_json(questions, input_list),
      .by = c(
        "component_id",
        "material_id",
        "deployment_material_id",
        "deployment_id",
        "evaluation_create_user",
        "evaluation_create_time"
      )
    ) |>
    dplyr::mutate(
      # WAITING: Get correct usecases and Notes
      use_case = "Forestry",
      note_create_user = NA_character_,
      note_create_time = NA_integer_,
      note_body = NA_character_
    )

  if (all(is.na(questions$evaluation_create_user))) {
    # First response
    evals <- dplyr::mutate(
      evals,
      evaluation_create_user = .env$user_id,
      evaluation_create_time = timestamp_to(Sys.time()),
      evaluation_modify_user = NA_character_,
      evaluation_modify_time = NA_integer_
    )
  } else {
    # Modified response
    evals <- dplyr::mutate(
      evals,
      evaluation_create_time = timestamp_to(.data$evaluation_create_time),
      evaluation_modify_user = .env$user_id,
      evaluation_modify_time = timestamp_to(Sys.time())
    )
  }

  # Save to file
  db_write_table(
    con,
    table = "evaluations",
    data = evals,
    mode = "upsert"
  )
}

#' Create JSON evaluation body
#'
#' @noRd
response_to_json <- function(questions, input_list) {
  # - All responses have 'values' directly from the question
  # - Only spatial response have a list response including 'value' and 'subunit'

  # Examples:
  # Spatial - "values":["Sever over", ...], "response":[{"value":"Sever over", "subunits": [...]}]
  # Ordinal - "values":["Extremely","Very",...],"response":"Not at all"
  # Simple Text - "values":[],"response":"blahblah"
  input_list <- input_list[!stringr::str_detect(names(input_list), "-show$")]
  input_list <- input_list[!names(input_list) %in% c("save", "ready")]

  evaluation_body <- questions |>
    dplyr::mutate(
      response = purrr::map2(
        .data$type,
        .data$question_id,
        \(type, question_id) {
          inputs <- input_list[stringr::str_detect(
            names(input_list),
            question_id
          )]
          if (type %in% c("simple_text", "ordinal")) {
            r <- unlist(inputs, use.names = FALSE)
          } else if (type == "spatial") {
            r <- purrr::imap(inputs, \(v, i) {
              list(
                value = input_to_value(stringr::str_extract(i, "[A-Za-z_ ]+$")),
                subunits = v
              )
            }) |>
              unname()
          }
        }
      )
    ) |>
    dplyr::select("question_id", "label", "values", "response")

  jsonlite::toJSON(evaluation_body, auto_unbox = TRUE)
}
