#' Test the Model Page
#'
#' @returns A Shiny app object
#' @noRd
#'
#' @examplesIf have_data()
#' test_page_model()

test_page_model <- function() {
  # TODO: define location, pages, etc. elsewhere
  prep_data() |> expand_list()

  ui <- bslib::page_navbar(
    title = "SDM Tool Testing",
    mod_page_model_ui()
  )

  server <- function(input, output, session) {
    mod_page_model_server(
      model_id = reactive("bam_v5_can71"),
      species_id = reactive("BBWO"),
      tbl_deployments = tbl_deployments,
      tbl_models = tbl_models,
      tbl_species = tbl_species
    )
  }

  shiny::shinyApp(ui, server, options = list(port = 8080))
}

#' Model Page UI
#'
#' @param id Shiny module ID
#' @param title Page title
#'
#' @returns Shiny UI
#'
#' @export
#' @examples
#' mod_page_model_ui()
mod_page_model_ui <- function(id = "model", title = "Model") {
  nav_panel(
    title,
    h2(textOutput(NS(id, "title"))),

    h4("Model summary"),
    mod_comp_model_summary_ui(NS(id, "model_summary")),

    h4("Model fit"),
    mod_comp_model_fit_ui(NS(id, "model_fit"))
  )
}

#' Model Page Server
#'
#' @param id Shiny module ID
#' @param ... Additional arguments passed via expand_dots including model_id, species_id, tbl_models, tbl_species
#'
#' @returns Server function for Shiny module
#'
#' @export

mod_page_model_server <- function(id = "model", ...) {
  expand_dots(...)
  stopifnot(is.reactive(model_id))
  stopifnot(is.reactive(species_id))

  moduleServer(id, function(input, output, session) {
    output$title <- renderText(paste0(
      "Model statistics for model ",
      model_id(),
      " and species ",
      species_id()
    ))

    mod_comp_model_summary_server("model_summary", model_id, species_id)
    mod_comp_model_fit_server("model_fit", model_id, species_id)
  })
}
