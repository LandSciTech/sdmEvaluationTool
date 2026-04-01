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


#' Format time nicely for humans
#'
#' @param time POSIXct time
#'
#' @returns Character. Nicely formated date
#'
#' @export
#' @examples
#' fmt_time(Sys.time())
#' fmt_time(as.POSIXct("2026-02-01 16:02"))
fmt_time <- function(time) {
  time |>
    format("%a, %b %d %Y<br>%I:%M %p") |>
    stringr::str_remove_all("(?<=(\\s|<br>))0")
}


fmt_pretty <- function(x) {
  x |> stringr::str_replace_all("_|-", " ") |> stringr::str_to_title()
}
