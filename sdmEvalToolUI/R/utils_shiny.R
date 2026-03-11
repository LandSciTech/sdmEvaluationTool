#' Validate input ids
#'
#' @param ... Named arguments containing id values to validate (e.g.,
#' deployment_id, model_id, species_id)
#'
#' @returns NULL (invisibly), or throws validation error if any id is missing
#'
#' @export

validate_ids <- function(...) {
  expand_dots(...)
  nms <- names(list(...))
  n <- purrr::map(nms, \(w) need(get(w), paste("Please select a", pretty(w))))
  validate(!!!n)
}

map_reactive_vals <- function(
  input,
  map,
  x = c(
    "draw_all_features",
    "draw_new_feature",
    "draw_stop",
    "marker_click",
    "shape_click"
  ),
  js_x = c(
    "clear_selection", # From EasyButton created in `base_map()`
    "layers_visible"
  ) # From Layers update function in `base_map()`
) {
  rv <- reactiveValues()

  # Update those Namespaced with the map
  x1 <- paste0(map, "_", x)

  # Join all together
  x <- c(x, js_x)
  x1 <- c(x1, js_x)

  # Create individual observers to update the Reactive Values
  purrr::walk2(x, x1, \(x, x1) {
    observe({
      rv[[x]] <- input[[x1]]
    })
  })
  rv
}

sdm_spinner <- function(ui_element, fill = TRUE) {
  as_fill_carrier(
    shinycssloaders::withSpinner(
      type = 8,
      color.background = bs_get_variables(sdm_theme(), "primary"),
      ui_element
    )
  )
}

sdm_card <- function(
  ...,
  class = "p-0",
  full_screen = TRUE,
  min_height = 400
) {
  card(
    class = class,
    full_screen = full_screen,
    min_height = min_height,
    ...
  )
}

sdm_nav_panel <- function(title, ..., class = "sdm-tab-pane") {
  nav_panel(title, class = class, ...)
}

sdm_layout_sidebar <- function(..., gap = 0, border = FALSE) {
  layout_sidebar(
    gap = gap,
    border = border,
    ...
  )
}
