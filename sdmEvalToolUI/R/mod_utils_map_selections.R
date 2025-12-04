#' Map Selections UI
#'
#' Highlights spatial ids selected, either through user selection or through the
#' 'show' button from evaluations.
#'
#' @param id Character. Shiny module ID.
#'
#' @returns Shiny UI
#'
#' @export
mod_utils_map_selections_ui <- function(id, spatial_type) {
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
        div(
          h4(textOutput(NS(id, "tbl_title"))),
          reactable::reactableOutput(NS(id, "tbl_selected"))
        ),
        div(
          strong(glue::glue(
            "Copy selected {stringr::str_remove(spatial_type, 's$')} IDs"
          )),
          copy_output(NS(id, "selected"))
        )
      )
    )
  )
}

#' Show spatial selections on map
#'
#' Highlights spatial ids selected, either through user selection or through the
#' 'show' button from evaluations.
#'
#' @param id Character. Shiny module ID
#' @param data Spatial Data frame. Data from which selections will be made.
#' @param spatial_selection List of `show_clicked` reactiveVal which indicates
#' which show button was last clicked and `show_spatial_ids` which contains a
#' list of spatial ids by category to highlight.
#'
#' @returns Shiny server
#'
#' @export

mod_utils_map_selections_server <- function(
  id,
  data,
  spatial_selection,
  interactions,
  spatial_type = "points",
  parent_session = getDefaultReactiveDomain()
) {
  stopifnot(is.reactive(data))

  expand_list(spatial_selection) # Leads to --->
  stopifnot(is.reactive(show_clicked)) # reactiveVal
  stopifnot(is.reactive(show_spatial_ids))

  if (spatial_type == "points") {
    remove_geo <- leaflet::removeMarker
    add_geo <- add_markers
    add_selected_geo <- add_selected_markers
    map_click <- "marker_click"
  } else if (spatial_type == "areas") {
    remove_geo <- leaflet::removeShape
    add_geo <- add_subunits
    add_selected_geo <- add_selected_subunits
    map_click <- "shape_click"
  }

  moduleServer(id, function(input, output, session) {
    # Setup ----------------------------------------------------------------
    curr_selected <- reactiveVal(data.frame())
    prev_selected <- reactiveVal(character(0))

    # Highlight selected shapes --------------------------------------------
    observe({
      # What needs to change?
      if (nrow(curr_selected()) > 0) {
        unselect <- setdiff(prev_selected(), curr_selected()$id)
      } else {
        unselect <- prev_selected()
      }
      select <- curr_selected()

      if (length(unselect) > 0) {
        leaflet::leafletProxy("map", session = parent_session) |>
          remove_geo(layerId = unselect) |>
          add_geo(dplyr::filter(data(), id %in% unselect))
      }

      if (nrow(select) > 0) {
        levels <- unique(select$type)
        d <- dplyr::right_join(data(), select, by = "id") |>
          dplyr::mutate(type = factor(type, levels = levels))

        leaflet::leafletProxy("map", session = parent_session) |>
          remove_geo(layerId = unique(select$id)) |>
          add_selected_geo(d)
      }

      # Track the current selection
      isolate(prev_selected(unique(select$id)))
    }) |>
      bindEvent(curr_selected(), ignoreInit = TRUE)

    # Map selections -------------------------------------------
    # Process Drawn Selections
    observe({
      req(interactions$draw_new_feature$geometry)
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
      id <- interactions[[map_click]]$id

      restart <- nrow(curr_selected()) == 0 ||
        !"Selected" %in% curr_selected()$type

      if (restart) {
        curr_selected(data.frame(id = id, type = "Selected"))
      } else {
        if (id %in% curr_selected()$id) {
          if (all(curr_selected()$id %in% id)) {
            curr_selected(data.frame())
          } else {
            curr_selected(data.frame(
              id = setdiff(curr_selected()$id, id),
              type = "Selected"
            ))
          }
        } else {
          curr_selected(data.frame(
            id = union(curr_selected()$id, id),
            type = "Selected"
          ))
        }
      }
    }) |>
      bindEvent(interactions[[map_click]])

    # Selection Details ---------------------------
    output$tbl_selected <- reactable::renderReactable({
      validate(need(
        nrow(curr_selected()) > 0,
        glue::glue("No {spatial_type} selected")
      ))

      r <- data() |>
        dplyr::right_join(curr_selected(), by = "id") |>
        dplyr::relocate(type) |>
        sf::st_drop_geometry() |>
        dplyr::select(-dplyr::any_of("popup")) |>
        dplyr::rename_with(stringr::str_to_title) |>
        dplyr::rename("Category" = "Type") |>
        reactable::reactable()

      r
    })

    output$tbl_title <- renderText({
      if (
        nrow(curr_selected()) == 0 ||
          "Selected" %in% curr_selected()$type
      ) {
        title <- glue::glue("Currently selected {spatial_type}")
      } else {
        title <- glue::glue("Identified {spatial_type}")
      }
      title
    })

    output$selected <- renderText({
      req(curr_selected())
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
