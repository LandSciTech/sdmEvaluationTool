#' Title
#'
#' @param id
#' @param title
#'
#' @returns
#'
#' @export
#' @examples
mod_comp_observations_ui <- function(id = "comp_observations") {
  tagList(
    div(
      leaflet::leafletOutput(NS(id, "observations")),
      absolutePanel(uiOutput(NS(id, "ui_selectors")), top = 10, right = 10)
    )
  )
}


mod_comp_observations_server <- function(id = "comp_observations", sp, mod) {
  moduleServer(id, function(input, output, session) {
    #TODO:  Display non-detections (status == 0) detections (status > 0) in
    # different colors. Show detections by default (green), allow an option to turn
    # on non-detections (grey). Use circle markers in Leaflet.
    # We can use unique(method) and year of survey as dropdown filters.
    # Method, time, status should be part of popup message on click.

    # TODO: Options for when materials don't exist

    obs <- reactive({
      req(sp(), mod())
      sdmEvalToolCore:::make_target_path(
        paste0("materials/{mod}/species/{sp}/observations.gpkg"),
        data = list(mod = mod(), sp = sp())
      ) |>
        sdmEvalToolCore:::read_file() |>
        dplyr::mutate(year = lubridate::year(time))
    })

    output$ui_selectors <- renderUI({
      tagList(
        selectInput("year", label = "Year", choices = unique(obs()$year)),
        selectInput("method", label = "Method", choices = unique(obs()$method))
      )
    })

    output$observations <- leaflet::renderLeaflet({
      obs() |>
        sf::st_transform(crs = 4326) |>
        leaflet::leaflet() |>
        leaflet::addTiles() |>
        leaflet::addCircles()
    })
  })
}
