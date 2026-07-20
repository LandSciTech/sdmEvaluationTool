test_that("obs_prep()", {
  skip_if_no_data()
  expect_silent(o <- obs_prep(model_id = "bam_v5_can71", species_id = "BBWO"))
  expect_s3_class(o, "data.frame")
})

test_that("obs_prep_points()", {
  skip_if_no_data()
  o <- obs_prep(model_id = "bam_v5_can71", species_id = "BBWO")

  expect_silent(op <- obs_prep_points(o))
  expect_s3_class(op, "data.frame")
  expect_s3_class(op, "sf")
})

test_that("obs_prep_raster()", {
  skip_if_no_data()
  o <- obs_prep(model_id = "bam_v5_can71", species_id = "BBWO")
  r <- prep_materials(
    "spatial_prediction",
    model_id = "bam_v5_can71",
    species_id = "BBWO"
  )

  expect_silent(or <- obs_prep_raster(o, r))
  expect_s4_class(or, "SpatRaster")
})

test_that("obs_map_points()", {
  skip_if_no_data()
  o <- obs_prep(model_id = "bam_v5_can71", species_id = "BBWO")
  expect_silent(m <- obs_map_points(o))
  expect_s3_class(m, "leaflet")
})

test_that("obs_map_raster()", {
  skip_if_no_data()
  o <- obs_prep(model_id = "bam_v5_can71", species_id = "BBWO")
  r <- prep_materials(
    "spatial_prediction",
    model_id = "bam_v5_can71",
    species_id = "BBWO"
  )
  rast <- obs_prep_raster(o, r)

  expect_silent(m <- obs_map_raster(rast))
  expect_s3_class(m, "leaflet")
})

test_that("test_comp_observations()", {
  # Don't run these tests on the CRAN build servers
  skip_if_no_data()
  # If have problems, use this to troubleshoot errors
  #shinytest2::record_test(test_comp_observations())

  app <- shinytest2::AppDriver$new(test_comp_observations, name = "test")
  app$set_window_size(width = 1619, height = 993)
  app$wait_for_idle()
  app$expect_values()
  app$stop()
})
