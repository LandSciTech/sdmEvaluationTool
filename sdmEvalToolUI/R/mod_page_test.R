#' Test the 'test' page
#'
#' @param deployment_id Character. Deployment ID
#' @param model_id Character. Model ID
#' @param species_id Character. Species ID
#'
#' @returns A Shiny app object
#' @noRd
#'
#' @examplesIf have_data()
#' test_page_test()

test_page_test <- function(...) {
  test_page("mod_page_test", ...)
}

#' Test Page UI
#'
#' @param id Shiny module ID
#' @param review_width Character. Width of the review sidebar in percentage.
#'
#' @returns Shiny UI
#'
#' @export
#' @examples
#' mod_page_test_ui()

mod_page_test_ui <- function(
  id,
  review_width = "50%"
) {
  nav_panel(
    title = "Test",
    value = id,
    sdm_layout_sidebar(
      sidebar = sidebar(
        width = review_width,
        position = "right",
        "Evaluations",
        uiOutput(NS(id, "ui_questions"))
      ),
      uiOutput(NS(id, "details")),
      tableOutput(NS(id, "saved"))
    )
  )
}

#' Test Page Server
#'
#' @param id Shiny module ID
#' @param ... Additional arguments passed via expand_dots including deployment_id, model_id, species_id, tbl_models, tbl_species
#'
#' @returns Server function for Shiny module
#'
#' @export

mod_page_test_server <- function(id = "test", ...) {
  expand_dots(...)
  stopifnot(is.reactive(deployment_id))
  stopifnot(is.reactive(model_id))
  stopifnot(is.reactive(species_id))
  purrr::walk(opts, \(o) stopifnot(is.reactive(o)))

  moduleServer(id, function(input, output, session) {
    output$details <- renderUI({
      tagList(
        "Test for Model: ",
        model_id(),
        " and species ",
        species_id(),
        p(),
        "Showing all evaluations possible (regardless of component)"
      )
    })

    # Evaluations ----------------------------------------------------
    questions_init <- reactive({
      prep_questions(
        deployment_id = deployment_id(),
        model_id = model_id(),
        species_id = species_id()
      )
    }) |>
      bindCache(deployment_id(), model_id(), species_id())

    output$ui_questions <- renderUI({
      ui_questions(questions_init())
    })

    questions <- reactive({
      dplyr::mutate(
        questions_init(),
        evaluations = purrr::map(.data$id, \(q) {
          # Grab the value; if NULL use ""
          rlang::set_names(input[[q]] %||% "", q)
        })
      )
    }) |>
      bindEvent(input$save)

    output$saved <- renderTable({
      s <- unlist(questions()$evaluations)
      data.frame(question = names(s), value = unname(s))
    })
  })
}
