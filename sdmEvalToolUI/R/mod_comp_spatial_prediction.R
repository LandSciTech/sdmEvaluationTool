#' Test the Spatial Prediction Component
#'
#' @returns A Shiny app object
#'
#' @export
#' @examplesIf have_data()
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

#' Spatial Prediction Component UI
#'
#' @param id Shiny module ID
#'
#' @returns Shiny UI
#'
#' @export
#' @examples
#' mod_comp_spatial_prediction_ui()

mod_comp_spatial_prediction_ui <- function(id = "comp_spatial_prediction") {
  tagList(
    div(
      style = "position: relative;",
      leaflet::leafletOutput(NS(id, "spatial_prediction")),
      absolutePanel(
        uiOutput(NS(id, "ui_selectors")),
        top = 10,
        right = 10
      )
    )
  )
}


mod_comp_spatial_prediction_server <- function(
  id = "comp_spatial_prediction",
  deployment_id,
  model_id,
  species_id
) {
  stopifnot(is.reactive(model_id))
  stopifnot(is.reactive(species_id))
  # stopifnot(is.reactive(questions))
  # stopifnot(is.reactive(show_clicked)) # reactiveVal
  # stopifnot(is.reactive(show_spatial_ids))

  moduleServer(id, function(input, output, session) {
    spatial_prediction <- reactive({
      spatial_prediction_prep(model_id(), species_id())
    })

    output$spatial_prediction <- leaflet::renderLeaflet({
      spatial_prediction_map(
        spatial_prediction(),
        deployment_id = deployment_id()
      )
    })
  })
}


#' Create a Leaflet Map of Spatial Prediction Data
#'
#' @param spatial_prediction terra Raster. Spatial predictions
#' @param deployment_subunits Deployment subunits.
#'
#' @returns A leaflet map object
#'
#' @export
#' @examplesIf have_data()
#' p <- spatial_prediction_prep(model_id = "bam_v5_can71", species_id = "BBWO")
#' spatial_prediction_map(p)
#' spatial_prediction_map(p, "deployment1")

spatial_prediction_map <- function(
  spatial_prediction,
  deployment_id = NULL
) {
  base_map() |>
    add_raster(
      spatial_prediction,
      layer = "mean",
      name = "Distribution",
      palette = "Spectral"
    ) |>
    add_raster(
      spatial_prediction,
      layer = "cv",
      name = "Uncertainty",
      palette = "viridis"
    ) |>
    add_subunits(deployment_id) |>
    add_control(groups = c("Distribution", "Uncertainty"))
}

#' Prepare Spatial Prediction Data
#'
#' @param model_id Character. Model ID
#' @param species_id Character. Model ID
#'
#' @returns terra Raster
#'
#' @export
#' @examplesIf have_data()
#' spatial_prediction_prep(model_id = "bam_v5_can71", species_id = "BBWO")

spatial_prediction_prep <- function(model_id, species_id) {
  prep_materials(
    "spatial_prediction",
    model_id = model_id,
    species_id = species_id
  )
}
