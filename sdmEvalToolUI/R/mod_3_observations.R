#' Title
#'
#' @param id
#' @param title
#'
#' @returns 
#'
#' @export
#' @examples
mod_observations_ui <- function(id, title = "Observations") {
  nav_panel(
    title,
    h2(textOutput(NS(id, "title"))),
    leaflet::leafletOutput(NS(id, "observations"))
  )
}

#' Title
#'
#' @param id
#'
#' @returns
#'
#' @export
#' @examples
mod_observations_server <- function(id, mod, sp, tbl_materials) {
  moduleServer(id, function(input, output, session) {
    output$title <- renderText(paste0("Observations for Model: ", mod(), " and species ", sp()))

    # TODO: Options for when materials don't exist

    obs <- reactive({
      req(sp(), mod())
      sdmEvalToolCore:::make_target_path(
        paste0("materials/{mod}/species/{sp}/observations.gpkg"),
        data = list(mod = mod(), sp = sp())
      ) |>
        sdmEvalToolCore:::read_file()
    })

    output$observations <- leaflet::renderLeaflet({
      obs() |>
        sf::st_transform(crs = 4326) |>
        leaflet::leaflet() |>
        leaflet::addTiles() |>
        leaflet::addCircles()
    })

    make_target_path <- function(path, data=list(), base = NULL) {
      if (is.null(base))
          base <- sdmevaltool_options()$base
      path <- glue::glue_data(.x = data, path)
      file.path(base, path)
  }
  # make_target_path("bam_v5/oven/observations.parquet")
  # make_target_path("{model}/{species}/observations.parquet", list(model = "bam_v5", species = "oven"))
  # make_target_path("{model}/{species}/observations.parquet", list(model = "bam_v5", species = "oven"), ".")
  


  })
}

