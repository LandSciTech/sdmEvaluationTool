validate_ids <- function(..., .call = rlang::caller_env()) {
  expand_dots(...)
  nms <- names(list(...))
  n <- purrr::map(nms, \(w) need(get(w), paste("Please select a", pretty(w))))
  validate(!!!n)
}
