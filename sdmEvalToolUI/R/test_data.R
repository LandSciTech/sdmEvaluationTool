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
    dplyr::select("question_id", "values") |>
    tidyr::unnest("values") |>
    dplyr::mutate(
      question_id = dplyr::if_else(
        .data$values != "",
        paste0(.data$question_id, "-", value_to_input(.data$values)),
        .data$question_id
      )
    ) |>
    dplyr::pull(.data$question_id)

  v <- vector("list", length(q))
  for (i in seq_along(q)) {
    if (stringr::str_detect(q[i], "\\d$")) {
      v[[i]] <- sample(c("", "sldfkjasdlfj", "test"), 1)
    } else {
      v[[i]] <- paste0("id", 1:100)[sample(
        1:100,
        size = sample(0:10, size = 1)
      )]
      if (length(v[[i]]) == 0) v[[i]] <- NULL
    }
  }

  rlang::set_names(v, q)
}


#' Create dummy json evaluation body
#'
#' @returns Character. JSON string for hypothetical evaluation
#'
#' @export
#' @examples
#' test_evaluation_body()

test_evaluation_body <- function() {
  "[{\"question_id\":\"deployment1_bam_v5_can71_BBWA_observations_1_0\",\"label\":\"Are there areas where you are concerned about potential bias in the data? Identify areas with potential bias in the data.\",\"values\":[\"Very biased\",\"Moderately biased\",\"Accurate\",\"Unknown\"],\"response\":[{\"value\":\"Very biased\",\"subunits\":[\"id4\",\"id5\",\"id6\",\"id7\",\"id8\",\"id9\",\"id10\"]},{\"value\":\"Moderately biased\",\"subunits\":{}},{\"value\":\"Accurate\",\"subunits\":[\"id2\",\"id3\",\"id4\",\"id5\"]},{\"value\":\"Unknown\",\"subunits\":{}}]},{\"question_id\":\"deployment1_bam_v5_can71_BBWA_observations_2_0\",\"label\":\"Are there areas where this species is not sufficiently sampled? Identify areas that are not sufficiently sampled.\",\"values\":[\"Very undersampled\",\"Moderately undersampled\",\"Accurate\",\"Unknown\"],\"response\":[{\"value\":\"Very undersampled\",\"subunits\":[\"id3\",\"id4\",\"id5\",\"id6\",\"id7\",\"id8\"]},{\"value\":\"Moderately undersampled\",\"subunits\":{}},{\"value\":\"Accurate\",\"subunits\":{}},{\"value\":\"Unknown\",\"subunits\":[\"id4\",\"id5\",\"id6\",\"id7\",\"id8\",\"id9\"]}]},{\"question_id\":\"deployment1_bam_v5_can71_BBWA_observations_3_0\",\"label\":\"How concerned are you about the distribution of counts?\",\"values\":\"\",\"response\":\"Extremely\"},{\"question_id\":\"deployment1_bam_v5_can71_BBWA_observations_3_1\",\"label\":\"If so, explain. What is an appropriate truncation value (i.e. highest count)?\",\"values\":\"\",\"response\":\"\"},{\"question_id\":\"deployment1_bam_v5_can71_BBWA_observations_4_0\",\"label\":\"How concerned are you about the temporal distribution of detections?\",\"values\":\"\",\"response\":\"\"},{\"question_id\":\"deployment1_bam_v5_can71_BBWA_observations_4_1\",\"label\":\"If so, explain. What is an appropriate truncation value (i.e. minimum year)?\",\"values\":\"\",\"response\":\"\"},{\"question_id\":\"deployment1_bam_v5_can71_BBWA_observations_5_0\",\"label\":\"How concerned are you about the description and treatment of potential biases in the data, as described in the model metadata?\",\"values\":\"\",\"response\":\"\"}]"
}
