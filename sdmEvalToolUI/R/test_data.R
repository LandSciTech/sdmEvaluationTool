#' Create input list for quick tests
#'
#'
#' @param component Character. Component ids to include
#' @param deployment_id Character. Deployment ids to include
#' @param model_id Character. Model ids to include
#' @param species_id Character. Species ids to include
#' @param user_id Character. User id to include
#'
#' @returns Named list
#'
#' @noRd
#' @examples
#' do.call(prep_questions, test_inputs())

test_inputs <- function(
  component = "observations",
  deployment_id = "deployment_test",
  model_id = "bam_v5_can71",
  species_id = "BBWO",
  user_id = "test_user"
) {
  list(
    component = component,
    deployment_id = deployment_id,
    model_id = model_id,
    species_id = species_id,
    user_id = user_id
  )
}


#' Create dummy questions for testing
#'
#' @param component Component.
#' @param deployment_id Deployment ID.
#' @param model_id Model ID.
#' @param species_id Species ID.
#' @param types Question types.
#' @param user_id User id.
#'
#' @examples
#' test_questions()
#' @export
test_questions <- function(
  component = "observations",
  deployment_id = "deployment_test",
  model_id = "bam_v5_can71",
  species_id = "BBWO",
  types = c("spatial", "ordinal", "simple_text"),
  user_id = "testuser"
) {
  q <- sdmEvalToolCore::default_questions |>
    # Renumber
    dplyr::mutate(
      part = dplyr::row_number() - 1,
      .by = c("component", "order")
    ) |>
    dplyr::rename("label" = "english") |>
    dplyr::mutate(
      deployment_id = .env$deployment_id,
      model_id = .env$model_id,
      species_id = .env$species_id,
      evaluation_create_user = .env$user_id,
      evaluation_create_time = "2025-01-01 00:00:00",
      last_modified = "2025-01-02 00:00:00",
      material_id = glue::glue("{model_id}_{species_id}_{component}"),
      question_id = glue::glue("{deployment_id}_{material_id}_{order}_{part}")
    )

  if (!is.null(component)) {
    q <- q[q$component == component, ]
  }
  if (!is.null(types)) {
    q <- q[q$type %in% types, ]
  }

  q
}

#' Create dummy input values for evaluations
#'
#' @param questions Data frame. Output of `.prep_questions()`
#'
#' @returns List of dummy input values. Mimics and `input` object from the Shiny app.
#'
#' @export
#' @examples
#' q <- test_questions()
#' test_input_evals(q)

test_input_evals <- function(questions) {
  q <- questions |>
    dplyr::select("type", "question_id", "values") |>
    tidyr::unnest("values") |>
    dplyr::mutate(
      question_id = dplyr::if_else(
        .data$type == "spatial",
        paste0(.data$question_id, "-", value_to_input(.data$values)),
        .data$question_id
      )
    ) |>
    dplyr::select(-"values") |>
    dplyr::distinct()

  q_id <- q$question_id

  v <- vector("list", length(q_id))
  for (i in seq_along(q_id)) {
    if (q$type[i] == "simple_text") {
      v[[i]] <- sample(c("", "sldfkjasdlfj", "test"), 1)
    } else if (q$type[i] == "spatial") {
      v[[i]] <- paste0("id", 1:100)[sample(
        1:100,
        size = sample(0:10, size = 1)
      )]
      if (length(v[[i]]) == 0) v[[i]] <- NULL
    } else if (q$type[i] == "ordinal") {
      v[[i]] <- sample(
        c(
          "Extremely",
          "Very",
          "Moderately",
          "Slightly",
          "Not at all",
          "Uncertain"
        ),
        1
      )
    } else if (q$type[i] == "yesno") {
      v[[i]] <- sample(c("yes", "no", ""), 1)
    }
  }

  rlang::set_names(v, q_id)
}


