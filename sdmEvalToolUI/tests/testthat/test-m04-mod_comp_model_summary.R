test_that("model_summary_prep()", {
  skip_if_no_data()

  expect_silent(
    s <- model_summary_prep(model_id = "bam_v5_can71", species_id = "BBWO")
  )
  expect_s3_class(s, "data.frame")
})

test_that("model_metadata_table()", {
  skip_if_no_data()

  s <- model_summary_prep(model_id = "bam_v5_can71", species_id = "BBWO")
  expect_silent(tbl <- model_summary_table(s))
  expect_s3_class(tbl, "reactable")
})


test_that("test_comp_model_summary()", {
  # Don't run these tests on the CRAN build servers
  skip_on_cran()
  # If have problems, use this to troubleshoot errors
  #shinytest2::record_test(test_comp_model_summary())

  app <- shinytest2::AppDriver$new(test_comp_model_summary, name = "test")

  app$expect_values()
})
