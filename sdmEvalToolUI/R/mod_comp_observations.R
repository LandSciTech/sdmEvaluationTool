#' Title
#'
#' @returns
#'
#' @export
#' @examples
#' test_comp_observations()
test_comp_observations <- function() {
  ui <- mod_page_observations_ui()

  server <- function(input, output, session) {
    mod_page_observations_server(
      mod = reactive("bam_v5_can71"),
      sp = reactive("BBWO")
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
mod_comp_observations_ui <- function(id = "comp_observations") {
  tagList(
    div(
      style = "position: relative;",
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

    obs <- reactive(obs_prep(mod(), sp()))

    output$ui_selectors <- renderUI({
      tagList(
        selectInput("year", label = "Year", choices = sort(unique(obs()$year))),
        selectInput(
          "method",
          label = "Method",
          choices = sort(unique(obs()$method))
        )
      )
    })

    output$observations <- leaflet::renderLeaflet(obs_map(obs()))
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
#' obs_prep(mod = "bam_v5_can71", sp = "BBWO") |>
#'   obs_map()

obs_map <- function(obs) {
  pal <- leaflet::colorFactor("darkgreen", obs$detections)
  obs |>
    dplyr::filter(!is.na(detections)) |>
    sf::st_transform(crs = 4326) |>
    leaflet::leaflet() |>
    leaflet::addTiles() |>
    leaflet::addCircleMarkers(color = ~ pal(detections), popup = ~popup)
}

#' Title
#'
#' @param obs
#'
#' @returns
#'
#' @export
#' @examples
#' obs_prep(mod = "bam_v5_can71", sp = "BBWO")

obs_prep <- function(mod, sp) {
  req(sp, mod)
  sdmEvalToolCore:::make_target_path(
    paste0("materials/{mod}/species/{sp}/observations.gpkg"),
    data = list(mod = mod, sp = sp)
  ) |>
    sdmEvalToolCore:::read_file() |>
    dplyr::mutate(
      year = lubridate::year(.data$time),
      detections = dplyr::na_if(.data$status > 0, 0),
      # fmt: skip
      popup = paste0(
          "<strong>Method:</strong> ", .data$method, "<br>",
          "<strong>Time:</strong> ", .data$time, "<br>",
          "<strong>Status:</strong> ", .data$status
        )
    )
}
