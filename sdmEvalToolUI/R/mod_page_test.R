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
#' test_page_test(NULL, NULL, NULL)

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
  id = "test",
  review_width = "50%"
) {
  nav_panel(
    "Test",
    layout_sidebar(
      sidebar = sidebar(
        width = review_width,
        position = "right",
        "Evaluations",
        uiOutput(NS(id, "ui_questions"))
      ),
      h2(textOutput(NS(id, "title"))),
      textOutput(NS(id, "details")),
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
    output$title <- renderText("Test")
    output$details <- renderText({
      paste0(
        "Test for Model: ",
        model_id(),
        " and species ",
        species_id()
      )
    })

    # Evaluations ----------------------------------------------------
    questions_init <- reactive({
      prep_questions(
        deployment_id = deployment_id(),
        model_id = model_id(),
        species_id = species_id(),
        lang = opts$lang()
      )
    }) |>
      bindCache(deployment_id(), model_id(), species_id())

    output$ui_questions <- renderUI({
      ui_questions(questions_init(), session = session)
    })

    # TODO: Save values temporarily, so not lost if don't "Save Responses"?
    #   Highlight Save Responses in different colours if not saved
    #   Highlight Page tab in different colours if not saved
    #   Modal warns user when switching deployments/models/species if have unsaved work.

    questions <- reactive({
      #TODO: capture values as...JSON?
      #TODO: Save values to disk
      #TODO: Warn user if overwriting?
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
