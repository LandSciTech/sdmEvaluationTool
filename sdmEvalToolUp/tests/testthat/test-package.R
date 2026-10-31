test_that("the package namespace loads", {
  expect_true("sdmEvalToolUp" %in% loadedNamespaces())
})
