#' Title
#'
#' @returns
#' @noRd
#'
#' @examples
#' test_page_model_metadata()

test_page_model_metadata <- function() {
  # TODO: define location, pages, etc. elsewhere
  prep_data() |> expand_list()

  ui <- bslib::page_navbar(
    title = "SDM Tool Testing",
    mod_page_model_metadata_ui()
  )

  server <- function(input, output, session) {
    mod_page_model_metadata_server(
      model_id = reactive("bam_v5_can71"),
      species_id = reactive("BBWO"),
      tbl_materials = tbl_materials,
      tbl_models = tbl_models,
      tbl_species = tbl_species
    )
  }

  shiny::shinyApp(ui, server, options = list(port = 8080))
}

#' Title
#'
#' @param id
#' @param title
#'
#' @returns
#'
#' @export
#' @examples
mod_page_model_metadata_ui <- function(
  id = "model_metadata",
  title = "Model_Metadata"
) {
  nav_panel(
    title,
    h2(textOutput(NS(id, "title"))),
    mod_comp_model_metadata_ui(NS(id, "model_metadata"))
  )
}

#' Title
#'
#' @param id
#'
#' @returns
#'
#' @export
#' @examples
mod_page_model_metadata_server <- function(id = "model_metadata", ...) {
  moduleServer(id, function(input, output, session) {
    rlang::env_bind(rlang::current_env(), !!!list(...))
    output$title <- renderText(paste0("Model Metadata: ", model_id()))

    mod_comp_model_metadata_server("model_metadata", model_id())
  })
}
