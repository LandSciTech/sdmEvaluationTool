#' Fetch and format submitted evaluations
#'
#' @param user_id Character. User ID.
#' @param deployment_id Character. Deployment ID
#'
#' @returns Data frame of evaluation details
#'
#' @export
#' @examplesIf have_data()
#' #prep_evaluations(c("draper", "okoye"))
#' #prep_evaluations("holden")
#' #prep_evaluations("okoye")
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
      abandoned = purrr::map_lgl(.data$answers, \(a) any(a$abandoned)),
      answers = purrr::pmap(
        list(.data$deployment_id, .data$material_id, .data$answers),
        \(d, m, a) {
          # If necessary, add order and part
          if ("order" %in% names(a)) {
            a <- dplyr::mutate(
              a,
              question_id = paste(d, m, .data$order, .data$part, sep = "_")
            )
          }
          # Either way, get rid of abandoned column
          dplyr::select(a, -"abandoned")
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
      "abandoned",
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
#' @param questions Data frame. Data frame of questions; output of
#' `prep_questions()`.
#' @param input_list List. List of Shiny inputs; output of
#' `reactiveValuesToList(input)`
#' @param user_id Character. User ID.
#'
#' @export
#' @examplesIf have_data()
#' q <- prep_questions("observations", "deployment_test", "bam_v5_can71", "BBWO", "testuser")
#' a <- test_input_evals(q)
#' save_evaluations(q, a, user_id = "testuser")
#' # Compare
#' q <- prep_questions("observations", "deployment_test", "bam_v5_can71", "BBWO", "testuser")
#' e <- prep_evaluations("testuser", "deployment_test")
#' q <- evals_list(q)
#' # waldo::compare(a, q)

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
      evaluation_body = response_to_json(
        .data$component_id,
        .env$questions,
        .env$input_list
      ),
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
  dplyr::group_split(evals, .data$component_id) |>
    purrr::walk(\(e) {
      db_write_table(
        con,
        table = "evaluations",
        data = e,
        mode = "upsert"
      )
    })
}

#' Create JSON evaluation body
#'
#' @noRd
#' @examples
#' q1 <- prep_questions("model_fit", "deployment2", "bam_v5_can71", "BBWO")
#' q2 <- prep_questions("model_summary", "deployment2", "bam_v5_can71", "BBWO")
#' i1 <- test_input_evals(q1)
#' i2 <- test_input_evals(q2)
#' response_to_json("model_fit", rbind(q1, q2), append(i1, i2))

response_to_json <- function(component_id, questions, input_list) {
  # - All responses have 'values' directly from the question
  # - Only spatial response have a list response including 'value' and 'subunit'

  # Examples:
  # Spatial - "values":["Sever over", ...], "response":[{"value":"Sever over", "subunits": [...]}]
  # Ordinal - "values":["Extremely","Very",...],"response":"Not at all"
  # Simple Text - "values":[],"response":"blahblah"

  # Ensure filtered to component_ids and non-button inputs
  input_list <- input_list[!stringr::str_detect(names(input_list), "-show$")]
  questions <- dplyr::filter(
    questions,
    .data$component %in% unique(.env$component_id)
  )

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
          if (!type %in% c("spatial", "ordinal")) {
            r <- unlist(inputs, use.names = FALSE)
          } else {
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

#' Get Evaluation Details for User
#'
#' Retrieves evaluation details for a specific user based on their
#' role. For modelers, shows all evaluations across users for their deployments.
#' For evaluators, shows only their own evaluations. Returns a data frame with
#' deployment, model, species, component, and completion information.
#'
#' @param user_id Character string. User identifier
#' @param user_role Character string. User role ("admin", "modeler" or "evaluator")
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
#' evals_details("testuser", "evaluator")

evals_details <- function(user_id, user_role) {
  con <- withr::local_db_connection(db_connect())
  validate(need(
    user_role %in% c("admin", "modeler", "evaluator"),
    "Overview table only relevant for admins, modelers, and evaluators"
  ))

  # Deployment details we're working with
  deployments <- dplyr::tbl(con, "access") |>
    dplyr::collect() |>
    dplyr::mutate(
      modeler = stringr::str_detect(.data$user_roles, "admin|modeler"),
      evaluator = stringr::str_detect(.data$user_roles, "evaluator")
    )
  deployment_ids <- deployments |>
    dplyr::filter(
      .data$user_id == .env$user_id,
      stringr::str_detect(.data$user_roles, .env$user_role)
    ) |>
    dplyr::pull(.data$deployment_id)

  if (user_role %in% c("admin", "modeler")) {
    deploy_user <- user_id
    # Which users expected to have evaluations admin or modeler wants to check progress on?
    eval_user <- deployments |>
      dplyr::filter(
        .data$deployment_id %in% .env$deployment_ids,
        stringr::str_detect(.data$user_roles, "evaluator")
      ) |>
      dplyr::pull(.data$user_id) |>
      unique() # In case users with multiple deployments
  } else if (user_role == "evaluator") {
    # Don't care who the deployer/modeller is when looking at own evaluations
    deploy_user <- NULL
    eval_user <- user_id
  }

  eval_expect <- db_read_deployment_materials(
    con,
    deployment_id = deployment_ids
  ) |>
    dplyr::select(
      "deployment_id",
      "material_id",
      "model_id",
      "species_id",
      dplyr::contains("name"),
      "component_id"
    )

  # Add in model level 'app' materials
  # (not really materials but to capture app abandon questions)
  app_material <- eval_expect |>
    dplyr::filter(is.na(species_id)) |>
    dplyr::mutate(
      component_id = "app",
      material_id = paste0(.data$model_id, "_ALL_app")
    ) |>
    dplyr::distinct()

  eval_expect <- dplyr::bind_rows(eval_expect, app_material)

  if (nrow(eval_expect) == 0) {
    return(data.frame())
  }

  # Add 'app' level components
  eval_app <- eval_expect |>
    dplyr::filter(!is.na(.data$species_id)) |>
    dplyr::mutate(
      component_id = "app",
      material_id = glue::glue("{model_id}_{species_id}_{component_id}")
    ) |>
    dplyr::distinct()

  eval_expect <- dplyr::bind_rows(eval_expect, eval_app) |>
    dplyr::mutate(evaluation_create_user = .env$eval_user)

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

  # If first evaluation, grab details from expected questions and fill with placeholders
  if (nrow(eval_complete) == 0) {
    eval_complete <- eval_expect |>
      dplyr::select(
        "deployment_id",
        "material_id",
        "evaluation_create_user",
      ) |>
      dplyr::mutate(abandoned = FALSE, n_q = NA, n_q_complete = 0)
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
      n_q_complete = tidyr::replace_na(.data$n_q_complete, 0),
      # For totals, use recorded evaluations if available
      n_q = dplyr::if_else(!is.na(.data$n_q.eval), .data$n_q.eval, .data$n_q)
    )

  evals <- evals |>
    dplyr::mutate(
      abandoned = any(.data$abandoned, na.rm = TRUE),
      .by = c("deployment_id", "model_id", "species_id")
    )

  # WAITING: Fix once database mismatch is corrected
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
    dplyr::filter(.data$component_id != "app") |>
    dplyr::mutate(
      started = any(.data$n_q_complete > 0, na.rm = TRUE),
      completed = .data$n_q_complete == .data$n_q,
      completed = tidyr::replace_na(.data$completed, FALSE),
      n_q_display = paste0(.data$n_q_complete, "/", .data$n_q),
      # Icon for check mark?

      n_q_display = dplyr::if_else(
        .data$completed,
        paste0("\u00A0\u00A0", .data$n_q_display, " \u2714"),
        paste0(.data$n_q_display, "\u00A0\u00A0")
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
        " Model Overall"
      )
    ) |>
    dplyr::mutate(
      model_abandoned = unique(.data$abandoned[.data$species_id == "ALL"]),
      .by = "deployment_model_name"
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
      "abandoned", "model_abandoned",
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
#' evals_extract(test_evaluation_body())
#' @export

evals_extract <- function(json) {
  json <- stringr::str_replace_all(json, "value\\b", "values")
  jsonlite::fromJSON(json) |>
    dplyr::mutate(
      abandoned = purrr::map2_lgl(.data$question_id, .data$response, \(q, r) {
        stringr::str_detect(q, "app_1_0") &&
          unlist(r) %in% c("yes", "Yes", TRUE)
      }),
      values = purrr::map(.data$values, listify),
      response = purrr::map(.data$response, listify)
    )
}

listify <- function(x) {
  if (!is.list(x)) {
    x <- list(x)
  }
  x
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
#' eval_data <- evals_extract(test_evaluation_body())
#' evals_answered(eval_data)
#'
#' eval_data <- evals_extract(test_evaluation_body(component_id = "model_fit_a"))
#' evals_answered(eval_data)
#'
#' eval_data <- evals_extract(test_evaluation_body(component_id = "model_fit_b"))
#' evals_answered(eval_data)
#' @export

evals_answered <- function(eval) {
  eval |>
    dplyr::mutate(
      order = stringr::str_extract(.data$question_id, "\\d+(?=_\\d{1,2}$)"),
      part = stringr::str_extract(.data$question_id, "\\d+$")
    ) |>
    dplyr::mutate(
      count = purrr::map_lgl(.data$response, \(x) {
        any(unlist(x) %in% affirmative())
      }),
      count = any(.data$count),
      .by = c("order")
    ) |>
    dplyr::mutate(count = .data$count | .data$part == 0) |>
    dplyr::summarize(
      n_q = sum(.data$count),
      n_q_complete = sum(
        purrr::map_lgl(.data$response[.data$count], \(x) {
          # Only NULL, NA, "" should be considered missing; Also catch dataframes
          !is.null(x) &&
            ((is.data.frame(x) && any(x$subunits != "")) ||
              (!is.data.frame(x) && !is.na(x) && x != ""))
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
  if (!all(is.na(q2)) && any(q1[!is.na(q2)] != q2[!is.na(q2)], na.rm = TRUE)) {
    stop("Mismatch between evaluated and deployed questions", call. = FALSE)
  }
}

#' Convert questions to input list structure
#'
#' @param questions Data frame. Data frame of questions; output of
#' `prep_questions()`.
#'
#' @returns List which imitates a Shiny input object
#'
#' @export
#' @examplesIf have_data()
#' q <- prep_questions("observations", "deployment1", "bam_v5_can71", "BBWA", "testuser")
#' evals_list(q)
#' q <- prep_questions("model_summary", "deployment1", "bam_v5_can71", "BBWA", "testuser")
#' evals_list(q)

evals_list <- function(questions) {
  q <- questions |>
    dplyr::mutate(
      values = dplyr::if_else(
        !.data$type %in% "spatial",
        list(""),
        values
      ),
      response = purrr::map(.data$response, \(r) {
        r <- if ("subunits" %in% names(r)) r$subunits else r
        r <- if (all(is.null(r) | is.na(r))) "" else r
        listify(r)
      })
    ) |>
    tidyr::unnest(cols = c("values", "response")) |>
    dplyr::mutate(
      input_id = purrr::map2_chr(.data$values, .data$question_id, \(v, q) {
        if (v != "") paste0(q, "-", value_to_input(v)) else q
      }),
      response = purrr::map(.data$response, \(r) {
        if (length(r) == 0) NULL else r
      })
    )
  rlang::set_names(as.list(q$response), q$input_id)
}
