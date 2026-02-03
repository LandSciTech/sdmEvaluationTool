#' Get Evaluation Details for User
#'
#' Retrieves evaluation details for a specific user based on their
#' role. For modelers, shows all evaluations across users for their deployments.
#' For evaluators, shows only their own evaluations. Returns a data frame with
#' deployment, model, species, component, and completion information.
#'
#' @param user_id Character string. User identifier
#' @param user_role Character string. User role ("modeler" or "evaluator")
#'
#' @returns Data frame with columns:
#'   - `deployment_model_name`
#'   - `evaluation_create_user_name`
#'   - `deployment_name`
#'   - `model_name`
#'   - `species_display`
#'   - `component_name`
#'   - `completed`
#'   - `started`
#'   - `n_q_display`
#'   - `n_q`
#'   - `n_q_complete`
#'
#' @export
#' @examplesIf have_data()
#' evals_details("holden", "modeler")
#' evals_details("holden", "evaluator")
#' evals_details("draper", "modeler")
#' evals_details("draper", "evaluator")

evals_details <- function(user_id, user_role) {
  con <- withr::local_db_connection(db_connect())
  validate(need(
    user_role %in% c("modeler", "evaluator"),
    "Overview table only relevant for modelers and evaluators"
  ))

  # Deployment details we're working with
  deployments <- dplyr::tbl(con, "access") |>
    dplyr::collect() |>
    dplyr::mutate(
      modeler = stringr::str_detect(.data$user_roles, "modeler"),
      evaluator = stringr::str_detect(.data$user_roles, "evaluator")
    )

  deployment_ids <- deployments |>
    dplyr::filter(
      .data$user_id == .env$user_id,
      stringr::str_detect(.data$user_roles, .env$user_role)
    ) |>
    dplyr::pull(.data$deployment_id)

  if (user_role == "modeler") {
    deploy_user <- user_id
    # Which users expected to have evaluations modeler wants to check progress on?
    eval_user <- deployments |>
      dplyr::filter(
        .data$deployment_id %in% .env$deployment_ids,
        stringr::str_detect(.data$user_roles, "evaluator")
      ) |>
      dplyr::pull(.data$user_id)
  } else if (user_role == "evaluator") {
    # Don't care who the deployer/modeller is when looking at own evaluations
    deploy_user <- NULL
    eval_user <- user_id
  }

  eval_expect <- db_read_deployment_materials(
    con,
    deployment_id = deployment_ids
  ) |>
    #fmt: skip
    dplyr::select(
      "deployment_id",
      "material_id",
      "model_id",
      "species_id", 
      dplyr::contains("name"),
      "component_id"
    ) |>
    tidyr::expand_grid(data.frame(evaluation_create_user = eval_user))

  if (nrow(eval_expect) == 0) {
    return(data.frame())
  }

  eval_questions <- eval_expect |>
    dplyr::select("deployment_id", "component_id") |>
    dplyr::distinct() |>
    dplyr::mutate(
      n_q = purrr::map2(
        .data$deployment_id,
        .data$component_id,
        fetch_questions
      ),
      n_q = purrr::map_int(.data$n_q, nrow)
    )

  eval_complete <- prep_evaluations(eval_user)

  if (nrow(eval_complete) == 0) {
    eval_complete <- eval_expect |>
      dplyr::select(
        "deployment_id",
        "material_id",
        "evaluation_create_user"
      ) |>
      dplyr::mutate(n_q = NA, n_q_complete = 0)
  }

  evals <- eval_expect |>
    dplyr::full_join(
      eval_questions,
      by = c("deployment_id", "component_id")
    ) |>
    dplyr::full_join(
      eval_complete,
      by = c(
        "evaluation_create_user",
        "deployment_id",
        "material_id"
      ),
      suffix = c("", ".eval")
    ) |>
    dplyr::mutate(
      species_id = tidyr::replace_na(.data$species_id, "ALL"),
      n_q_complete = tidyr::replace_na(.data$n_q_complete, 0)
    )

  # TODO: Fix once database mismatch is corrected
  # check_q_mismatch(evals$n_q, evals$n_q.eval)

  user <- dplyr::tbl(con, "users") |>
    dplyr::filter(.data$user_id %in% .env$eval_user) |>
    dplyr::select(
      "evaluation_create_user" = "user_id",
      "evaluation_create_user_name" = "user_name"
    ) |>
    dplyr::collect()

  evals <- evals |>
    dplyr::select(-"n_q.eval") |>
    dplyr::mutate(
      started = any(.data$n_q_complete > 0, na.rm = TRUE),
      completed = .data$n_q_complete == .data$n_q,
      completed = tidyr::replace_na(completed, FALSE),
      n_q_display = paste0(.data$n_q_complete, "/", .data$n_q),
      n_q_display = dplyr::if_else(
        .data$completed,
        paste0(.data$n_q_display, " \u2714\ufe0f"),
        .data$n_q_display
      ),
      .by = c("deployment_id", "model_id", "species_id", "component_id")
    ) |>
    dplyr::left_join(user, by = "evaluation_create_user") |>
    fmt_species() |>
    dplyr::mutate(
      deployment_model_name = paste0(
        .data$deployment_name,
        "---",
        .data$model_name
      ),
      component_name = pretty(.data$component_id),
      # To sort "Model" to the top, add space
      species_display = stringr::str_replace(
        .data$species_display,
        "^Model$",
        " Model"
      )
    ) |>
    dplyr::arrange(
      .data$deployment_model_name,
      .data$evaluation_create_user_name,
      .data$species_display
    ) |>
    # fmt:skip
    dplyr::select(
      #"deployment_id", #"deployment_description", "deployment_create_user", #"use_cases", 
      # , "species_id",
      #"evaluation_create_time", "evaluation_modify_user", "evaluation_modify_time",

      "deployment_model_name",
      "evaluation_create_user_name",
      "deployment_name", "model_name", "species_display", "component_name", 
      "completed", "started", 
      "n_q_display", dplyr::starts_with("n_q"),     

      # Keep IDs for filling in app inputs later
      "deployment_id", "model_id", "species_id"      
    ) |>
    dplyr::arrange(
      .data$deployment_model_name,
      .data$evaluation_create_user_name,
      .data$species_display,
      .data$component_name
    )

  evals
}


