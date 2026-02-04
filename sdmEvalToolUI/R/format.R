#' Format species display names
#'
#' @param df Data frame to format. Must contain at least species name in French
#' or English as well as scientific name.
#'
#' @returns Formatted species display names.
#'
#' @export
fmt_species <- function(df) {
  df |>
    dplyr::mutate(
      # fmt: skip
      species_display = paste0(
        .data[[paste0(lang(), "_name")]],
        " (", .data$scientific_name, ")"
      ),
      species_display = dplyr::if_else(
        is.na(.data$species_id) | .data$species_id == "ALL",
        "Model",
        .data$species_display
      )
    )
}

fmt_tbl <- function(tbl, tbl_models, tbl_species) {
  # CLEANUP: Remove? - Get pretty column names
  tbl |>
    dplyr::left_join(
      dplyr::select(tbl_species, "species_id", "species_display"),
      by = "species_id"
    ) |>
    dplyr::left_join(
      dplyr::select(tbl_models, "model_id", "model_name"),
      by = "model_id"
    ) |>
    dplyr::select(-"model_id", "species_id") |>
    dplyr::relocate("model_name", "species_display")
}


fmt_time <- function(time) {
  time |>
    format("%a, %b %d %Y<br>%I:%M %p") |>
    stringr::str_remove_all("\\b0")
}
