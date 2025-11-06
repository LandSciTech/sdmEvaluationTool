evaluations <- function(
  component_id,
  deployment_id,
  model_id,
  species_id = NA
) {
  validate_ids(
    deployment_id = deployment_id,
    model_id = model_id,
    species_id = species_id
  )

  q <- dplyr::rows_upsert(
    sdmEvalToolCore::default_questions,
    prep_deployments(deployment_id, "questions"),
    by = c("component", "order")
  ) |>
    dplyr::filter(.data$component == .env$component_id) |>
    dplyr::rename("label" = sdmevaltool_options()$lang) |>
    dplyr::mutate(
      ui = dplyr::case_match(
        .data$type,
        "text" ~ "text_input",
        "heading" ~ "h2",
        "gold_standard" ~ "gold_standard_input",
        "ordinal" ~ "slider_input"
      ),
      id = paste(
        .env$deployment_id,
        .env$model_id,
        .env$species_id,
        .data$component,
        .data$order,
        sep = "_"
      )
    ) |>
    dplyr::select("ui", "id", "label")

  tagList(
    purrr::pmap(q, \(ui, id, label) {
      get(ui)(id = id, label = label)
    })
  )
}
