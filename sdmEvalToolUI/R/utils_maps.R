coords_to_poly <- function(geometry) {
  geometry$coordinates[[1]] |>
    unlist() |>
    matrix(ncol = 2, byrow = TRUE) |>
    list() |>
    sf::st_polygon() |>
    sf::st_sfc(crs = 4326)
}

#' Extract feature ids
#'
#' @param features The input for the draw all features
#' (`input${map}_draw_all_features`).
#'
#' @returns Numeric vector of leaflet ids

feature_ids <- function(features) {
  features |>
    purrr::pluck("features") |>
    purrr::map_dbl(\(x) purrr::pluck(x, "properties", "_leaflet_id"))
}

map_has_group <- function(map, group) {
  map$x$calls |>
    purrr::map_lgl(\(c) {
      purrr::map_lgl(c$args, \(i) {
        if (is.character(i)) {
          any(stringr::str_detect(i, group))
        } else {
          FALSE
        }
      }) |>
        any()
    }) |>
    any()
}
