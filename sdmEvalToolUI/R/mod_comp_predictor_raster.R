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
    use = c("model_id", "deployment_id"),
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
  header = NULL
) {
  sdm_card(
    min_height = height,
    class = "p-0 sub-card",
    header,
    card_body(
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


mod_comp_predictor_raster_server <- function(
  id = "comp_predictor_raster",
  model_id,
  deployment_id
) {
  stopifnot(is.reactive(deployment_id))
  stopifnot(is.reactive(model_id))

  moduleServer(id, function(input, output, session) {
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
        isolate(input$predictor),
        subunits()
      )
    })

    output$map <- leaflet::renderLeaflet({
      map()
    })

    observe({
      leaflet::leafletProxy("map", session = session) |>
        leaflet::clearControls() |>
        predictor_raster_layer(
          predictor_raster(),
          layers = input$predictor
        )
    })
  })
}


#' Create a Leaflet Map of Predictor Raster Data
#'
#' @param predictor_raster terra Raster. Predictor information.
#' @param layers Layers.
#' @param subunits Spatial Data frame. Deployment subunits.
#'
#' @returns A leaflet map object
#'
#' @export
#' @examplesIf have_data()
#' predictor_raster_prep("bam_v5_can71") |>
#'   predictor_raster_map(layers = "year")

predictor_raster_map <- function(
  predictor_raster,
  layers = NULL,
  subunits = NULL
) {
  base_map() |>
    predictor_raster_layer(
      raster = predictor_raster,
      layers = layers,
      subunits = subunits
    )
}


predictor_raster_layer <- function(
  map,
  raster = NULL,
  layers = NULL,
  subunits = NULL
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

  # Show selections for multiple layers
  if (length(layers) > 1) {
    g <- layers
  } else {
    g <- character(0)
  }

  map <- add_subunits(map, subunits)

  map <- add_control(map, groups = g)

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
