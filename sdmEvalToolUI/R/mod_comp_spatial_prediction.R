#' Test the Spatial Prediction Component
#'
#' @param ... Arguments passed to other functions.
#'
#' @returns A Shiny app object
#'
#' @export
#' @examplesIf have_data()
#' test_comp_spatial_prediction()

test_comp_spatial_prediction <- function(...) {
  test_comp("mod_comp_spatial_prediction", ...)
}

#' Spatial Prediction Component UI
#'
#' @param id Shiny module ID
#' @param header Header
#'
#' @returns Shiny UI
#'
#' @export
#' @examples
#' mod_comp_spatial_prediction_ui()

mod_comp_spatial_prediction_ui <- function(
  id = "comp_spatial_prediction",
  header = NULL
) {
  tagList(
    sdm_card(
      class = "p-0 sub-card",
      min_height = "60%",
      header,
      sdm_spinner(leaflet::leafletOutput(NS(id, "map")))
    ),
    sdm_card(
      class = "p-0 sub-card",
      min_height = "40%",
      mod_utils_map_selections_ui(
        NS(id, "select"),
        spatial_type = "areas"
      )
    )
  )
}


mod_comp_spatial_prediction_server <- function(
  id = "comp_spatial_prediction",
  deployment_id,
  model_id,
  species_id,
  spatial_selection,
  spatial_ids
) {
  stopifnot(is.reactive(deployment_id))
  stopifnot(is.reactive(model_id))
  stopifnot(is.reactive(species_id))

  moduleServer(id, function(input, output, session) {
    # Map --------------------------------------------------------------------
    spatial_prediction <- reactive({
      spatial_prediction_prep(model_id(), species_id())
    })

    subunits <- reactive({
      deployment_subunits_prep(deployment_id())
    })

    output$map <- leaflet::renderLeaflet({
      validate_ids(
        deployment_id = deployment_id(),
        model_id = model_id(),
        species_id = species_id()
      )
      spatial_prediction_map(
        spatial_prediction(),
        subunits(),
        ns = session$ns
      )
    })

    # Process and show map selections ---------------------------------------
    interactions <- map_reactive_vals(input, "map")

    mod_utils_map_selections_server(
      "select",
      data = subunits,
      spatial_selection,
      interactions,
      spatial_type = "areas",
      parent_session = session
    )

    # Return ---------------------
    observe({
      spatial_ids(subunits()$id)
    })
  })
}


#' Create a Leaflet Map of Spatial Prediction Data
#'
#' @param spatial_prediction terra Raster. Spatial predictions
#' @param subunits Spatial Data frame. Deployment subunits.
#' @param ns Namespace.
#'
#' @returns A leaflet map object
#'
#' @export
#' @examplesIf have_data()
#' p <- spatial_prediction_prep(model_id = "bam_v5_can71", species_id = "BBWO")
#' s <- deployment_subunits_prep("deployment1")
#' spatial_prediction_map(p)
#' spatial_prediction_map(p, s)

spatial_prediction_map <- function(
  spatial_prediction,
  subunits = NULL,
  ns = identity
) {
  base_map(ns = ns) |>
    add_raster(
      spatial_prediction,
      layer = "mean",
      name = "Distribution",
      palette = "Spectral",
      min_0 = TRUE
    ) |>
    add_raster(
      spatial_prediction,
      layer = "cv",
      name = "Uncertainty",
      palette = "viridis",
      min_0 = TRUE
    ) |>
    add_subunits(subunits) |>
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
