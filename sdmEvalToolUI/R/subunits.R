# Subunits are used by multiple components for a deployment

#' Prepare Deployment Subunits
#'
#' @param deployment_id Character. Deployment ID
#'
#' @returns Subunits polygons
#'
#' @export
#' @examplesIf have_data()
#' deployment_subunits_prep(deployment_id = "deployment1")

deployment_subunits_prep <- function(deployment_id) {
  prep_deployments(
    deployment_id = deployment_id,
    deployment_type = "deployment_subunits"
  ) |>
    #TODO: Should they have unique ids?
    dplyr::summarize(
      dplyr::across("geom", sf::st_union),
      .by = "subunit_id"
    ) |>
    dplyr::mutate(
      id = .data$subunit_id,
      sort = tryCatch(as.numeric(.data$id), error = \(e) .data$id)
    ) |>
    dplyr::arrange(.data$sort) |>
    dplyr::select(-"sort") |>
    sf::st_transform(crs = 4326) # CLEANUP: Remove if fixed
}
