test_that("coords_to_poly()", {
  # Imitate output of interactions$draw_new_feature$geometry from selections
  g <- list(coordinates = sf::st_coordinates(test_points()))

  expect_silent(poly <- coords_to_poly(g))
  expect_s3_class(poly, "sfc")
  expect_length(poly, 1)
})

test_that("feature_ids()", {
  # Imitate output of draw all features from selections
  f <- list(
    features = list(
      list(properties = list("_leaflet_id" = 1)),
      list(properties = list("_leaflet_id" = 2))
    )
  )

  expect_silent(ids <- feature_ids(f))
  expect_equal(ids, c(1, 2))
})

test_that("map_has_group()", {
  m <- base_map()
  expect_silent(g <- map_has_group(m, "Subunits"))
  expect_false(g)

  m <- base_map() |>
    add_markers(data = test_points())
  expect_silent(g <- map_has_group(m, "present"))
  expect_true(g)
})
