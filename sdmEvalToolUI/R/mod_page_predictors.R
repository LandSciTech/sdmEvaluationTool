#' Test the Predictors Page
#'
#' @returns A Shiny app object
#' @noRd
#'
#' @examplesIf have_data()
#' test_page_predictors()

test_page_predictors <- function(...) {
  test_page("mod_page_predictors", ...)
}

#' Predictors Page UI
#'
#' @param id Shiny module ID
#' @param title Page title
#' @param review_width Review width
#'
#' @returns Shiny UI
#'
#' @export
#' @examples
#' mod_page_predictors_ui()

mod_page_predictors_ui <- function(
  id,
  title,
  review_width = NULL
) {
  nav_panel(
    title = span(title, class = "sdm-model-lvl"),
    value = id,
    sdm_layout_sidebar(
      sidebar = mod_utils_evaluations_ui(
        NS(id, "eval"),
        review_width,
        level = "model"
      ),
      mod_comp_predictor_raster_ui(
        NS(id, "predictor_raster"),
        height = "60%",
        header = card_header("Predictor Raster")
      ),
      mod_comp_predictor_metadata_ui(
        NS(id, "predictor_metadata"),
        height = "40%",
        header = card_header("Predictor Metadata")
      )
    )
  )
}

#' Predictors Page Server
#'
#' @param id Shiny module ID
#' @param ... Additional arguments passed via expand_dots including model_id, tbl_models, tbl_species
#'
#' @returns Server function for Shiny module
#'
#' @export

mod_page_predictors_server <- function(id = "predictors", ...) {
  expand_dots(...)
  stopifnot(is.reactive(deployment_id))
  stopifnot(is.reactive(model_id))
  stopifnot(is.reactive(abandoned)) # reactiveVal
  stopifnot(is.reactive(unsaved)) # reactiveVal
  purrr::walk(opts, \(o) stopifnot(is.reactive(o)))

  moduleServer(id, function(input, output, session) {
    # Prepare the evaluation questions
    mod_utils_evaluations_server(
      "eval",
      component_id = c("predictor_metadata", "predictor_raster"),
      deployment_id = deployment_id,
      model_id = model_id,
      species_id = reactive("ALL"),
      opts = opts,
      abandoned = abandoned,
      unsaved = unsaved
    )

    mod_comp_predictor_metadata_server(
      "predictor_metadata",
      model_id = model_id
    )
    mod_comp_predictor_raster_server(
      "predictor_raster",
      model_id = model_id
    )
  })
}
