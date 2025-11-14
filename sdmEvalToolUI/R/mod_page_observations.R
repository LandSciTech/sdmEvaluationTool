#' Test the Observations Page
#'
#' @param deployment_id Character. Deployment ID
#' @param model_id Character. Model ID
#' @param species_id Character. Species ID
#'
#' @returns A Shiny app object
#' @noRd
#'
#' @examplesIf have_data()
#' test_page_observations()
#' test_page_observations(NULL, NULL, NULL)

test_page_observations <- function(
  deployment_id = "deployment1",
  model_id = "bam_v5_can71",
  species_id = "BBWO"
) {
  # TODO: define location, pages, etc. elsewhere
  prep_data() |> expand_list()

  ui <- bslib::page_navbar(
    title = "SDM Tool Testing",
    mod_page_observations_ui()
  )

  server <- function(input, output, session) {
    mod_page_observations_server(
      deployment_id = reactive(deployment_id),
      model_id = reactive(model_id),
      species_id = reactive(species_id),
      tbl_deployments = tbl_deployments,
      tbl_models = tbl_models,
      tbl_species = tbl_species
    )
  }

  shiny::shinyApp(ui, server, options = list(port = 8080))
}

#' Observations Page UI
#'
#' @param id Shiny module ID
#' @param title Page title
#' @param review_width Character. Width of the review sidebar in percentage of the screen
#'
#' @returns Shiny UI
#'
#' @export
#' @examples
#' mod_page_observations_ui()
mod_page_observations_ui <- function(
  id = "observations",
  title = "Observations",
  review_width = "50%"
) {
  nav_panel(
    title,
    layout_sidebar(
      sidebar = sidebar(
        width = review_width,
        position = "right",
        "Evaluations",
        uiOutput(NS(id, "ui_questions"))
      ),
      h2(textOutput(NS(id, "title"))),
      mod_comp_observations_ui(NS(id, "comp_obs"))
    )
  )
}

#' Observations Page Server
#'
#' @param id Shiny module ID
#' @param ... Additional arguments passed via expand_dots including deployment_id, model_id, species_id, tbl_models, tbl_species
#'
#' @returns Server function for Shiny module
#'
#' @export

mod_page_observations_server <- function(id = "observations", ...) {
  expand_dots(...)
  stopifnot(is.reactive(deployment_id))
  stopifnot(is.reactive(model_id))
  stopifnot(is.reactive(species_id))

  moduleServer(id, function(input, output, session) {
    output$title <- renderText({
      paste0(
        "Observations for Model: ",
        model_id(),
        " and species ",
        species_id()
      )
    })

    # Evaluations ----------------------------------------------------
    questions_init <- reactive({
      #TODO: Read values from disk?
      prep_questions(
        component_id = "observations",
        deployment_id = deployment_id(),
        model_id = model_id(),
        species_id = species_id()
      )
    }) |>
      bindCache(deployment_id(), model_id(), species_id())

    output$ui_questions <- renderUI({
      ui_questions(questions_init(), session)
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
        evaluations = purrr::map(.data$id, \(q) rlang::set_names(input[[q]], q))
      )
    }) |>
      bindEvent(input$save)

    output$saved <- renderText({
      questions()$evaluations[1][[1]]
    })

    mod_comp_observations_server(
      "comp_obs",
      model_id = model_id,
      species_id = species_id
    )
  })
}
