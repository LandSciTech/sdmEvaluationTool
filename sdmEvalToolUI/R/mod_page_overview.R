#' Test the Overview Page
#'
#' @returns A Shiny app object
#' @noRd
#'
#' @examplesIf have_data()
#' test_page_overview()

test_page_overview <- function(
  opts = list(user_id = "holden", user_role = "modeler"),
  ...
) {
  test_page("mod_page_overview", opts = opts, ...)
}

#' Overview Page UI
#'
#' @param id Shiny module ID
#' @param title Page title
#'
#' @returns Shiny UI
#'
#' @export

mod_page_overview_ui <- function(id = "overview", title = "Overview") {
  nav_panel(
    title,
    sdm_card(
      card_header("Current status of review"),
      reactable::reactableOutput(NS(id, "tbl_overview"))
    )
  )
}

#' Overview Page Server
#'
#' @param id Shiny module ID
#' @param ... Additional arguments passed via expand_dots including
#' deployment_id, model_id, species_id, and overview_inputs (reactiveVal)
#'
#' @returns Server function for Shiny module
#'
#' @export

mod_page_overview_server <- function(id = "overview", ...) {
  # Expected arguments
  expand_dots(...)
  stopifnot(is.reactive(deployment_id))
  stopifnot(is.reactive(model_id))
  stopifnot(is.reactive(species_id))
  stopifnot(is.reactive(overview_inputs)) # reactiveVal

  purrr::walk(opts, \(o) stopifnot(is.reactive(o)))

  moduleServer(id, function(input, output, session) {
    # Table for display
    tbl <- reactive({
      evals_details(opts$user_id(), opts$user_role())
    })

    # Table for input keys
    tbl_top <- reactive({
      tbl() |>
        dplyr::select("deployment_id", "model_id", "species_id") |>
        dplyr::distinct()
    })

    output$tbl_overview <- reactable::renderReactable({
      validate(
        need(opts$user_id(), "Please select a user"),
        need(opts$user_role(), "Please select a user role")
      )
      validate(
        need(
          nrow(tbl()) > 0,
          "No deployments for this user in this role"
        )
      )
      evals_table(tbl(), opts$user_role())
    })

    observe({
      # Update reactiveVal created by sdm_tool()
      i <- tbl_top() |>
        dplyr::slice(input$button_clicked) |>
        as.list()

      overview_inputs(i)
    }) |>
      bindEvent(input$button_clicked, ignoreInit = TRUE)
  })
}

#' Create a Reactable Overview table
#'
#' Creates reactable table displaying evaluation progress for either modelers or
#' evaluators. The table shows deployment-model combinations, species,
#' components, and their completion status.
#'
#' @param tbl Data frame. Evaluation details from `evals_details()`
#' @param user_role Character. User role ("modeler" or "evaluator")
#'
#' @returns A reactable table object
#'
#' @export
#' @examplesIf have_data()
#' tbl <- evals_details("holden", "modeler")
#' evals_table(tbl, "modeler")
#' tbl <- evals_details("draper", "evaluator")
#' evals_table(tbl, "evaluator")

