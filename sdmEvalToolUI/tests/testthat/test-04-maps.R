test_that("base_map()", {
  expect_silent(m <- base_map())
  expect_s3_class(m, "leaflet")
  expect_s3_class(m, "htmlwidget")
})

test_that("add_subunits()", {
  skip_if_no_data()

  map <- base_map()
  subunits <- deployment_subunits_prep(deployment_id = "deployment1")

  expect_silent(m <- add_subunits(map, subunits))
  expect_s3_class(m, "leaflet")
  expect_s3_class(m, "htmlwidget")

  expect_silent(m <- add_subunits(map, subunits, opacity = 0.2))
  expect_s3_class(m, "leaflet")
  expect_s3_class(m, "htmlwidget")

  expect_silent(m <- add_subunits(map, subunits = NULL))
  expect_identical(m, map)
})

test_that("add_selected_subunits() adds colored polygons to map", {
  skip_if_no_data()

  map <- base_map()
  subunits <- deployment_subunits_prep(deployment_id = "deployment1")
  subunits$selected <- c(TRUE, TRUE, rep(FALSE, nrow(subunits) - 2))
  subunits$selected <- factor(subunits$selected)

  expect_silent(m <- add_selected_subunits(map, subunits, "selected"))
  expect_s3_class(m, "leaflet")
})

test_that("add_selected_subunits() NULL subunits", {
  map <- base_map()

  expect_silent(m <- add_selected_subunits(map, subunits = NULL))
  expect_identical(m, map)
})

test_that("add_raster() & add_control()", {
  raster <- template_spatial_prep()
  map <- base_map()

  expect_silent(
    m <- add_raster(
      map,
      raster,
      layer = "mean",
      name = "Mean",
      palette = "Spectral"
    )
  )
  expect_s3_class(m, "leaflet")
  expect_s3_class(m, "htmlwidget")

  expect_silent(m <- add_control(m))
  expect_s3_class(m, "leaflet")
  expect_s3_class(m, "htmlwidget")
})

test_that("add_markers() & add_control()", {
  map <- base_map()

  expect_silent(m <- add_markers(map, data = test_points()))
  expect_s3_class(m, "leaflet")
  expect_s3_class(m, "htmlwidget")

  expect_silent(m <- add_control(m))
  expect_s3_class(m, "leaflet")
  expect_s3_class(m, "htmlwidget")
})

test_that("add_selected_markers() & add_control()", {
  map <- base_map()

  expect_silent(m <- add_selected_markers(map, data = test_points()))
  expect_s3_class(m, "leaflet")
  expect_s3_class(m, "htmlwidget")

  expect_silent(m <- add_control(m))
  expect_s3_class(m, "leaflet")
  expect_s3_class(m, "htmlwidget")
})
