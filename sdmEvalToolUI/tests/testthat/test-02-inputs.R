test_that("ui_questions()", {
  skip_if_no_data()

  q <- do.call(prep_questions, test_inputs())
  ui <- ui_questions(q)

  expect_s3_class(ui, "shiny.tag.list")
  expect_true(length(ui) > 0)
})

test_that("ui_questions() handles multiple components", {
  skip_if_no_data()
  q <- do.call(prep_questions, test_inputs(c("model_fit", "model_summary")))

  expect_silent(ui <- ui_questions(q))
  expect_s3_class(ui, "shiny.tag.list")
  expect_true(any(stringr::str_detect(unlist(ui), "model_fit")))
  expect_true(any(stringr::str_detect(unlist(ui), "model_summary")))
})
