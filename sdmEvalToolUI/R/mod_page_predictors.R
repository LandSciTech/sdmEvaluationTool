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
    mod_page_predictors_ui()
  )

  server <- function(input, output, session) {
    mod_page_predictors_server(
      model_id = reactive("bam_v5_can71"),
      species_id = reactive("BBWO"),
      tbl_deployments = tbl_deployments,
      tbl_models = tbl_models,
      tbl_species = tbl_species
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

mod_page_predictors_ui <- function(id = "predictors", title = "Predictors") {
  nav_panel(
    title,
    h2(textOutput(NS(id, "title"))),
    mod_comp_predictor_metadata_ui(NS(id, "predictor_metadata"))
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
  stopifnot(is.reactive(model_id))

  moduleServer(id, function(input, output, session) {
    output$title <- renderText(paste0(
      "Model predictors for model ",
      model_id()
    ))

    mod_comp_predictor_metadata_server("predictor_metadata", model_id)
  })
}
