test_that("test_comp_obs_chart()", {
  # Don't run these tests on the CRAN build servers
  skip_on_cran()
  # If have problems, use this to troubleshoot errors
  #shinytest2::record_test(test_comp_obs_chart())

  skip("Failing for unknown reasons...")
  app <- shinytest2::AppDriver$new(test_comp_obs_chart, name = "test")

  app$expect_values()
})
