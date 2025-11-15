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
