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
#' @examples
#' mod_page_overview_ui()

mod_page_overview_ui <- function(id = "overview", title = "Overview") {
  nav_panel(
    title,
    "Current status of review",
    #reactable::reactableOutput(NS(id, "table"))
  )
}

#' Overview Page Server
#'
#' @param id Shiny module ID
#' @param ... Additional arguments passed via expand_dots including deployment_id, model_id, species_id, tbl_models, tbl_species
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
    # table <- reactive({
    #   tbl_overview(
    #     role,
    #     deployment_id,
    #     model_id,
    #     species_id,
    #     tbl_models,
    #     tbl_species,
    #     tbl_materials
    #   )
    # })

    output$tbl_overview <- reactable::renderReactable({
      tbl <- df_details()

      # If evaluator only show evaluations created
      # If modeler only show deployments created
      if (input$role == "evaluator") {
        tbl <- dplyr::filter(tbl, .data$evaluation_create_user == user())
      } else if (input$role == "modeler") {
        tbl <- dplyr::filter(tbl, .data$deployment_create_user == user())
      }

      # Nested tables https://glin.github.io/reactable/articles/examples.html?q=collaps#nested-tables

      tbl0 <- dplyr::select(
        tbl,
        "deployment_name",
        "model_name",
        "species_display",
        "component_id",
        "complete"
      ) |>
        dplyr::arrange("deployment_name", "model_name", "species_display")

      tbl |>
        dplyr::mutate(
          species_display = tidyr::replace_na(.data$species_id, "Model")
        ) |>
        dplyr::summarize(
          last_eval = max(.data$evaluation_create_time, na.rm = TRUE),
          last_edit = max(.data$evaluation_modify_time, na.rm = TRUE),
          last_change = pmax(.data$last_eval, .data$last_edit, na.rm = TRUE),
          n = dplyr::n(),
          n_complete = sum(.data$complete, na.rm = TRUE),
          n_display = paste0(.data$n_complete, "/", .data$n),
          .by = c("deployment_name", "model_name", "species_display")
        )
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

df_details <- function() {
  con <- withr::local_db_connection(db_connect())
  tbl_materials <- db_read_deployment_materials(con)
  tbl_questions <- tbl_materials |>
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

  # TODO: Pull out evaluations to see which are actually responded to.
  df <- db_read_evaluations(con) |>
    #TODO: Temporary
    dplyr::mutate(
      deployment_material_id = stringr::str_remove(
        .data$deployment_material_id,
        " bam\\_v5\\_can71$"
      ),
      material_id = stringr::str_remove(.data$material_id, " bam\\_v5\\_can71$")
    ) |>
    dplyr::mutate(
      evals = purrr::map(.data$evaluation_body, evals_extract),
      evals = purrr::map(.data$evals, evals_answered)
    ) |>
    tidyr::unnest("evals") |>
    dplyr::full_join(
      tbl_materials,
      by = c("deployment_id", "material_id", "deployment_material_id")
    ) |>
    dplyr::full_join(
      tbl_questions,
      by = c("deployment_id", "component_id"),
      suffix = c("", ".eval")
    ) |>
    dplyr::mutate(
      species_id = tidyr::replace_na(.data$species_id, "ALL")
    )

  dplyr::mutate(
    start = any(.data$n_q_complete),
    complete = .data$n_q_complete == .data$n_q,
    .by = "deployment_id"
  ) |>
    dplyr::full_join(
      tbl_materials,
      by = c("deployment_id", "material_id", "deployment_material_id")
    ) |>
    fmt_species() |>
    # fmt:skip
    dplyr::select(
      "deployment_id", "deployment_name", "deployment_description", "deployment_create_user", #"use_cases", 
      "model_id", "model_name", 
      "species_id", "species_display", 
      "evaluation_create_user", "evaluation_create_time", "evaluation_modify_user", "evaluation_modify_time",
      dplyr::starts_with("n_q"),
      "component_id"
    )

  df
}


evals_extract <- function(json) {
  jsonlite::fromJSON(json)
}

evals_answered <- function(eval) {
  dplyr::summarize(
    eval,
    n_q = dplyr::n(),
    n_q_complete = sum(purrr::map_lgl(.data$response, isTruthy)),
    n_q_display = glue::glue("{n_q}/{n_q_complete}")
  )
}
