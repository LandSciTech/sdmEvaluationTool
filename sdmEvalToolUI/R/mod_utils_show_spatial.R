#' Show spatial ideas in evaluations
#'
#' Highlights spatial ids indicated in the evaluations on the map.
#'
#' @param id
#' @param questions_init
#'
#' @returns
#'
#' @export
mod_utils_show_spatial_server <- function(id, questions_init) {
  stopifnot(is.reactive(questions_init))

  moduleServer(id, function(input, output, session) {})
}
