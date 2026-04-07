test_that("evals_extract() parses JSON evaluation body", {
  json <- test_evaluation_body()
  e <- evals_extract(json)

  expect_s3_class(e, "data.frame")
  expect_named(
    e,
    c("question_id", "label", "values", "response", "abandoned")
  )
  expect_true(nrow(e) > 0)
})

test_that("evals_answered()", {
  a <- test_evaluation_body() |>
    evals_extract() |>
    evals_answered()

  expect_s3_class(a, "data.frame")
  expect_equal(a, data.frame(n_q = 6, n_q_complete = 3))

  a <- test_evaluation_body("model_fit_a") |>
    evals_extract() |>
    evals_answered()

  expect_s3_class(a, "data.frame")
  expect_equal(a, data.frame(n_q = 3, n_q_complete = 1))

  a <- test_evaluation_body("model_fit_b") |>
    evals_extract() |>
    evals_answered()

  expect_s3_class(a, "data.frame")
  expect_equal(a, data.frame(n_q = 6, n_q_complete = 2))
})

test_that("check_q_mismatch()", {
  # No error on match
  expect_silent(check_q_mismatch(c(1, 1, 2, 10, 6), c(1, 1, 2, 10, 6)))

  # No error on missing
  expect_silent(check_q_mismatch(c(10, 7, 1), c(10, NA, NA)))

  # Error on mismatch
  expect_error(check_q_mismatch(c(10, 11, 1), c(10, 10, NA)))
})


test_that("save/read evaluations", {
  skip_if_no_data()

  # Expect circularity from questions to saved answers and back to loaded answers
  expect_silent(q0 <- do.call(test_questions, test_inputs()))
  expect_silent(a <- test_input_evals(q0))

  expect_output(save_evaluations(q0, a, user_id = "testuser"))

  expect_silent(
    q1 <- do.call(prep_questions, test_inputs()) |>
      evals_list()
  )

  expect_equal(a, q1)
})
