#' Test the Deployment Subunits Component
#'
#' @param ... Arguments passed to other functions.
#'
#' @returns A Shiny app object
#'
#' @export
#' @examplesIf have_data()
#' test_comp_deployment_subunits()

test_comp_deployment_subunits <- function(...) {
  test_comp(
    "mod_comp_deployment_subunits",
    ...
  )
}

#' Deployment Subunits Component UI
#'
#' @param id Shiny module ID
#' @param header Header
#'
#' @returns Shiny UI
#'
#' @export
#' @examples
#' mod_comp_deployment_subunits_ui()

mod_comp_deployment_subunits_ui <- function(
  id = "comp_summary",
  header = "Comfort zones"
) {
  layout_columns(
    gap = 0, # No gap between top and bottom
    col_widths = 12, # One column
    row_heights = c("60%", "40%"), # More map than selection area(
    sdm_card(
      class = "sub-card",
      sdm_card_header(header),
      card_body(
        class = "p-0",
        sdm_spinner(leaflet::leafletOutput(NS(id, "map")))
      )
    ),
    sdm_card(
      class = "sub-card",
      card_body(
        mod_utils_map_selections_ui(
          NS(id, "select"),
          spatial_type = "areas"
        )
      )
    )
  )
}

#' Deployment Subunits component Server
#'
#' @param id Module ID
#' @param deployment_id Deployment ID
#' @param model_id Model ID
#' @param species_id Species ID
#' @param spatial_selection Spatial selection
#' @param spatial_ids Spatial IDs
#'
#' @returns Module server function
#'
#' @export
mod_comp_deployment_subunits_server <- function(
  id = "comp_summary",
  deployment_id,
  model_id,
  species_id,
  spatial_selection,
  spatial_ids
) {
  moduleServer(id, function(input, output, session) {
    # Setup -------------------------------------------------------------
    ns <- session$ns

    # Map --------------------------------------------------------------------

    # Subunits only
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
      deployment_subunits_map(
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

#' Create a Leaflet Map of Subunits
#'
#' @param subunits Spatial Data frame. Deployment subunits.
#' @param ns Namespace.
#'
#' @returns A leaflet map object
#'
#' @export
#' @examplesIf have_data()
#' s <- deployment_subunits_prep("deployment1")
#' deployment_subunits_map(s)

deployment_subunits_map <- function(
  subunits,
  ns = identity
) {
  base_map(ns = ns) |>
    add_subunits(subunits) |>
    add_control()
}
