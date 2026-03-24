test_that("save_evaluations()", {
  skip("Wait until default dep questions are ready")

  withr::with_options(
    set_options(base = test_path("../../../misc/base")),
    {
      skip_if_not(dir.exists(sdmevaltool_options()$base))

      expect_silent(q <- test_questions())
      expect_silent(a <- test_input_evals(q))

      expect_output(save_evaluations(q, a, user_id = "testuser"))

      expect_silent(
        q <- prep_questions(
          "observations",
          "deployment_test",
          "bam_v5_can71",
          "BBW0",
          "testuser"
        ) |>
          dplyr::filter(order <= 3) |>
          evals_list()
      )

      expect_equal(a, q)
    }
  )
})
