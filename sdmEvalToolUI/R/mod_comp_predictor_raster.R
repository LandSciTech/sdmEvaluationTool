#' Title
#'
#' @returns
#'
#' @export
#' @examples
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

#' Title
#'
#' @param id
#' @param title
#'
#' @returns
#'
#' @export
#' @examples
mod_comp_predictor_raster_ui <- function(id = "comp_predictor_raster") {
  tagList(
    tagList(
      leaflet::leafletOutput(NS(id, "predictor_raster"))
    )
  )
}


mod_comp_predictor_raster_server <- function(
  id = "comp_predictor_raster",
  mod
) {
  moduleServer(id, function(input, output, session) {
    predictor_raster <- reactive(predictor_raster_prep(model_id()))
    output$predictor_raster <- leaflet::renderLeaflet({
      predictor_raster() |>
        predictor_raster_map()
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
#' predictor_raster_prep(model_id = "bam_v5_can71") |>
#'   predictor_raster_map()

predictor_raster_map <- function(predictor_raster) {
  leaflet::leaflet() |>
    leaflet::addRasterImage(predictor_raster[[1]])
}

#' Title
#'
#' @param obs
#'
#' @returns
#'
#' @export
#' @examples
#' predictor_raster_prep(model_id = "bam_v5_can71")

predictor_raster_prep <- function(mod) {
  prep_files("predictor_raster", model_id = model_id)
}
