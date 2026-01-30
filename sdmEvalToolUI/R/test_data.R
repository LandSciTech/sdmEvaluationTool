#' Create dummy input values for evaluations
#'
#' @param questions Data frame. Output of `.prep_questions()`
#'
#' @returns List of dummy input values. Mimics and `input` object from the Shiny app.
#'
#' @export
#' @examples
#' q <- prep_questions("observations", "deployment_test", "bam_v5_can71", "BBWO")
#' test_input_evals(q)

test_input_evals <- function(questions) {
  q <- questions |>
    dplyr::select("id", "values") |>
    tidyr::unnest("values") |>
    dplyr::mutate(
      id = dplyr::if_else(
        .data$values != "",
        paste0(.data$id, "-", .data$values),
        .data$id
      )
    ) |>
    dplyr::pull(.data$id)

  v <- vector("list", length(q))
  for (i in seq_along(q)) {
    if (stringr::str_detect(q[i], "\\d$")) {
      v[[i]] <- sample(c("", "sldfkjasdlfj", "test"), 1)
    } else {
      v[[i]] <- paste0("id", 1:100)[sample(
        1:100,
        size = sample(0:10, size = 1)
      )]
    }
  }

  rlang::set_names(v, q)
}
