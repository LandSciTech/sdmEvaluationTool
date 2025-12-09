#' Test the Model Metadata Page
#'
#' @returns A Shiny app object
#' @noRd
#'
#' @examplesIf have_data()
#' test_page_model_metadata()

test_page_model_metadata <- function(...) {
  test_page("mod_page_model_metadata", ...)
}

#' Model Metadata Page UI
#'
#' @param id Shiny module ID
#' @param title Page title
#'
#' @returns Shiny UI
#'
#' @export
#' @examples
#' mod_page_model_metadata_ui()
mod_page_model_metadata_ui <- function(
  id = "model_metadata",
  title = "Model Metadata"
) {
  nav_panel(
    title,
    h2(textOutput(NS(id, "title"))),
    mod_comp_model_metadata_ui(NS(id, "model_metadata"))
  )
}

#' Model Metadata Page Server
#'
#' @param id Shiny module ID
#' @param ... Additional arguments passed via expand_dots including model_id, species_id, tbl_models, tbl_species
#'
#' @returns Server function for Shiny module
#'
#' @export

mod_page_model_metadata_server <- function(id = "model_metadata", ...) {
  expand_dots(...)
  stopifnot(is.reactive(model_id))

  moduleServer(id, function(input, output, session) {
    output$title <- renderText(paste0("Model Metadata: ", model_id()))

    mod_comp_model_metadata_server("model_metadata", model_id)
  })
}
