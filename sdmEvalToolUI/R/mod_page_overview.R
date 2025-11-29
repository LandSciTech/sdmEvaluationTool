#' Test the Overview Page
#'
#' @returns A Shiny app object
#' @noRd
#'
#' @examplesIf have_data()
#' test_page_overview()

test_page_overview <- function() {
  prep_data() |> expand_list()

  ui <- bslib::page_navbar(
    title = "SDM Tool Testing",
    mod_page_overview_ui()
  )

  server <- function(input, output, session) {
    set_options("user_id" = "holden", "user_role" = "modeler")
    mod_page_overview_server(
      deployment_id = reactive("deployment1"),
      model_id = reactive("bam_v5_can71"),
      species_id = reactive("BBWO"),
      tbl_deployments = tbl_deployments,
      tbl_models = tbl_models,
      tbl_species = tbl_species
    )
  }

  shiny::shinyApp(ui, server, options = list(port = 8080))
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
    "Current status of review",
    reactable::reactableOutput(NS(id, "tbl_overview"))
  )
}

#' Overview Page Server
#'
#' @param id Shiny module ID
#' @param ... Additional arguments passed via expand_dots including
#' deployment_id, model_id, species_id
#'
#' @returns Server function for Shiny module
#'
#' @export

mod_page_overview_server <- function(id = "overview", ...) {
  expand_dots(...)
  stopifnot(is.reactive(deployment_id))
  stopifnot(is.reactive(model_id))
  stopifnot(is.reactive(species_id))

  moduleServer(id, function(input, output, session) {
    validate(
      need(user_id(), "Please select a user"),
      need(user_role(), "Please select a user role")
    )

    tbl <- reactive({
      eval_details(user_id(), user_role())
    })

    output$tbl_overview <- reactable::renderReactable({
      evals_table(tbl(), user_role())
    })

    # TODO: Option to click on species/model combination on table to select
    output$table <- reactable::renderReactable({
      reactable::reactable(
        table(),
        highlight = TRUE,
        rowStyle = function(index) {
          if (
            isTruthy(species_id()) &&
              index == which(table()[["species_id"]] == species_id())
          ) {
            list(background = "rgba(0, 0, 0, 0.5)")
          }
        },
        columns = list(
          model_name = reactable::colDef(
            style = reactable::JS(
              "function(rowInfo, column, state) {
              const firstSorted = state.sorted[0]
              // Merge cells if unsorted or sorting by model_name
              if (!firstSorted || firstSorted.id === 'model_name') {
                const prevRow = state.pageRows[rowInfo.viewIndex - 1]
                if (prevRow && rowInfo.values['model_name'] === prevRow['model_name']) {
                  return { visibility: 'hidden' }
                }
              }
            }"
            )
          )
        )
      )
    })
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
#' @examples
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
  group_by <- c(group_by, "species_display")

  # Grouped tables https://glin.github.io/reactable/articles/examples.html?q=collaps#grouping-and-aggregation
  # Nested tables https://glin.github.io/reactable/articles/examples.html?q=collaps#nested-tables

  pal <- c("white", colorRampPalette(c("#d9fbfb", "#081a1c"))(100))
  pal_text <- c(rep("black", 50), rep("white", 51))

  reactable::reactable(
    dplyr::select(
      tbl,
      -"started",
      -"deployment_name",
      -"model_name"
    ),
    groupBy = group_by,
    defaultColDef = reactable::colDef(
      vAlign = "center",
      headerVAlign = "bottom",
    ),
    columns = list(
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
        show = user_role() == "modeler"
      ),
      species_display = reactable::colDef(
        name = "Species",
        html = TRUE,
        minWidth = 500,
        grouped = reactable::JS(
          "function(cellInfo) {
       let out = cellInfo.value
       out = out.replaceAll('(', '(<em>')
       out = out.replaceAll(')', '</emf>)')
       return out
      }"
        )
      ),
      component_name = reactable::colDef(
        name = "Component",
        minWidth = 200,
        maxWidth = 350,
      ),
      n_q_display = reactable::colDef(show = FALSE),
      n_q = reactable::colDef(show = FALSE),
      n_q_complete = reactable::colDef(show = FALSE),
      completed = reactable::colDef(
        name = "Progress",
        minWidth = 100,
        maxWidth = 150,
        aggregate = reactable::JS(
          "function(values, rows) {
      let out = 0

      if(values.length === 1) {
        out = rows['n_q_display']
      } else {             
        rows.forEach(function(row) {
          out += row['completed']
        })
        out = Math.round(out / values.length * 10 ** 2) / 10 ** 2
      }

      return out
}"
        ),
        cell = reactable::JS(
          "function(cellInfo, state) {
        let out = 'Yes'
        if(!cellInfo.aggregated) out = cellInfo.row.n_q_display
        return out
      }"
        ),
        format = reactable::colFormat(percent = TRUE, digits = 0),

        # Colour by percent complete
        style = reactable::JS(
          "function(rowInfo, column, state) {
        const pal = state.meta.pal
        const pal_text = state.meta.pal_text
        let value = 0
        let completed = 0

        if(rowInfo.aggregated) {
          completed = rowInfo.row['completed']
        } else {
          completed = rowInfo.values['n_q_complete'] / rowInfo.values['n_q']
        }
        value = (Math.round(completed * 10 ** 2) / 10 ** 2) * 100
        return { backgroundColor: pal[value] , color: pal_text[value]}
    }"
        )
      )
    ),
    meta = list(pal = pal, pal_text = pal_text),
    highlight = TRUE
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
#' @examples
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
    # Which ussers expected to have evaluations modeler wants to check progress on?
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

  eval_complete <- db_read_evaluations(con, user_id = eval_user) |>
    dplyr::select(
      "deployment_id",
      "material_id",
      "evaluation_create_user",
      "evaluation_body"
    ) |>
    dplyr::mutate(
      evals = purrr::map(.data$evaluation_body, evals_extract),
      evals = purrr::map(.data$evals, evals_answered)
    ) |>
    tidyr::unnest("evals")

  if (nrow(eval_complete) == 0) {
    eval_complete <- eval_expect |>
      dplyr::select("deployment_id", "material_id", "evaluation_create_user") |>
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

  check_q_mismatch(evals$n_q, evals$n_q.eval)

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
      component_name = pretty(.data$component_id)
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
      "n_q_display",           
      dplyr::starts_with("n_q")      
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

evals_extract <- function(json) {
  jsonlite::fromJSON(json)
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

evals_answered <- function(eval) {
  dplyr::summarize(
    eval,
    n_q = dplyr::n(),
    n_q_complete = sum(purrr::map_lgl(.data$response, \(x) {
      # Only NULL, NA, "" should be considered missing
      !is.null(x) && !is.na(x) && x != ""
    }))
    #n_q_display = glue::glue("{n_q_complete}/{n_q}")
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

check_q_mismatch <- function(q1, q2) {
  if (any(!is.na(q2)) && any(q1[!is.na(q2)] != q2[!is.na(q2)], na.rm = TRUE)) {
    stop("Mismatch between evaluated and deployed questions", call. = FALSE)
  }
}
