#' Test the Predictors Page
#'
#' @returns A Shiny app object
#' @noRd
#'
#' @examplesIf have_data()
#' test_page_predictors()

test_page_predictors <- function() {
  # TODO: define location, pages, etc. elsewhere
  prep_data() |> expand_list()

  ui <- bslib::page_navbar(
    title = "SDM Tool Testing",
    theme = sdm_theme(),
    mod_page_predictors_ui()
  )

  server <- function(input, output, session) {
    mod_page_predictors_server(
      deployment_id = reactive("deployment1"),
      model_id = reactive("bam_v5_can71")
    )
  }

  shiny::shinyApp(ui, server, options = list(port = 8080))
}

#' Predictors Page UI
#'
#' @param id Shiny module ID
#' @param title Page title
#'
#' @returns Shiny UI
#'
#' @export
#' @examples
#' mod_page_predictors_ui()

mod_page_predictors_ui <- function(
  id = "predictors",
  title = "Predictors",
  review_width = NULL
) {
  nav_panel(
    title,
    layout_sidebar(
      sidebar = mod_utils_evaluations_ui(NS(id, "eval"), review_width),
    h2(textOutput(NS(id, "title"))),
      mod_comp_predictor_metadata_ui(NS(id, "predictor_metadata")),
      mod_comp_predictor_raster_ui(NS(id, "predictor_raster"))
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

  moduleServer(id, function(input, output, session) {
    output$title <- renderText(paste0(
      "Model predictors for model ",
      model_id()
    ))

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
