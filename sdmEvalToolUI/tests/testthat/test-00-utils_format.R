test_that("fmt_pretty()", {
  expect_equal(fmt_pretty("model_id"), "Model")
  expect_equal(fmt_pretty("deployment_id"), "Deployment")
  expect_equal(fmt_pretty("species_id"), "Species")
  expect_equal(fmt_pretty("id"), "")

  expect_equal(fmt_pretty("some-value"), "Some Value")
  expect_equal(fmt_pretty("mixed_value-here"), "Mixed Value Here")
  expect_equal(fmt_pretty("Already Formatted"), "Already Formatted")
  expect_equal(fmt_pretty("one_two-three_four"), "One Two Three Four")
})


test_that("fmt_time()", {
  # Test with current time
  expect_silent(t <- fmt_time(Sys.time()))
  expect_type(t, "character")
  expect_true(stringr::str_detect(t, "<br>"))

  # Test with specific time
  time <- as.POSIXct("2026-02-01 16:02")
  expect_silent(t <- fmt_time(time))
  expect_type(t, "character")
  expect_equal(t, "Sun, Feb 1 2026<br>4:02 PM")
})

test_that("fmt_species()", {
  df <- data.frame(
    species_id = c("BBWO", "ALL", NA),
    english_name = c("Black-backed Woodpecker", "NA", "NA"),
    scientific_name = c("Picidae picinae", "NA", "NA")
  )

  expect_silent(sp <- fmt_species(df))
  expect_true("species_display" %in% names(sp))
  expect_equal(
    sp$species_display,
    c(
      paste0(df$english_name[1], " (", df$scientific_name[1], ")"),
      "Model",
      "Model"
    )
  )
})
