#' Test the Predictions Page
#'
#' @returns A Shiny app object
#' @noRd
#'
#' @examplesIf have_data()
#' test_page_predictions()

test_page_predictions <- function() {
  ui <- bslib::page_navbar(
    title = "SDM Tool Testing",
    theme = sdm_theme(),
    mod_page_predictions_ui()
  )

  server <- function(input, output, session) {
    mod_page_predictions_server(
      deployment_id = reactive("deployment1"),
      model_id = reactive("bam_v5_can71"),
      species_id = reactive("BBWO")
    )
  }

  shiny::shinyApp(ui, server, options = list(port = 8080))
}

#' Predictions Page UI
#'
#' @param id Shiny module ID
#' @param title Page title
#'
#' @returns Shiny UI
#'
#' @export
#' @examples
#' mod_page_predictions_ui()

mod_page_predictions_ui <- function(
  id = "predictions",
  title = "Predictions",
  review_width = NULL
) {
  nav_panel(
    title,
    layout_sidebar(
      sidebar = mod_utils_evaluations_ui(NS(id, "eval"), review_width),
      h2(textOutput(NS(id, "title"))),
      mod_comp_spatial_prediction_ui(NS(id, "spatial_prediction"))
    )
  )
}

#' Predictions Page Server
#'
#' @param id Shiny module ID
#' @param ... Additional arguments passed via expand_dots including model_id, species_id, tbl_models, tbl_species
#'
#' @returns Server function for Shiny module
#'
#' @export

mod_page_predictions_server <- function(id = "predictions", ...) {
  expand_dots(...)
  stopifnot(is.reactive(deployment_id))
  stopifnot(is.reactive(model_id))
  stopifnot(is.reactive(species_id))

  moduleServer(id, function(input, output, session) {
    output$title <- renderText(paste0(
      "Spatial predictions for model ",
      model_id(),
      " and species ",
      species_id()
    ))

    # Placeholder reactiveVal until map created
    spatial_ids <- reactiveVal(NULL)

    # Prepare the evaluation questions
    spatial_selection <- mod_utils_evaluations_server(
      "eval",
      deployment_id,
      model_id,
      species_id,
      spatial_ids,
      spatial_type = "areas"
    )

    mod_comp_spatial_prediction_server(
      "spatial_prediction",
      deployment_id = deployment_id,
      model_id = model_id,
      species_id = species_id,
      spatial_selection = spatial_selection,
      spatial_ids = spatial_ids #reactiveVal to update in module
    )
  })
}
