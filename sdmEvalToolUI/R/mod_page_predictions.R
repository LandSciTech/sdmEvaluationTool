#' Test the Predictions Page
#'
#' @returns A Shiny app object
#' @noRd
#'
#' @examplesIf have_data()
#' test_page_predictions()

test_page_predictions <- function(...) {
  test_page("mod_page_predictions", ...)
}

#' Predictions Page UI
#'
#' @param id Shiny module ID
#' @param title Page title
#' @param review_width Review width
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
    span(title, class = "sdm-species-lvl"),
    sdm_layout_sidebar(
      sidebar = mod_utils_evaluations_ui(NS(id, "eval"), review_width),
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
  stopifnot(is.reactive(abandoned)) # reactiveVal
  purrr::walk(opts, \(o) stopifnot(is.reactive(o)))

  moduleServer(id, function(input, output, session) {
    # Placeholder reactiveVal until map created
    spatial_ids <- reactiveVal(NULL)

    # Prepare the evaluation questions
    spatial_selection <- mod_utils_evaluations_server(
      "eval",
      component_id = "spatial_prediction",
      deployment_id = deployment_id,
      model_id = model_id,
      species_id = species_id,
      spatial_ids = spatial_ids,
      spatial_type = "areas",
      opts = opts,
      abandoned = abandoned
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
