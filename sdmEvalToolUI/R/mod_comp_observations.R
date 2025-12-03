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
    show_clicked <- reactiveVal(NULL)
    mod_comp_observations_server(
      model_id = reactive("bam_v5_can71"),
      species_id = reactive("BBWO"),
      spatial_selection = list(show_clicked, show_spatial_ids = reactive(NULL))
    )
  }

  shiny::shinyApp(ui, server, options = list(port = 8080))
}

#' Observations Component UI
#'
#' @param id Shiny module ID
#'
#' @returns Shiny UI
#'
#' @export
#' @examples
#' mod_comp_observations_ui()

mod_comp_observations_ui <- function(id = "comp_observations") {
  tagList(
    # From: https://github.com/trafficonese/leaflet.extras/issues/96
    tags$script(HTML(
      "
      Shiny.addCustomMessageHandler(
        'removeleaflet',
        function(x){
          console.log('deleting',x)
          // get leaflet map
          var map = HTMLWidgets.find('#' + x.elid).getMap();
          // remove
          map.removeLayer(map._layers[x.layerid])
        })
      "
    )),
    div(
      style = "position: relative;",
      leaflet::leafletOutput(NS(id, "map")),
      card(
        layout_columns(
          col_widths = c(8, 4),
          reactable::reactableOutput(NS(id, "tbl_selected")),
          div(
            strong("Copy selected point IDs"),
            copy_output(NS(id, "selected"))
          )
        )
      ),
      absolutePanel(uiOutput(NS(id, "ui_selectors")), top = 10, right = 10)
    )
  )
}


