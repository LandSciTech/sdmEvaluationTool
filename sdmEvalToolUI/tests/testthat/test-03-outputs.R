test_that("copy_output()", {
  expect_silent(o <- copy_output(id = "output_1"))
  expect_s3_class(o, "shiny.tag.list")
})
