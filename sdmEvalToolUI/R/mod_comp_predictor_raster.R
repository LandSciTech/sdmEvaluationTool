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
      uiOutput(NS(id, "ui_selectors")),
      sdm_spinner(leaflet::leafletOutput(NS(id, "map")))
    )
  )
}


mod_comp_predictor_raster_server <- function(
  id = "comp_predictor_raster",
  model_id
) {
  moduleServer(id, function(input, output, session) {
    # Setup -------------------------------------------------------------

    # Use reactiveVal to catch first time the input predictor is ready to ensure
    # the map doesn't render until it has that initial input.
    input_ready <- reactiveVal(FALSE)
    observe(if (!is.null(input$predictor) && !input_ready()) input_ready(TRUE))

    # Map ----------------------------------------------------------
    predictor_raster <- reactive({
      predictor_raster_prep(model_id())
    })

    # Switch among map layers
    output$ui_selectors <- renderUI({
      tagList(
        div(
          style = "display:grid; grid-template-columns: 200px 200px; gap: 10px; padding-bottom:10px;",
          selectInput(
            session$ns("predictor"),
            label = "Predictor Displayed",
            choices = names(predictor_raster())
          )
        )
      )
    })

    map <- reactive({
      req(input_ready())
      predictor_raster_map(predictor_raster(), isolate(input$predictor))
    })

    output$map <- leaflet::renderLeaflet({
      map()
    })

    observe({
      leaflet::leafletProxy("map", session = session) |>
        leaflet::clearControls() |>
        predictor_raster_layer(predictor_raster(), layer = input$predictor)
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
#' predictor_raster_prep("bam_v5_can71") |>
#'   predictor_raster_map(layers = "year")

predictor_raster_map <- function(predictor_raster, layers = NULL) {
  map <- base_map()
  if (!is.null(layers)) {
    map <- predictor_raster_layer(map, predictor_raster, layers)
  }
  map
}


predictor_raster_layer <- function(map, predictor_raster, layers) {
  for (l in layers) {
    map <- add_raster(
      map,
      predictor_raster,
      layer = l,
      name = l,
      palette = "viridis",
      opacity = 1
    )
  }

  # Show selections for multiple layers
  if (length(layers) > 1) {
    g <- layers
  } else {
    g <- character(0)
  }

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
  validate_ids(model_id = model_id)
  prep_materials("predictor_raster", model_id = model_id)
}
