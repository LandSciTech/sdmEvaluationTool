test_that("model_fit_prep()", {
  skip_if_no_data()

  expect_silent(
    f <- model_fit_prep(model_ = "bam_v5_can71", species_id = "BBWO")
  )
  expect_s3_class(f, "data.frame")
})

test_that("model_fit_table()", {
  skip_if_no_data()

  f <- model_fit_prep(model_ = "bam_v5_can71", species_id = "BBWO")
  expect_silent(tbl <- model_fit_table(f))
  expect_s3_class(tbl, "reactable")
})


test_that("test_comp_model_fit()", {
  # Don't run these tests on the CRAN build servers
  skip_if_no_data()
  # If have problems, use this to troubleshoot errors
  #shinytest2::record_test(test_comp_model_fit())

  app <- shinytest2::AppDriver$new(test_comp_model_fit, name = "test")
  app$set_window_size(width = 1619, height = 993)
  app$wait_for_idle()
  app$expect_values()
  app$stop()
})
