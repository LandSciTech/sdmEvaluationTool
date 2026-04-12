#' Test the Template Spatial Component
#'
#' @param ... Arguments passed to other functions.
#'
#' @returns A Shiny app object
#'
#' @export
#' @examplesIf have_data()
#' test_comp_template_spatial()

test_comp_template_spatial <- function(...) {
  test_comp("mod_comp_template_spatial", ...)
}

#' Template Spatial Component UI
#'
#' @param id Character. Shiny module ID
#' @param header Header
#'
#' @returns Shiny UI
#'
#' @export
#' @examples
#' mod_comp_template_spatial_ui()

mod_comp_template_spatial_ui <- function(
  id = "comp_template_spatial",
  header = "Template Spatial"
) {
  # TEMPLATE: Arrange Map and Map selections output, require both if
  # making spatial selections
  layout_columns(
    gap = 0, # No gap between top and bottom
    col_widths = 12, # One column
    row_heights = c("60%", "40%"), # More map than selection area
    sdm_card(
      class = "sub-card",
      sdm_card_header(header, uiOutput(NS(id, "tooltip"))),
      card_body(
        class = "p-0", # Good for maps where we want it to fill the card
        sdm_spinner(leaflet::leafletOutput(NS(id, "map")))
      )
    ),
    sdm_card(
      class = "sub-card",
      mod_utils_map_selections_ui(
        NS(id, "select"),
        spatial_type = "areas" # "points" or "areas" depending on what is being selected
      )
    )
  )
}


#' Template Spatial component Server
#'
#' @param id Module ID
#' @param deployment_id Deployment ID. Required for subunits.
#' @param model_id Model ID
#' @param species_id Species ID
#' @param spatial_selection Spatial selection. Required for spatial evaluations.
#' @param spatial_ids Spatial IDs. Required for spatial evaluations.
#'
#' @returns Module server function
#'
#' @export

mod_comp_template_spatial_server <- function(
  id = "comp_template_spatial",
  deployment_id, # Require deployment_id for subunits on maps
  model_id,
  species_id,
  spatial_selection,
  spatial_ids # ReactiveVal to be update
) {
  stopifnot(is.reactive(deployment_id))
  stopifnot(is.reactive(model_id))
  stopifnot(is.reactive(species_id))

  moduleServer(id, function(input, output, session) {
    # Setup -------------------------------------------------------------
    ns <- session$ns

    # Tooltip -------------------------------------------------------
    output$tooltip <- renderUI({
      # If the component exists in the materials table, this will work:
      # p <- prep_material_settings("template_spatial", model_id(), species_id())
      # tt_material_settings(p)
      # Otherwise if the material settings have already been attached to the
      # materials reactive, use just:
      # tt_material_settings(material())  #see `mod_comp_template_server()`
      "Spatial template legend" # delete this line if for real
    })

    # Map --------------------------------------------------------------------
    # EXAMPLE: Prepare units to be displayed on map
    map_units <- reactive({
      template_spatial_prep(model_id(), species_id())
    })

    # Prepare subunits for selections
    subunits <- reactive({
      deployment_subunits_prep(deployment_id())
    })

    # Output leaflet map
    output$map <- leaflet::renderLeaflet({
      # Create sensible messages if missing
      validate_ids(
        deployment_id = deployment_id(),
        model_id = model_id(),
        species_id = species_id()
      )
      # Create map
      template_spatial_map(
        map_units(),
        subunits(),
        ns = session$ns
      )
    })

    # Process and show map selections ---------------------------------------
    # TEMPLATE: This will be the same for each spatial component
    #  Only things that change is the spatial_type, 'points' or 'areas'
    interactions <- map_reactive_vals(input, "map")

    mod_utils_map_selections_server(
      "select",
      data = subunits,
      spatial_selection, # reactiveVal which holds the current selection
      interactions, # reactiveVal which notes clicks etc.
      spatial_type = "areas",
      parent_session = session
    )

    # Return ---------------------
    observe({
      # TEMPLATE:  Update the reactiveVal with available spatial ids,
      # used by evaluations module to offer map unit ids in the selectors.
      # Should not change unless NOT selecting by subunits.
      spatial_ids(subunits()$id)
    })
  })
}

#' Create a Leaflet Map of Template Spatial Data
#'
#' @param template_spatial terra Raster. Template spatial data
#' @param subunits Spatial Data frame. Deployment subunits.
#' @param ns Namespace.
#'
#' @returns A leaflet map object
#'
#' @export
#' @examplesIf have_data()
#' p <- template_spatial_prep(model_id = "bam_v5_can71", species_id = "BBWO")
#' s <- deployment_subunits_prep("deployment1")
#' template_spatial_map(p)
#' template_spatial_map(p, s)

template_spatial_map <- function(
  template_spatial,
  subunits = NULL,
  ns = identity
) {
  base_map(ns = ns) |>
    add_raster(
      template_spatial,
      layer = "mean",
      name = "Distribution",
      palette = "Spectral",
      min_0 = TRUE
    ) |>
    add_raster(
      template_spatial,
      layer = "cv",
      name = "Uncertainty",
      palette = "viridis",
      min_0 = TRUE
    ) |>
    add_subunits(subunits) |>
    add_control(groups = c("Distribution", "Uncertainty"))
}

#' Prepare Template Spatial Data
#'
#' @param model_id Character. Model ID
#' @param species_id Character. Model ID
#'
#' @returns terra Raster
#'
#' @export
#' @examplesIf have_data()
#' template_spatial_prep(model_id = "bam_v5_can71", species_id = "BBWO")

template_spatial_prep <- function(model_id, species_id) {
  # TEMPLATE: Normally would use `prep_materials` function to prepare the
  # component materials, see the following example for the "spatial_prediction"
  # component:

  # prep_materials(
  #   component_id = "spatial_prediction",
  #   model_id = model_id,
  #   species_id = species_id
  # )

  # TEMPLATE: For this example, we'll use dummy data
  # Create example raster for northern Ontario
  # Extent roughly covering northern Ontario (longitude, latitude)
  r <- test_raster()

  # Create mean layer with some spatial pattern
  mean_layer <- r
  terra::values(mean_layer) <- stats::runif(
    terra::ncell(mean_layer),
    min = 0,
    max = 1
  )
  names(mean_layer) <- "mean"

  # Create sd layer
  sd_layer <- r
  terra::values(sd_layer) <- stats::runif(
    terra::ncell(sd_layer),
    min = 0,
    max = 0.3
  )
  names(sd_layer) <- "sd"

  # Combine layers
  rast <- c(mean_layer, sd_layer)

  rast
}
