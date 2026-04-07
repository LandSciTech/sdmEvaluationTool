test_that("spatial_prediction_prep()", {
  skip_if_no_data()

  expect_silent(r <- spatial_prediction_prep("bam_v5_can71", "BBWO"))
  expect_s4_class(r, "SpatRaster")
})

test_that("spatial_prediction_map()", {
  skip_if_no_data()

  r <- spatial_prediction_prep("bam_v5_can71", "BBWO")
  expect_silent(m <- spatial_prediction_map(r))
  expect_s3_class(m, "leaflet")
})


test_that("test_comp_spatial_prediction()", {
  # Don't run these tests on the CRAN build servers
  skip_if_no_data()
  # If have problems, use this to troubleshoot errors
  #shinytest2::record_test(test_comp_spatial_prediction())

  app <- shinytest2::AppDriver$new(test_comp_spatial_prediction, name = "test")
  app$set_window_size(width = 1619, height = 993)
  app$wait_for_idle()
  app$expect_values()
  app$stop()
})
