#' Test the Predictor Raster Component
#'
#' @param ... Other arguments.
#'
#' @returns A Shiny app object
#'
#' @export
#' @examplesIf have_data()
#' test_comp_predictor_raster()

test_comp_predictor_raster <- function(...) {
  test_comp(
    "mod_comp_predictor_raster",
    use = c("parent_id", "model_id", "deployment_id", "map_views"),
    ...
  )
}

#' Predictor Raster Component UI
#'
#' @param id Shiny module ID
#' @param height Height
#' @param header Header
#'
#' @returns Shiny UI
#'
#' @export
#' @examples
#' mod_comp_predictor_raster_ui()
mod_comp_predictor_raster_ui <- function(
  id = "comp_predictor_raster",
  height = NULL,
  header = "Predictor Raster"
) {
  sdm_card(
    min_height = height,
    class = "sub-card",
    sdm_card_header(header, uiOutput(NS(id, "tooltip"))),
    card_body(
      class = "p-0",
      min_height = 400,
      as_fill_carrier(
        div(
          style = "position: relative",
          sdm_spinner(leaflet::leafletOutput(
            NS(id, "map"),
            height = "100%"
          )),
          absolutePanel(
            uiOutput(NS(id, "ui_selectors")),
            top = 10,
            left = 10,
            width = 300,
            style = "padding-left:50px"
          ),
        )
      )
    )
  )
}

#' Predictor Raster component Server
#'
#' @param id Module ID
#' @param parent_id Parent tab ID (used to identify which tab is active)
#' @param deployment_id Deployment ID. Required for subunits.
#' @param model_id Model ID
#' @param map_views List. List of reactiveVals `active_tab`, `set_by` and
#'   `view` (list with zoom and lat/lon).
#'
#' @returns Module server function
#'
#' @export

mod_comp_predictor_raster_server <- function(
  id = "comp_predictor_raster",
  parent_id,
  deployment_id,
  model_id,
  map_views
) {
  stopifnot(is.reactive(deployment_id))
  stopifnot(is.reactive(model_id))
  purrr::walk(map_views, \(v) stopifnot(is.reactive(v)))

  moduleServer(id, function(input, output, session) {
    # Tooltip -------------------------------------------------------
    output$tooltip <- renderUI({
      p <- prep_material_settings("predictor_raster", model_id())
      tt_material_settings(p)
    })

    # Setup -------------------------------------------------------------
    ns <- session$ns

    # Use reactiveVal to catch first time the input predictor is ready to ensure
    # the map doesn't render until it has that initial input.
    input_ready <- reactiveVal(FALSE)
    observe(
      if (!is.null(input$predictor) && !input_ready()) input_ready(TRUE)
    )

    # Map ----------------------------------------------------------
    predictor_raster <- reactive({
      predictor_raster_prep(model_id())
    })

    # Switch among map layers
    output$ui_selectors <- renderUI({
      selectInput(
        ns("predictor"),
        label = "Predictor",
        choices = names(predictor_raster())
      )
    })

    subunits <- reactive({
      deployment_subunits_prep(deployment_id())
    })

    map <- reactive({
      validate_ids(model_id = model_id)
      req(input_ready())
      predictor_raster_map(
        predictor_raster(),
        layers = isolate(input$predictor),
        subunits = subunits()
      )
    })

    output$map <- leaflet::renderLeaflet({
      map() |>
        set_view(map_views, tab = parent_id)
    }) |>
      bindEvent(map())

    observe({
      leaflet::leafletProxy("map", session = session) |>
        leaflet::clearControls() |>
        predictor_raster_layer(
          predictor_raster(),
          layers = input$predictor
        )
    })

    # Synchronize map views ------------------------------------------------
    mod_utils_map_sync_server(
      "sync",
      parent_id,
      this_view = map_view(input, "map"),
      map_views,
      parent_session = session
    )
  })
}


#' Create a Leaflet Map of Predictor Raster Data
#'
#' @param predictor_raster terra SpatRaster. Predictor information.
#' @param layers Character vector. Layers in SpatRaster to plot.
#' @param subunits Spatial Data frame. Deployment subunits.
#'
#' @returns A leaflet map object
#'
#' @export
#' @examplesIf have_data()
#' predictor_raster_prep("bam_v5_can71") |>
#'   predictor_raster_map(
#'     layers = "AHM_1km", # Must be a layer in prepared raster
#'     subunits = deployment_subunits_prep("deployment1")
#'   )

predictor_raster_map <- function(
  predictor_raster,
  layers = NULL,
  subunits = NULL
) {
  map <- base_map() |>
    predictor_raster_layer(
      raster = predictor_raster,
      layers = layers
    ) |>
    add_subunits(subunits)

  # Add in layer controls at map creation level because `add_control()` can't
  # use leafletProxy

  # Show selections for multiple layers only
  if (length(layers) > 1) {
    g <- layers
  } else {
    g <- character(0)
  }

  map <- add_control(map, groups = g)

  map
}


#' Add a Prediction Raster Layer to an existing map
#'
#' @param map Leaflet map.
#' @param raster SpatRaster. Raster from which to get `layers` to plot.
#' @param layers Character vector. Layers in SpatRaster to plot.
#'
#' @returns Leaflet map
#'
#' @export
#'
#' @examplesIf have_data()
#' r <- predictor_raster_prep("bam_v5_can71")
#' base_map() |>
#'   predictor_raster_layer(r, "mean")

predictor_raster_layer <- function(
  map,
  raster = NULL,
  layers = NULL
) {
  if (is.null(layers)) {
    return(map)
  }

  # Use map data if no raster
  raster <- raster %||% leaflet::getMapData(map)

  for (l in layers) {
    map <- add_raster(
      map,
      raster,
      layer = l,
      name = l,
      palette = "viridis",
      opacity = 1,
      min_0 = FALSE
    )
  }

  map
}

#' Prepare Predictor Raster Data
#'
#' @param model_id Character. Model ID
#'
#' @returns terra Raster
#'
#' @export
#' @examplesIf have_data()
#' predictor_raster_prep("bam_v5_can71")

predictor_raster_prep <- function(model_id) {
  prep_materials("predictor_raster", model_id = model_id)
}
