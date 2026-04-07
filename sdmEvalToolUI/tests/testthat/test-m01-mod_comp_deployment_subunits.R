test_that("deployment_subunits_prep()", {
  skip_if_no_data()

  expect_silent(s <- deployment_subunits_prep(deployment_id = "deployment1"))

  expect_s3_class(s, "sf")
  expect_true(nrow(s) > 0)
  expect_true("subunit_id" %in% names(s))
})


test_that("test_comp_deployment_subunits()", {
  # Don't run these tests on the CRAN build servers
  skip_if_no_data()
  #shinytest2::record_test(test_comp_deployment_subunits())

  app <- shinytest2::AppDriver$new(test_comp_deployment_subunits, name = "test")
  app$set_window_size(width = 1619, height = 993)
  app$wait_for_idle()
  app$expect_values()
  app$stop()
})
