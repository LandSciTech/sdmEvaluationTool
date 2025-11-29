test_that("prep_materials()", {
  withr::with_options(
    list(
      "sdmevaltool_options" = list(
        base = testthat::test_path("../../../misc/base")
      )
    ),
    {
      skip_if_not(dir.exists(sdmevaltool_options()$base))
      comp <- sdmEvalToolCore::components |>
        dplyr::filter(.data$type == "material") |>
        dplyr::pull(.data$component)

      for (c in comp) {
        #TODO: Update which we have/don't have as it changes
        if (c %in% c("model_metadata", "predictor_raster")) {
          expect_error(
            prep_materials(c, species_id = "BBWO", model_id = "bam_v5_can71"),
            "doesn't exist. Have you supplied the correct base path?"
          )
        } else {
          expect_silent(prep_materials(
            c,
            species_id = "BBWO",
            model_id = "bam_v5_can71"
          ))
        }
      }
    }
  )
})

test_that("prep_deployments()", {
  withr::with_options(
    list(
      "sdmevaltool_options" = list(
        base = testthat::test_path("../../../misc/base")
      )
    ),
    {
      skip_if_not(dir.exists(sdmevaltool_options()$base))

      deps <- sdmEvalToolCore::components |>
        dplyr::filter(.data$type == "deployment") |>
        dplyr::pull(.data$component)

      for (d in deps) {
        if (d %in% "deployment_subunits") {
          expect_error(prep_deployments("deployment2", d), "correct base path?")
        } else {
          expect_silent(prep_deployments("deployment1", d))
          expect_silent(prep_deployments("deployment2", d))
        }
      }
    }
  )
})
