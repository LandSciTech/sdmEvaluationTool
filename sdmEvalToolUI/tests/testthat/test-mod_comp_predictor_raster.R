test_that("predictor_raster_prep()", {
  skip_if_no_data()

  expect_silent(r <- predictor_raster_prep("bam_v5_can71"))
  expect_s4_class(r, "SpatRaster")
})

test_that("predictor_raster_map()", {
  skip_if_no_data()

  r <- predictor_raster_prep("bam_v5_can71")
  expect_silent(m <- predictor_raster_map(r))
  expect_s3_class(m, "leaflet")

  expect_silent(m <- predictor_raster_map(r, "detectiondistance"))
  expect_s3_class(m, "leaflet")
})


test_that("test_comp_predictor_raster()", {
  # Don't run these tests on the CRAN build servers
  skip_if_no_data()
  # If have problems, use this to troubleshoot errors
  #shinytest2::record_test(test_comp_predictor_raster())

  app <- shinytest2::AppDriver$new(test_comp_predictor_raster, name = "test")
  app$set_window_size(width = 1619, height = 993)
  app$wait_for_idle()
  app$expect_values()
  app$stop()
})