evals_table <- function(tbl, user_role) {
  # If evaluator only show evaluations created
  # If modeler only show deployments created
  group_by <- "deployment_model_name"
  if (user_role == "modeler") {
    group_by <- c(group_by, "evaluation_create_user_name")
  }

  # Grouped tables https://glin.github.io/reactable/articles/examples.html?q=collaps#grouping-and-aggregation
  # Nested tables https://glin.github.io/reactable/articles/examples.html?q=collaps#nested-tables

  pal <- c("white", grDevices::colorRampPalette(c("#d9fbfb", "#081a1c"))(100))
  pal_text <- c(rep("black", 50), rep("white", 51))

  tbl_components <- tbl

  tbl_top <- tbl |>
    dplyr::summarize(
      progress = sum(n_q_complete) / sum(n_q),
      .by = c(
        "deployment_model_name",
        "evaluation_create_user_name",
        "species_display",
        "species_id" # Key which determines button presence
      )
    ) |>
    dplyr::mutate(button = NA) |>
    dplyr::relocate("button", .after = "species_display")

  deployment_width <- 250

  reactable::reactable(
    tbl_top,
    groupBy = group_by,
    defaultColDef = reactable::colDef(
      vAlign = "center",
      headerVAlign = "bottom"
    ),
    # Sub Table with component-level progress
    details = function(index) {
      comp <- dplyr::filter(
        tbl_components,
        .data$deployment_model_name == tbl_top$deployment_model_name[index],
        .data$species_display == tbl_top$species_display[index]
      ) |>
        dplyr::mutate(
          progress_perc = round(.data$n_q_complete / .data$n_q * 100)
        ) |>
        dplyr::select(
          "Component" = "component_name",
          "Progress" = "n_q_display",
          "progress_perc"
        )
      div(
        # fmt: skip
        style = paste0(
          "margin-left:", deployment_width * 1.2, "px;",
          "margin-bottom: 20px"),
        reactable::reactable(
          comp,
          outlined = TRUE,
          width = 500,
          columns = list(
            progress_perc = reactable::colDef(show = FALSE),
            Progress = reactable::colDef(
              align = "center",
              maxWidth = 150,
              # Colour by percent complete
              style = \(v, i) {
                bg <- pal[comp$progress_perc[i]]
                txt <- pal_text[comp$progress_perc[i]]
                list(background = bg, color = txt)
              }
            )
          )
        )
      )
    },
    columns = list(
      species_id = reactable::colDef(show = FALSE),
      # Button column
      button = reactable::colDef(
        name = "",
        sortable = FALSE,
        cell = \(v, i) {
          if (!is.na(tbl_top$species_id[i]) & tbl_top$species_id[i] != "ALL") {
            htmltools::tags$button("Evaluate", class = "btn btn-sm btn-info")
          }
        }
      ),
      deployment_model_name = reactable::colDef(
        name = "Deployment - Model",
        html = TRUE,
        minWidth = 200,
        maxWidth = 250,
        grouped = reactable::JS(
          "function(cellInfo, state) {
        let [d, m] = cellInfo.value.split('---');

        d = `<span style = 'font-weight:600'>${d}</span>`
        m = `<div style = 'padding-left:20px; font-size:0.75rem'>${m}</div>`

      return `${d}<br>${m}`
      }"
        )
      ),
      evaluation_create_user_name = reactable::colDef(
        name = "Evaluator",
        minWidth = 200,
        maxWidth = 250,
        show = user_role == "modeler"
      ),
      species_display = reactable::colDef(
        name = "Species",
        html = TRUE,
        minWidth = 200,
        maxWidth = 400
      ),
      progress = reactable::colDef(
        name = "Progress",
        align = "center",
        minWidth = 100,
        maxWidth = 150,
        format = reactable::colFormat(percent = TRUE, digits = 0),

        # Colour by percent complete
        style = \(v) {
          bg <- pal[round(v * 100)]
          txt <- pal_text[round(v * 100)]
          list(background = bg, color = txt)
        }
      )
    ),
    meta = list(pal = pal, pal_text = pal_text),
    highlight = TRUE,
    onClick = reactable::JS(
      "function(rowInfo, column) {
         // Only handle click events on this column specifically
         if (column.id !== 'button') {
           return
         }
  
         Shiny.setInputValue('overview-button_clicked', rowInfo.index + 1, { priority: 'event' })
      }"
    )
  )
}


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

  eval_complete <- prep_evaluations(con, eval_user)

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
  jsonlite::fromJSON(json) |>
    dplyr::mutate(response = purrr::map(.data$response, list))
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
    n_q_complete = sum(purrr::map_lgl(.data$response, \(x) {
      # Only NULL, NA, "" should be considered missing; Also catch dataframes
      !is.null(x) && (is.data.frame(x) || (!is.na(x) && x != ""))
    }))
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
