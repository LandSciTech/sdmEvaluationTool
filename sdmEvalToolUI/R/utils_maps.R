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

#' Compare map views against a tolerance
#'
#' Compares map views within a defined tolerance. If the views are close enough,
#' returns `TRUE` otherwise `FALSE`.
#'
#' @param v1 List. First map view to compare. List with zoom and list of lat,
#' and lon.
#' @param v2 List. Second map view to compare. List with zoom and list of lat,
#' and lon.
#' @param tolerance Numeric. Amount of difference in coordinates tolerated.
#'
#' @returns Logical TRUE if the views match within `tolerance` for the coordinates.
#'  FALSE if the views do not match.
#'
#' @noRd

view_match <- function(v1, v2, tolerance = 0.01) {
  v1 <- unlist(v1)
  v2 <- unlist(v2)

  !is.null(v1) && !is.null(v2) && all(abs(v1 - v2) <= tolerance)
}
