#' Utility Module 'Map Synchronization' Server
#'
#' Synchronizes the map view port among tabs
#'
#' @param id Character. Shiny module ID
#'
#' @returns Shiny server
#'
#' @export

mod_utils_map_sync_server <- function(
  id,
  parent_id,
  this_view,
  map_views,
  parent_session = getDefaultReactiveDomain()
) {
  moduleServer(id, function(input, output, session) {
    # Update -------------------------------------------
    # Record map zoom/centre only if this tab is active
    # (Otherwise may record wonky values after tab changed)
    observe({
      req(map_views$active_tab() == parent_id)
      req(this_view())
      map_views$view(this_view())
      map_views$set_by(parent_id)
    }) |>
      bindEvent(this_view())

    # Set -----------------------------------------------
    # Change map view only if
    #   - view set by another tab AND
    #   - this tab is active AND
    #   - the difference in views is greater than tolerance (see view_match())
    observe({
      req(map_views$set_by() != parent_id)
      req(map_views$active_tab() == parent_id)
      req(!view_match(map_views$view(), this_view()))

      set_view(
        leaflet::leafletProxy("map", session = parent_session),
        map_views
      )
    })
  })
}