mod_comp_observations_server <- function(
  id = "comp_observations",
  model_id,
  species_id,
  spatial_selection,
  spatial_ids
) {
  stopifnot(is.reactive(model_id))
  stopifnot(is.reactive(species_id))

  expand_list(spatial_selection) # Leads to --->
  stopifnot(is.reactive(show_clicked)) # reactiveVal
  stopifnot(is.reactive(show_spatial_ids))

  moduleServer(id, function(input, output, session) {
    #TODO:  Display non-detections (status == 0) detections (status > 0) in
    # different colors. Show detections by default (green), allow an option to turn
    # on non-detections (grey). Use circle markers in Leaflet.
    # We can use unique(method) and year of survey as dropdown filters.
    # Method, time, status should be part of popup message on click.

    # TODO: Options for when materials don't exist

    obs <- reactive(obs_prep(model_id(), species_id()))
    obs_selected <- reactiveVal()
    prev_selected <- reactiveVal()

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

    output$map <- leaflet::renderLeaflet(obs_map(obs()))

    # Highlight selected points --------------------------------------------
    observe({
      # What needs to change?
      unselect <- setdiff(prev_selected(), obs_selected()$id)
      select <- obs_selected()

      if (length(unselect) > 0) {
        leaflet::leafletProxy("map") |>
          leaflet::removeMarker(layerId = unselect) |>
          obs_markers(data = dplyr::filter(obs(), id %in% unselect))
      }
      if (nrow(select) > 0) {
        levels <- unique(select$type)
        d <- dplyr::right_join(obs(), select, by = "id") |>
          dplyr::mutate(type = factor(type, levels = levels))

        leaflet::leafletProxy("map") |>
          leaflet::removeMarker(layerId = unique(select$id)) |>
          selected_markers(data = d)
      }

      # Track the current selection
      isolate(prev_selected(unique(select$id)))
    }) |>
      bindEvent(obs_selected(), ignoreInit = TRUE)

    # Map selections -------------------------------------------
    # Process Drawn Selections
    observe({
      # Store the selections
      poly <- coords_to_poly(input$map_draw_new_feature$geometry)
      s <- obs() |>
        sf::st_transform(4326) |>
        sf::st_filter(poly)
      obs_selected(data.frame(id = s$id, type = "Selected"))

      # Remove the drawn section
      feature_ids(input$map_draw_all_features) |>
        purrr::walk(\(x) {
          session$sendCustomMessage(
            "removeleaflet",
            list(elid = session$ns("map"), layerid = x)
          )
        })
    }) |>
      bindEvent(input$map_draw_stop, ignoreInit = TRUE)

    # Process click selections
    observe({
      id <- input$map_marker_click$id

      if (!"Selected" %in% obs_selected()$type) {
        obs_selected(data.frame(id = id, type = "Selected"))
      } else {
        if (id %in% obs_selected()$id) {
          obs_selected(data.frame(
            id = setdiff(obs_selected()$id, id),
            type = "Selected"
          ))
        } else {
          obs_selected(data.frame(
            id = union(obs_selected()$id, id),
            type = "Selected"
          ))
        }
      }
    }) |>
      bindEvent(input$map_marker_click)

    # Selection Details ---------------------------
    output$tbl_selected <- reactable::renderReactable({
      validate(need(
        nrow(obs_selected()) > 0,
        "No points selected"
      ))

      r <- obs() |>
        dplyr::right_join(obs_selected(), by = "id") |>
        dplyr::relocate(type) |>
        sf::st_drop_geometry() |>
        dplyr::select(-"popup") |>
        reactable::reactable()

      if ("Selected" %in% obs_selected()$type) {
        title <- "Currently selected points"
      } else {
        title <- "Identified points"
      }

      div(h4(title), r)
      r
    })

    output$selected <- renderText({
      req("Selected" %in% obs_selected()$type)
      obs() |>
        dplyr::filter(
          .data$id %in% obs_selected()$id[obs_selected()$type == "Selected"]
        ) |>
        dplyr::pull(.data$id) |>
        paste0(collapse = ",")
    })

    # "Show" selected ids on map --------------------------------------
    observe({
      ids <- show_spatial_ids() |>
        purrr::map(\(i) if (length(i) > 0) data.frame(id = i)) |>
        purrr::list_rbind(names_to = "type")
      obs_selected(ids)
      # ids <- show_spatial_ids() |>
      #   purrr::map(\(i) if (length(i) > 0) data.frame(id = i)) |>
      #   purrr::list_rbind(names_to = "type")

      # d <- dplyr::right_join(obs(), ids, by = "id")

      # leaflet::leafletProxy("map") |>
      #   leaflet::removeMarker(layerId = prev_selected()) |>
      #   obs_markers(data = dplyr::filter(obs(), !id %in% ids$id))
      # if (length(ids) > 0) {
      #   leaflet::leafletProxy("map") |>
      #     selected_markers(data = d, levels = names(show_spatial_ids()))
      # }

      # prev_selected(unlist(ids))
    }) |>
      bindEvent(show_clicked(), ignoreInit = TRUE)

    # Return ---------------------
    observe(spatial_ids(obs()$id)) |> bindEvent(obs)

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
#' obs_prep(model_id = "bam_v5_can71", species_id = "BBWO") |>
#'   obs_map()

obs_map <- function(obs) {
  obs |>
    leaflet::leaflet() |>
    leaflet::addTiles() |>
    obs_markers() |>
    leaflet.extras::addDrawToolbar(
      polylineOptions = FALSE,
      circleOptions = FALSE,
      rectangleOptions = leaflet.extras::drawRectangleOptions(),
      polygonOptions = leaflet.extras::drawPolygonOptions(),
      markerOptions = FALSE,
      circleMarkerOptions = FALSE
    )
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

obs_markers <- function(map, data = leaflet::getMapData(map)) {
  pal <- leaflet::colorFactor("#637261ff", data$detections)

  map |>
    leaflet::addCircleMarkers(
      color = ~"#000000",
      label = ~popup,
      layerId = ~id,
      data = data,
      radius = 5,
      fillOpacity = 0.7,
      opacity = 1,
      weight = 1,
      fillColor = ~ pal(detections)
    )
}

selected_markers <- function(
  map,
  data = leaflet::getMapData(map)
) {
  levels <- levels(data$type)
  pal <- leaflet::colorFactor(
    viridisLite::viridis(n = length(levels)),
    levels = factor(levels, levels = levels),
    ordered = TRUE
  )
  #"#fde725", data$detections)

  leaflet::addCircleMarkers(
    map,
    color = ~"#000000",
    label = ~popup,
    layerId = ~id,
    data = data,
    radius = 5,
    fillOpacity = 0.7,
    opacity = 1,
    weight = 1,
    fillColor = ~ pal(type)
  ) |>
    leaflet::addLegend(
      "bottomleft",
      pal = pal,
      values = levels,
      title = "Categories",
      opacity = 1,
      layerId = "legend" # Required to overwrite
    )
}
