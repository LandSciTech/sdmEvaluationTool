#' Title
#'
#' @returns
#'
#' @export
#' @examples
#' test_comp_spatial_prediction()
test_comp_spatial_prediction <- function() {
  ui <- mod_comp_spatial_prediction_ui()

  server <- function(input, output, session) {
    mod_comp_spatial_prediction_server(
      model_id = reactive("bam_v5_can71"),
      species_id = reactive("BBWO")
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
mod_comp_spatial_prediction_ui <- function(id = "comp_spatial_prediction") {
  tagList(
    div(
      style = "position: relative;",
      leaflet::leafletOutput(NS(id, "spatial_prediction")),
      absolutePanel(uiOutput(NS(id, "ui_selectors")), top = 10, right = 10)
    )
  )
}


mod_comp_spatial_prediction_server <- function(
  id = "comp_spatial_prediction",
  model_id,
  species_id
) {
  moduleServer(id, function(input, output, session) {
    spatial_prediction <- reactive(spatial_prediction_prep(
      model_id(),
      species_id()
    ))
    output$spatial_prediction <- leaflet::renderLeaflet({
      spatial_prediction() |>
        spatial_prediction_map()
    })
  })
}


#' Title
#'
#' @param obs
#'
#' @returns
#'
#' @export
#' @examples
#' spatial_prediction_prep(model_id = "bam_v5_can71", species_id = "BBWO") |>
#'   spatial_prediction_map()

spatial_prediction_map <- function(spatial_prediction) {
  leaflet::leaflet() |>
    leaflet::addRasterImage(spatial_prediction[[1]])
}

#' Title
#'
#' @param obs
#'
#' @returns
#'
#' @export
#' @examples
#' spatial_prediction_prep(model_id = "bam_v5_can71", species_id = "BBWO")

spatial_prediction_prep <- function(model_id, species_id) {
  prep_files("spatial_prediction", model_id = model_id, species_id = species_id)
}
