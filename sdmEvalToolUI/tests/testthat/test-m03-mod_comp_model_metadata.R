test_that("model_metadata_prep()", {
  skip_if_no_data()

  expect_silent(m <- model_metadata_prep("bam_v5_can71"))
  expect_s3_class(m, "data.frame")
})

test_that("model_metadata_table()", {
  skip_if_no_data()

  m <- model_metadata_prep("bam_v5_can71")
  expect_silent(tbl <- model_metadata_table(m))
  expect_s3_class(tbl, "reactable")
})


test_that("test_comp_model_metadata()", {
  # Don't run these tests on the CRAN build servers
  skip_on_cran()
  # If have problems, use this to troubleshoot errors
  #shinytest2::record_test(test_comp_model_metadata())

  app <- shinytest2::AppDriver$new(test_comp_model_metadata, name = "test")

  app$expect_values()
})
