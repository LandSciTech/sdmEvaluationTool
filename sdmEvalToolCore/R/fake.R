#' Fake DB Entries
#'
#' @param deployment_id Deployment ID.
#' @param model_id Model ID.
#' @param species_id Species ID.
#' @param user_id User ID.
#' @param material_id Material ID.
#' @param component_id Component ID.
#' @param question A questions data frame with a single row.
#' @param questions A questions data frame.
#' @param time Date-time.
#'
#' @examples
#' fake_comment(
#'     deployment_id = "deployment1",
#'     model_id = "model1",
#'     species_id = "MOTR",
#'     user_id = "draper")
#'
#' str(fake_response(sdmEvalToolCore::default_questions[1,]))
#'
#' fake_evaluation(
#'     deployment_id = "deployment1",
#'     material_id = "material1",
#'     component_id = "model_fit",
#'     user_id = "draper")
#'
#' @name fake
NULL

#' @export
#' @rdname fake
fake_comment <- function(
  deployment_id,
  model_id,
  species_id,
  user_id,
  time = NULL
) {
  if (is.null(time)) {
    time <- now()
  }
  data.frame(
    deployment_id = as.character(deployment_id),
    model_id = as.character(model_id),
    species_id = as.character(species_id),
    comment_create_user = as.character(user_id),
    comment_create_time = timestamp_to(time),
    comment_body = as.character(lorem::ipsum(sentence = 1))
  )
}

#' @export
#' @rdname fake
fake_evaluation <- function(
  deployment_id,
  material_id,
  component_id,
  user_id,
  questions = NULL,
  time = NULL
) {
  if (is.null(time)) {
    time <- now()
  }
  q <- if (is.null(questions)) {
    sdmEvalToolCore::default_questions
  } else {
    questions
  }
  q <- q[q$component == component_id, ]
  qq <- lapply(seq_len(nrow(q)), function(i) fake_response(q[i, ]))
  data.frame(
    deployment_material_id = paste0(deployment_id, "_", material_id),
    deployment_id = deployment_id,
    material_id = material_id,
    component_id = component_id,
    use_case = "Forestry",
    evaluation_create_user = user_id,
    evaluation_create_time = timestamp_to(time),
    evaluation_modify_user = NA_character_,
    evaluation_modify_time = NA_integer_,
    evaluation_body = jsonlite::toJSON(qq, auto_unbox = TRUE),
    note_create_user = NA_character_,
    note_create_time = NA_integer_,
    note_body = NA_character_
  )
}

#' @export
#' @rdname fake
fake_response <- function(question) {
  v <- as.list(question)
  v$values <- v$values[[1L]][[1L]]
  if (question$type == "simple_text") {
    v$response <- as.character(lorem::ipsum(sentence = 1))
  }
  if (question$type == "ordinal") {
    v$response <- sample(v$values, 1L)
  }
  if (question$type == "spatial") {
    v$response <- list()
    for (i in seq_along(v$values)) {
      v$response[[i]] <- list(
        value = v$values[i],
        subunits = sort(sample(
          c(
            "15.1",
            "15.2",
            "3.2",
            "3.3",
            "5.1",
            "5.2",
            "6.1",
            "6.1",
            "6.2"
          ),
          2
        ))
      )
    }
  }
  v
}
