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
        dplyr::filter(.data$type == "material", .data$component != "app") |>
        dplyr::pull(.data$component)

      for (c in comp) {
        #TODO: Update which we have/don't have as it changes
        if (c %in% "model_metadata") {
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

test_that("prep_questions()", {
  withr::with_options(
    list(
      "sdmevaltool_options" = list(
        base = testthat::test_path("../../../misc/base")
      )
    ),
    {
      skip_if_not(dir.exists(sdmevaltool_options()$base))

      d <- "deployment1"
      m <- "bam_v5_can71"
      sp <- "BBWO"

      # Return all questions
      expect_silent(q1 <- prep_questions(NULL, d, m, sp))

      # Return component specific questions
      expect_silent(q2 <- prep_questions("observations", d, m, sp))
      expect_silent(q3 <- prep_questions("model_fit", d, m))
      expect_silent(q4 <- prep_questions("model_summary", d, m))
      expect_silent(q5 <- prep_questions(c("model_summary", "model_fit"), d, m))
      expect_silent(q6 <- prep_questions("predictor_raster", d, m))

      # Return default questions
      expect_silent(
        q7 <- prep_questions("observations", "deployment_test", m, sp)
      )

      for (q in list(q2, q3, q4, q5, q6, q7)) {
        expect_named(!!q, names(q1))
        expect_type(!!q[["values"]], "list")
        expect_type(!!q[["values"]][[1]], "character")
      }
    }
  )
})
