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
    dplyr::mutate(id = paste0("id", dplyr::row_number()))
}
