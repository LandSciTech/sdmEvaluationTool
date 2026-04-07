#' Convert coordinates to polygon
#'
#' For use when drawing selections.
#'
#' @param geometry From drawing selections.
#'
#' @returns Sf polygon
#'
#' @export
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

#' Check if a group exists in map
#'
#' Note: this only works for Leaflet maps, NOT Leaflet Proxies.
#' For example, this is why `mod_comp_predictor_raster` family of functions
#' are a bit convoluted when it calls to adding layers and controls (because
#' `add_controls()` only adds layers which are dected with this function).
#'
#' This may be slightly fragile if the list structure of the leaflet objects
#' change.
#'
#' @param map Leaflet Map (not Leaflet Proxy).
#' @param group Character Vector. Groups to check for.
#'
#' @returns Logical. True if detected, false otherwise.
#'
#' @export

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
