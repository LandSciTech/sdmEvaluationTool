# Set data folder for testing
opts <- sdmevaltool_options(
  base = testthat::test_path("../../../misc/base")
)
cat("Using setup!")
withr::local_options(
  .new = list("sdmevaltool_options" = opts),
  .local_envir = testthat::teardown_env()
)
