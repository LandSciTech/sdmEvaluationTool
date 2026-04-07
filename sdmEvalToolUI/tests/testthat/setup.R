library(shinytest2)

# Set data folder for testing
opts <- sdmevaltool_options()

sdmevaltool_options(
  base = testthat::test_path("../../../misc/base")
)

withr::defer(sdmevaltool_options(opts), envir = testthat::teardown_env())
