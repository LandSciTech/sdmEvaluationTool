test_that("ui_questions()", {
  skip_if_no_data()

  q <- do.call(prep_questions, test_inputs())
  expect_silent(ui <- ui_questions(q))

  expect_s3_class(ui, "shiny.tag.list")
  expect_true(length(ui) > 0)

  # Expect some popovers
  q <- do.call(
    prep_questions,
    test_inputs(component = "model_summary", deployment_id = "deployment1")
  )
  expect_silent(ui <- ui_questions(q))
  expect_true("popover-contents" %in% unlist(ui))
})

test_that("ui_questions() handles multiple components", {
  skip_if_no_data()
  q <- do.call(prep_questions, test_inputs(c("model_fit", "model_summary")))

  expect_silent(ui <- ui_questions(q))
  expect_s3_class(ui, "shiny.tag.list")
  expect_true(any(stringr::str_detect(unlist(ui), "model_fit")))
  expect_true(any(stringr::str_detect(unlist(ui), "model_summary")))
})
