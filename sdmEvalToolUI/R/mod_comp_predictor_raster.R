#' Test the Predictor Raster Component
#'
#' @returns A Shiny app object
#'
#' @export
#' @examplesIf have_data()
#' test_comp_predictor_raster()

test_comp_predictor_raster <- function() {
  ui <- mod_comp_predictor_raster_ui()

  server <- function(input, output, session) {
    mod_comp_predictor_raster_server(
      model_id = reactive("bam_v5_can71")
    )
  }

  shiny::shinyApp(ui, server, options = list(port = 8080))
}

#' Predictor Raster Component UI
#'
#' @param id Shiny module ID
#'
#' @returns Shiny UI
#'
#' @export
#' @examples
#' mod_comp_predictor_raster_ui()
mod_comp_predictor_raster_ui <- function(id = "comp_predictor_raster") {
  tagList(
    tagList(
      leaflet::leafletOutput(NS(id, "predictor_raster"))
    )
  )
}


mod_comp_predictor_raster_server <- function(
  id = "comp_predictor_raster",
  model_id
) {
  moduleServer(id, function(input, output, session) {
    predictor_raster <- reactive(predictor_raster_prep(model_id()))
    output$predictor_raster <- leaflet::renderLeaflet({
      predictor_raster() |>
        predictor_raster_map()
    })
  })
}


#' Create a Leaflet Map of Predictor Raster Data
#'
#' @param predictor_raster terra Raster. Predictor information
#'
#' @returns A leaflet map object
#'
#' @export
#' @examplesIf have_data()
#' skip_eg()
#' # predictor_raster_prep("bam_v5_can71") |> predictor_raster_map()

predictor_raster_map <- function(predictor_raster) {
  leaflet::leaflet() |>
    leaflet::addRasterImage(predictor_raster[[1]])
}

#' Prepare Predictor Raster Data
#'
#' @param model_id Character. Model ID
#'
#' @returns terra Raster
#'
#' @export
#' @examplesIf have_data()
#' skip_eg()
#' # predictor_raster_prep("bam_v5_can71")

predictor_raster_prep <- function(model_id) {
  prep_materials("predictor_raster", model_id = model_id)
}
