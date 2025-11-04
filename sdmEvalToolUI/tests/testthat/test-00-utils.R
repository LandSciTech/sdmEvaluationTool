test_that("prep_files()", {
  withr::with_options(
    list(
      "sdmevaltool_options" = list(
        base = testthat::test_path("../../../misc/base")
      )
    ),
    {
      skip_if_not(dir.exists(sdmEvalToolCore::sdmevaltool_options()$base))
      for (c in sdmEvalToolCore::components$component) {
        #TODO: Update which we have/don't have as it changes
        if (c %in% c("model_metadata", "predictor_raster")) {
          expect_error(
            prep_files(c, species_id = "BBWO", model_id = "bam_v5_can71"),
            "doesn't exist. Have you supplied the correct base path?"
          )
        } else {
          expect_silent(prep_files(
            c,
            species_id = "BBWO",
            model_id = "bam_v5_can71"
          ))
        }
      }
    }
  )
})
