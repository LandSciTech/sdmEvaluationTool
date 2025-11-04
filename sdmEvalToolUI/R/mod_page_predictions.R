#' Title
#'
#' @returns
#' @noRd
#'
#' @examples
#' test_page_predictions()

test_page_predictions <- function() {
  # TODO: define location, pages, etc. elsewhere
  prep_data() |> expand_list()

  ui <- bslib::page_navbar(
    title = "SDM Tool Testing",
    mod_page_predictions_ui()
  )

  server <- function(input, output, session) {
    mod_page_predictions_server(
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
mod_page_predictions_ui <- function(id = "predictions", title = "Predictions") {
  nav_panel(
    title,
    h2(textOutput(NS(id, "title"))),
    mod_comp_spatial_prediction_ui(NS(id, "spatial_prediction"))
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
mod_page_predictions_server <- function(id = "predictions", ...) {
  moduleServer(id, function(input, output, session) {
    expand_dots(...)

    output$title <- renderText(paste0(
      "Spatial predictions for model ",
      model_id(),
      " and species ",
      species_id()
    ))

    mod_comp_spatial_prediction_server(
      "spatial_prediction",
      model_id = model_id,
      species_id = species_id
    )
  })
}
