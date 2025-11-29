# Test check_q_mismatch() ------------------------------------------------

test_that("check_q_mismatch() accepts matching values", {
  expect_silent(check_q_mismatch(c(1, 1, 2, 10, 6), c(1, 1, 2, 10, 6)))
  expect_silent(check_q_mismatch(c(10, 7, 1), c(10, NA, NA)))
  expect_silent(check_q_mismatch(c(5, 5, 5), c(5, 5, 5)))
})

test_that("check_q_mismatch() handles NA values correctly", {
  expect_silent(check_q_mismatch(c(10, 11, 1), c(10, NA, NA)))
  expect_silent(check_q_mismatch(c(1, 2, 3), c(NA, NA, NA)))
  expect_silent(check_q_mismatch(c(5, 5), c(NA, 5)))
})

test_that("check_q_mismatch() errors on mismatched values", {
  expect_error(
    check_q_mismatch(c(10, 11, 1), c(10, 10, NA)),
    "Mismatch between evaluated and deployed questions"
  )
  expect_error(
    check_q_mismatch(c(1, 2, 3), c(2, 2, 3)),
    "Mismatch between evaluated and deployed questions"
  )
  expect_error(
    check_q_mismatch(c(5, 5, 5), c(5, 6, 5)),
    "Mismatch between evaluated and deployed questions"
  )
})

test_that("check_q_mismatch() handles edge cases", {
  expect_silent(check_q_mismatch(integer(0), integer(0)))
  expect_silent(check_q_mismatch(c(1), c(1)))
  expect_silent(check_q_mismatch(c(1), c(NA)))
})


# Test evals_extract() ----------------------------------------------------
json <- paste0(
  '[',
  '{\"order\":[0],\"type\":[\"heading\"],\"question_body\":{\"en\":[\"What is the accuracy of model predictions based on your expert knowledge?\"],\"fr\":[\"\"]}},',
  '{\"order\":[1],\"type\":[\"gold_standard\"],\"question_body\":{\"en\":[\"How confident are you about model predictions?\"],\"fr\":[\"\"]},\"response\":[\"5\"]},',
  '{\"order\":[2],\"type\":[\"text\"],\"question_body\":{\"en\":[\"Why is it a problem?\"],\"fr\":[\"\"]},\"response\":[\"Not applicable\"]}',
  ']'
)

test_that("evals_extract() parses JSON", {
  result <- evals_extract(json)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 3)
  expect_named(
    result,
    c("order", "type", "question_body", "response"),
    ignore.order = TRUE
  )

  # TODO: Should columns be lists? Do we expect multiple answers?
  expect_equal(result$order, list(0, 1, 2))
  expect_equal(result$type, list("heading", "gold_standard", "text"))
  expect_equal(result$response, list(NULL, "5", "Not applicable"))
})

test_that("evals_extract() handles empty responses", {
  json_empty <- '[{"question": "Q1", "response": ""}]'
  result <- evals_extract(json_empty)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1)
  expect_equal(result$response, "")
})


# Test evals_answered() ---------------------------------------------------

test_that("evals_answered() counts questions correctly", {
  eval_data <- evals_extract(json)
  result <- evals_answered(eval_data)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1)
  expect_named(result, c("n_q", "n_q_complete"), ignore.order = TRUE)
  expect_equal(result$n_q, 3)
  expect_equal(result$n_q_complete, 2)
})

test_that("evals_answered() handles none answered", {
  eval_data <- data.frame(
    question = c("Q1", "Q2", "Q3"),
    response = I(list(NULL, NULL, NULL))
  )

  result <- evals_answered(eval_data)

  expect_equal(result$n_q, 3)
  expect_equal(result$n_q_complete, 0)
})

test_that("evals_answered() handles empty data", {
  eval_data <- data.frame(
    question = character(0),
    response = I(list())
  )

  result <- evals_answered(eval_data)

  expect_equal(result$n_q, 0)
  expect_equal(result$n_q_complete, 0)
})

test_that("evals_answered() counts only truthy responses", {
  eval_data <- data.frame(
    question = c("Q1", "Q2", "Q3", "Q4", "Q5", "Q6"),
    response = I(list("Yes", "", 0, FALSE, 1, "answer"))
  )

  result <- evals_answered(eval_data)

  expect_equal(result$n_q, 6)
  expect_equal(result$n_q_complete, 5)
})


# Test evals_details() ----------------------------------------------------

test_that("evals_details() requires valid user_role", {
  withr::with_options(
    set_options(base = test_path("../../../misc/base")),
    {
      skip_if_not(dir.exists(sdmevaltool_options()$base))

      expect_error(
        evals_details("holden", "invalid_role"),
        "Overview table only relevant for modelers and evaluators"
      )
    }
  )
})

test_that("evals_details() returns data frame with expected columns", {
  withr::with_options(
    set_options(base = test_path("../../../misc/base")),
    {
      skip_if_not(dir.exists(sdmevaltool_options()$base))

      expect_silent(e1 <- evals_details("holden", "modeler"))
      expect_silent(e2 <- evals_details("draper", "evaluator"))

      expect_s3_class(e1, "data.frame")
      expect_s3_class(e2, "data.frame")

      # Modeler is not evaluator
      expect_true(!any(e1$evaluation_create_user_name == "James Holden"))
      expect_true(all(e2$evaluation_create_user_name == "Bobbie Draper"))

      expect_named(
        e1,
        c(
          "deployment_model_name",
          "evaluation_create_user_name",
          "deployment_name",
          "model_name",
          "species_display",
          "component_name",
          "completed",
          "started",
          "n_q_display",
          "n_q",
          "n_q_complete"
        ),
        ignore.order = TRUE
      )
    }
  )
})

test_that("evals_details() handles no evaluations access", {
  withr::with_options(
    set_options(base = test_path("../../../misc/base")),
    {
      skip_if_not(dir.exists(sdmevaltool_options()$base))

      expect_silent(e <- evals_details("holden", "evaluator"))
      expect_s3_class(e, "data.frame")
      expect_equal(nrow(e), 0)
    }
  )
})


# Test evals_table() ------------------------------------------------------

test_that("evals_table() returns reactable", {
  withr::with_options(
    set_options(base = test_path("../../../misc/base")),
    {
      skip_if_not(dir.exists(sdmevaltool_options()$base))

      e <- evals_details("holden", "modeler")
      expect_silent(evals_table(e, "modeler")) |>
        expect_s3_class("reactable")
    }
  )
})

test_that("evals_table() works for evaluator role", {
  withr::with_options(
    set_options(base = test_path("../../../misc/base")),
    {
      skip_if_not(dir.exists(sdmevaltool_options()$base))

      e <- evals_details("draper", "evaluator")
      expect_silent(evals_table(e, "evaluator")) |>
        expect_s3_class("reactable")
    }
  )
})

test_that("evals_table() handles empty data", {
  empty_tbl <- data.frame(
    deployment_model_name = character(0),
    evaluation_create_user_name = character(0),
    deployment_name = character(0),
    model_name = character(0),
    species_display = character(0),
    component_name = character(0),
    completed = logical(0),
    started = logical(0),
    n_q_display = character(0),
    n_q = integer(0),
    n_q_complete = integer(0)
  )

  expect_silent(evals_table(empty_tbl, "modeler")) |>
    expect_s3_class("reactable")
})
