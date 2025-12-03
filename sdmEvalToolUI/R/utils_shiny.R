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
  x = c("draw_all_features", "draw_new_feature", "draw_stop", "marker_click")
) {
  rv <- reactiveValues()
  x1 <- paste0(map, "_", x)
  purrr::walk2(x, x1, \(x, x1) observe(rv[[x]] <- input[[x1]]))
  rv
}
