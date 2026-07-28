test_that("expand_list()", {
  expect_false(exists("test1"))
  expect_false(exists("test2"))

  expect_silent(expand_list(list("test1" = "test", "test2" = "test")))

  expect_true(exists("test1"))
  expect_true(exists("test2"))
})

test_that("expand_dots()", {
  expect_false(exists("test1"))
  expect_false(exists("test2"))

  expect_silent(expand_dots("test1" = "test", "test2" = "test"))

  expect_true(exists("test1"))
  expect_true(exists("test2"))
})

test_that("lang()", {
  l <- lang()
  expect_type(l, "character")
  expect_length(l, 1)
  expect_true(l %in% c("english", "french"))
})

test_that

test_that("affirmative()", {
  # Standard type
  standard <- affirmative()
  expect_type(standard, "character")
  expect_true(all(
    standard %in% c("Extremely", "Very", "Moderately", "Slightly", "Yes")
  ))

  # Spatial type
  spatial <- affirmative("spatial")
  expect_type(spatial, "character")
  expect_true(all(
    spatial %in%
      c(
        "Very_biased",
        "Moderately_biased",
        "Very_undersampled",
        "Moderately_undersampled",
        "Over*_prediction",
        "Under*_prediction",
        "Uncertain_but_seems_inaccurate",
        "Comment",
        "Inaccurate",
        "Greater_than_expected",
        "Less_than_expected"
      )
  ))
})
