test_that("prep_files()", {
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
})
