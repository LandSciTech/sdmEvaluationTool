#' Test the Observations Component
#'
#' @returns A Shiny app object
#'
#' @export
#' @examplesIf have_data()
#' test_comp_observations()

test_comp_observations <- function() {
  ui <- mod_comp_observations_ui()

  server <- function(input, output, session) {
    show_spatial_ids <- reactive(NULL)
    show_clicked <- reactiveVal(NULL)
    spatial_ids <- reactiveVal(NULL)

    mod_comp_observations_server(
      deployment_id = reactive("deployment1"),
      model_id = reactive("bam_v5_can71"),
      species_id = reactive("BBWO"),
      spatial_ids = spatial_ids,
      spatial_selection = list(
        show_clicked = show_clicked,
        show_spatial_ids = show_spatial_ids
      )
    )
  }

  shiny::shinyApp(ui, server, options = list(port = 8080))
}

#' Observations Component UI
#'
#' @param id Character. Shiny module ID
#'
#' @returns Shiny UI
#'
#' @export
#' @examples
#' mod_comp_observations_ui()

mod_comp_observations_ui <- function(id = "comp_observations") {
  tagList(
    div(
      style = "position: relative;",
      leaflet::leafletOutput(NS(id, "map")),
      absolutePanel(uiOutput(NS(id, "ui_selectors")), top = 10, right = 10)
    ),
    mod_utils_map_selections_ui(NS(id, "select"), spatial_type = "points")
  )
}


#' Observations component Server
#'
#' @param id
#' @param deployment_id
#' @param model_id
#' @param species_id
#' @param spatial_selection
#' @param spatial_ids
#'
#' @returns
#'
#' @export
#' @examples
mod_comp_observations_server <- function(
  id = "comp_observations",
  deployment_id,
  model_id,
  species_id,
  spatial_selection,
  spatial_ids # ReactiveVal to be update
) {
  stopifnot(is.reactive(deployment_id))
  stopifnot(is.reactive(model_id))
  stopifnot(is.reactive(species_id))

  moduleServer(id, function(input, output, session) {
    #TODO:  Display non-detections (status == 0) detections (status > 0) in
    # different colors. Show detections by default (green), allow an option to turn
    # on non-detections (grey). Use circle markers in Leaflet.
    # We can use unique(method) and year of survey as dropdown filters.
    # Method, time, status should be part of popup message on click.

    # TODO: Options for when materials don't exist

    # Map -------------------------------------------------------------------
    obs <- reactive(obs_prep(model_id(), species_id()))

    subunits <- reactive({
      deployment_subunits_prep(deployment_id())
    })

    # Filter observations on the map
    output$ui_selectors <- renderUI({
      tagList(
        selectInput(
          "year",
          label = "Year",
          choices = sort(unique(obs()$year))
        ),
        selectInput(
          "method",
          label = "Method",
          choices = sort(unique(obs()$method))
        )
      )
    })

    output$map <- leaflet::renderLeaflet(obs_map(
      obs(),
      subunits(),
      ns = session$ns
    ))

    # Process and show map selections ---------------------------------------
    interactions <- map_reactive_vals(input, "map")

    mod_utils_map_selections_server(
      "select",
      data = obs,
      spatial_selection = spatial_selection,
      interactions = interactions,
      spatial_type = "points",
      parent_session = session
    )

    # Return ---------------------
    observe(spatial_ids(obs()$id))

    spatial_ids
  })
}


#' Create a Leaflet Map of Observation Data
#'
#' @param obs sf data frame. Observations
#'
#' @returns A leaflet map object
#'
#' @export
#' @examplesIf have_data()
#' o <- obs_prep(model_id = "bam_v5_can71", species_id = "BBWO")
#' s <- deployment_subunits_prep("deployment1")
#' obs_map(o, s)

obs_map <- function(obs, subunits = NULL, ns = identity) {
  base_map(ns = ns) |>
    # Subunits first because selecting by points
    add_subunits(subunits) |>
    add_markers(data = obs) |>
    add_control()
}

#' Prepare Observation Data
#'
#' @param model_id Character. Model ID
#' @param species_id Character. Species ID
#'
#' @returns Spatial data frame
#'
#' @export
#' @examplesIf have_data()
#' obs_prep(model_id = "bam_v5_can71", species_id = "BBWO")

obs_prep <- function(model_id, species_id) {
  prep_materials(
    "observations",
    model_id = model_id,
    species_id = species_id
  ) |>
    dplyr::mutate(
      year = as.numeric(stringr::str_extract(.data$time, "^\\d{4}")),
      detections = dplyr::na_if(.data$status > 0, 0),
      # fmt: skip
      popup = paste0(
          "<strong>Method:</strong> ", .data$method, "<br>",
          "<strong>Time:</strong> ", .data$time, "<br>",
          "<strong>Status:</strong> ", .data$status
        )
    ) |>
    dplyr::filter(!is.na(.data$detections)) |>
    # For reasons, the id must be a character, otherwise can't be removed
    dplyr::mutate(id = paste0("id", dplyr::row_number())) |>
    sf::st_transform(crs = 4326)
}