#' Extract evaluations from JSON
#'
#' Parses JSON-formatted evaluation body into a data frame.
#'
#' @param json Character. JSON-formatted evaluation data
#'
#' @returns Data frame with evaluation information
#'
#' @examples
#' body <- '[{"question": "Q1", "response": "Yes"}]'
#' evals_extract(body)
#' @export

evals_extract <- function(json) {
  json <- stringr::str_replace_all(json, "value\\b", "values")
  jsonlite::fromJSON(json) |>
    dplyr::mutate(
      response = purrr::map(.data$response, \(r) {
        if (!is.list(r)) {
          r <- list(r)
        }
        r
      })
    )
}

#' Calculate number of answered questions
#'
#' Summarizes evaluation data to count total questions and completed questions.
#'
#' @param eval Data frame. Evaluation data with response column
#'
#' @returns Data frame with columns: n_q (total questions), n_q_complete (completed questions)
#'
#' @examples
#' body <- '[{"question": "Q1", "response": "Yes"}, {"question": "Q2", "response": ""}]'
#' eval_data <- evals_extract(body)
#' evals_answered(eval_data)
#' @export

evals_answered <- function(eval) {
  dplyr::summarize(
    eval,
    n_q = dplyr::n(),
    n_q_complete = sum(
      purrr::map_lgl(.data$response, \(x) {
        # Only NULL, NA, "" should be considered missing; Also catch dataframes
        !is.null(x) && (is.data.frame(x) || (!is.na(x) && x != ""))
      })
    )
  )
}


#' Compare number of questions
#'
#' Compares the number of questions from those evaluated (`q2`) to those
#' calculated from the question data (`q1`) Questions from evaluated (`q2`) may
#' be `NA` if evaluations haven't been finished. Will error if values don't
#' match (ignoring `NA`s)
#'
#' @param q1 Vector of Integers, number of questions calculated from Question data.
#' @param q2 Vector of Integers, number of questions evaluated.
#'
#' @returns invisible or error if there is a mismatch.
#'
#' @examples
#' check_q_mismatch(c(1, 1, 2, 10, 6), c(1, 1, 2, 10, 6))
#' check_q_mismatch(c(10, 7, 1), c(10, NA, NA))
#' # check_q_mismatch(c(10, 11, 1), c(10, 10, NA)) # Error
#' @export

check_q_mismatch <- function(q1, q2) {
  if (any(!is.na(q2)) && any(q1[!is.na(q2)] != q2[!is.na(q2)], na.rm = TRUE)) {
    stop("Mismatch between evaluated and deployed questions", call. = FALSE)
  }
}
