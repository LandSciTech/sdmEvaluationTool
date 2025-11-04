#' Title
#'
#' @returns
#' @noRd
#'
#' @examples
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

#' Title
#'
#' @param id
#'
#' @returns
#'
#' @export
#' @examples
mod_page_model_server <- function(id = "model", ...) {
  moduleServer(id, function(input, output, session) {
    expand_dots(...)
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
