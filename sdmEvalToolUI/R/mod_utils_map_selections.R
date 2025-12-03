mod_utils_map_selections_ui <- function(id) {
  tagList(
    # From: https://github.com/trafficonese/leaflet.extras/issues/96
    # Removes selection when called
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
    card(
      layout_columns(
        col_widths = c(8, 4),
        reactable::reactableOutput(NS(id, "tbl_selected")),
        div(
          strong("Copy selected point IDs"),
          copy_output(NS(id, "selected"))
        )
      )
    )
  )
}

#' Show spatial ideas in evaluations
#'
#' Highlights spatial ids indicated in the evaluations on the map.
#'
#' @param id
#' @param data
#' @param spatial_selection
#'
#' @returns
#'
#' @export
mod_utils_map_selections_server <- function(
  id,
  data,
  spatial_selection,
  interactions,
  type = "markers",
  parent_session = getDefaultReactiveDomain()
) {
  stopifnot(is.reactive(data))

  expand_list(spatial_selection) # Leads to --->
  stopifnot(is.reactive(show_clicked)) # reactiveVal
  stopifnot(is.reactive(show_spatial_ids))

  if (type == "markers") {
    remove_geo <- leaflet::removeMarker
    add_geo <- add_markers
    add_selected_geo <- add_selected_markers
  } else if (type == "polygons") {
    remove_geo <- leaflet::removeShape
    add_geo <- add_markers #TODO: UPDATE
    add_selected_geo <- add_selected_markers #TODO: UPDATE
  }

  moduleServer(id, function(input, output, session) {
    # Setup ----------------------------------------------------------------
    curr_selected <- reactiveVal()
    prev_selected <- reactiveVal()

    # Highlight selected shapes --------------------------------------------
    observe({
      # What needs to change?
      unselect <- setdiff(prev_selected(), curr_selected()$id)
      select <- curr_selected()

      if (length(unselect) > 0) {
        leaflet::leafletProxy("map", session = parent_session) |>
          remove_geo(layerId = unselect) |>
          add_geo(data = dplyr::filter(data(), id %in% unselect))
      }
      if (nrow(select) > 0) {
        levels <- unique(select$type)
        d <- dplyr::right_join(data(), select, by = "id") |>
          dplyr::mutate(type = factor(type, levels = levels))

        leaflet::leafletProxy("map", session = parent_session) |>
          remove_geo(layerId = unique(select$id)) |>
          add_selected_geo(data = d)
      }

      # Track the current selection
      isolate(prev_selected(unique(select$id)))
    }) |>
      bindEvent(curr_selected(), ignoreInit = TRUE)

    # Map selections -------------------------------------------
    # Process Drawn Selections
    observe({
      # Store the selections
      poly <- coords_to_poly(interactions$draw_new_feature$geometry)
      s <- data() |>
        sf::st_transform(4326) |>
        sf::st_filter(poly)
      curr_selected(data.frame(id = s$id, type = "Selected"))

      # Remove the drawn section
      feature_ids(interactions$draw_all_features) |>
        purrr::walk(\(x) {
          session$sendCustomMessage(
            "removeleaflet",
            list(elid = parent_session$ns("map"), layerid = x)
          )
        })
    }) |>
      bindEvent(interactions$draw_stop, ignoreInit = TRUE)

    # Process click selections
    observe({
      id <- interactions$marker_click$id

      if (!"Selected" %in% curr_selected()$type) {
        curr_selected(data.frame(id = id, type = "Selected"))
      } else {
        if (id %in% curr_selected()$id) {
          curr_selected(data.frame(
            id = setdiff(curr_selected()$id, id),
            type = "Selected"
          ))
        } else {
          curr_selected(data.frame(
            id = union(curr_selected()$id, id),
            type = "Selected"
          ))
        }
      }
    }) |>
      bindEvent(interactions$marker_click)

    # Selection Details ---------------------------
    output$tbl_selected <- reactable::renderReactable({
      validate(need(
        nrow(curr_selected()) > 0,
        "No points selected"
      ))

      r <- data() |>
        dplyr::right_join(curr_selected(), by = "id") |>
        dplyr::relocate(type) |>
        sf::st_drop_geometry() |>
        dplyr::select(-"popup") |>
        reactable::reactable()

      if ("Selected" %in% curr_selected()$type) {
        title <- "Currently selected points"
      } else {
        title <- "Identified points"
      }

      div(h4(title), r)
      r
    })

    output$selected <- renderText({
      req("Selected" %in% curr_selected()$type)
      data() |>
        dplyr::filter(
          .data$id %in%
            curr_selected()$id[curr_selected()$type == "Selected"]
        ) |>
        dplyr::pull(.data$id) |>
        paste0(collapse = ",")
    })

    # Update selected ids to be shown on map----------------------------------
    observe({
      ids <- show_spatial_ids() |>
        purrr::map(\(i) if (length(i) > 0) data.frame(id = i)) |>
        purrr::list_rbind(names_to = "type")
      curr_selected(ids)
    }) |>
      bindEvent(show_clicked(), ignoreInit = TRUE)
  })
}