#' Create dummy json evaluation body
#'
#' This can be used for testing loading/extracting/counting/etc. questions.
#' These are created by running the App, saving data, and then extracting the
#' JSON bodies. They can be updated the same way. Note that there are different
#' bodies to test different kinds of behaviour.
#'
#' @param component_id Character. Id of the test evaluation body to use.
#'   Currently "observations", "model_fit_a", or "model_fit_b"
#'
#' @returns Character. JSON string for hypothetical evaluation
#'
#' @export
#' @examples
#' test_evaluation_body()
#'
#' \dontrun{
#'   # After created through app with 'testuser' and `deployment2` retrieved with:
#'   db_read_evaluations(db_connect(), "deployment2", "testuser") |>
#'     dplyr::filter(component_id == "model_fit") |>
#'     dplyr::slice(1) |>
#'     dplyr::pull(evaluation_body)
#' }

test_evaluation_body <- function(component_id = "observations") {
  if (component_id == "observations") {
    b <- "[{\"question_id\":\"deployment1_bam_v5_can71_BBWA_observations_1_0\",\"label\":\"Are there areas where you are concerned about potential bias in the data? Identify areas with potential bias in the data.\",\"values\":[\"Very biased\",\"Moderately biased\",\"Accurate\",\"Unknown\"],\"response\":[{\"value\":\"Very biased\",\"subunits\":[\"id4\",\"id5\",\"id6\",\"id7\",\"id8\",\"id9\",\"id10\"]},{\"value\":\"Moderately biased\",\"subunits\":{}},{\"value\":\"Accurate\",\"subunits\":[\"id2\",\"id3\",\"id4\",\"id5\"]},{\"value\":\"Unknown\",\"subunits\":{}}]},{\"question_id\":\"deployment1_bam_v5_can71_BBWA_observations_2_0\",\"label\":\"Are there areas where this species is not sufficiently sampled? Identify areas that are not sufficiently sampled.\",\"values\":[\"Very undersampled\",\"Moderately undersampled\",\"Accurate\",\"Unknown\"],\"response\":[{\"value\":\"Very undersampled\",\"subunits\":[\"id3\",\"id4\",\"id5\",\"id6\",\"id7\",\"id8\"]},{\"value\":\"Moderately undersampled\",\"subunits\":{}},{\"value\":\"Accurate\",\"subunits\":{}},{\"value\":\"Unknown\",\"subunits\":[\"id4\",\"id5\",\"id6\",\"id7\",\"id8\",\"id9\"]}]},{\"question_id\":\"deployment1_bam_v5_can71_BBWA_observations_3_0\",\"label\":\"How concerned are you about the distribution of counts?\",\"values\":\"\",\"response\":\"Extremely\"},{\"question_id\":\"deployment1_bam_v5_can71_BBWA_observations_3_1\",\"label\":\"If so, explain. What is an appropriate truncation value (i.e. highest count)?\",\"values\":\"\",\"response\":\"\"},{\"question_id\":\"deployment1_bam_v5_can71_BBWA_observations_4_0\",\"label\":\"How concerned are you about the temporal distribution of detections?\",\"values\":\"\",\"response\":\"\"},{\"question_id\":\"deployment1_bam_v5_can71_BBWA_observations_4_1\",\"label\":\"If so, explain. What is an appropriate truncation value (i.e. minimum year)?\",\"values\":\"\",\"response\":\"\"},{\"question_id\":\"deployment1_bam_v5_can71_BBWA_observations_5_0\",\"label\":\"How concerned are you about the description and treatment of potential biases in the data, as described in the model metadata?\",\"values\":\"\",\"response\":\"\"}]"
  }
  if (component_id == "model_fit_a") {
    # After created through app, retrieved from:
    # db_read_evaluations(db_connect(), "deployment2", "testuser") |>
    #   dplyr::filter(component_id == "model_fit") |>
    #   dplyr::slice(1) |>
    #   dplyr::pull(evaluation_body)

    b <- "[{\"question_id\":\"deployment2_bam_v5_can71_BBWA_model_fit_1_0\",\"label\":\"How concerned are you about the adequacy or appropriateness of the validation metrics?\",\"values\":\"\",\"response\":[{\"value\":null,\"subunits\":\"Not at all\"}]},{\"question_id\":\"deployment2_bam_v5_can71_BBWA_model_fit_1_1\",\"label\":\"Why is it a problem?\",\"values\":\"\",\"response\":\"dasldkfj\"},{\"question_id\":\"deployment2_bam_v5_can71_BBWA_model_fit_1_2\",\"label\":\"How important is it to fix the problem?\",\"values\":\"\",\"response\":[{\"value\":null,\"subunits\":\"\"}]},{\"question_id\":\"deployment2_bam_v5_can71_BBWA_model_fit_1_3\",\"label\":\"How difficult is it to fix the problem?\",\"values\":\"\",\"response\":[{\"value\":null,\"subunits\":\"\"}]},{\"question_id\":\"deployment2_bam_v5_can71_BBWA_model_fit_2_0\",\"label\":\"What are the metrics that should be used and why?\",\"values\":\"\",\"response\":\"\"},{\"question_id\":\"deployment2_bam_v5_can71_BBWA_model_fit_3_0\",\"label\":\"What other concerns do you have about model performance?\",\"values\":\"\",\"response\":\"\"}]"
  }

  if (component_id == "model_fit_b") {
    # After created through app, retrieved from:
    # db_read_evaluations(db_connect(), "deployment2", "testuser") |>
    #   dplyr::filter(component_id == "model_fit") |>
    #   dplyr::slice(1) |>
    #   dplyr::pull(evaluation_body)

    b <- "[{\"question_id\":\"deployment2_bam_v5_can71_BBWA_model_fit_1_0\",\"label\":\"How concerned are you about the adequacy or appropriateness of the validation metrics?\",\"values\":\"\",\"response\":[{\"value\":null,\"subunits\":\"Extremely\"}]},{\"question_id\":\"deployment2_bam_v5_can71_BBWA_model_fit_1_1\",\"label\":\"Why is it a problem?\",\"values\":\"\",\"response\":\"dasldkfj\"},{\"question_id\":\"deployment2_bam_v5_can71_BBWA_model_fit_1_2\",\"label\":\"How important is it to fix the problem?\",\"values\":\"\",\"response\":[{\"value\":null,\"subunits\":\"\"}]},{\"question_id\":\"deployment2_bam_v5_can71_BBWA_model_fit_1_3\",\"label\":\"How difficult is it to fix the problem?\",\"values\":\"\",\"response\":[{\"value\":null,\"subunits\":\"\"}]},{\"question_id\":\"deployment2_bam_v5_can71_BBWA_model_fit_2_0\",\"label\":\"What are the metrics that should be used and why?\",\"values\":\"\",\"response\":\"\"},{\"question_id\":\"deployment2_bam_v5_can71_BBWA_model_fit_3_0\",\"label\":\"What other concerns do you have about model performance?\",\"values\":\"\",\"response\":\"\"}]"
  }

  b
}


test_points <- function() {
  data.frame(
    id = 1:5,
    popup = c("Toronto", "Ottawa", "Thunder Bay", "Sudbury", "Windsor"),
    type = factor(c("l1", "l1", "l2", "l2", "l3")),
    layers = factor(c("present", "present", "absent", "absent", "absent")),
    longitude = c(-79.3832, -75.6972, -89.2477, -80.9930, -83.0366),
    latitude = c(43.6532, 45.4215, 48.3809, 46.4917, 42.3149)
  ) |>
    sf::st_as_sf(
      coords = c("longitude", "latitude"),
      crs = 4326
    )
}

test_raster <- function() {
  terra::rast(
    xmin = -95,
    xmax = -74,
    ymin = 46,
    ymax = 56,
    resolution = 0.1,
    crs = "EPSG:4326"
  )
}
