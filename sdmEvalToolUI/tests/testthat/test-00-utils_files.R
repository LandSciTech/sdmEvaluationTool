expect_silent(
  components <- sdmEvalToolCore::components |>
    dplyr::filter(.data$type == "material", .data$component != "app") |>
    dplyr::pull(.data$component)
)

test_that("prep_materials()", {
  skip_if_no_data()

  for (c in components) {
    expect_silent(
      prep_materials(
        component_id = !!c,
        species_id = "BBWO",
        model_id = "bam_v5_can71"
      )
    )
  }
})

test_that("prep_materials() species", {
  skip_if_no_data()

  expect_error(
    prep_materials(
      component_id = "observations",
      model_id = "bam_v5_can71",
      species_id = ""
    ),
    "Please select a Species"
  )
})


test_that("prep_deployments() questions", {
  skip_if_no_data()

  for (d in c("deployment1", "deployment2")) {
    expect_silent(
      deps <- prep_deployments(
        deployment_id = d,
        deployment_type = "deployment_questions"
      )
    )
    expect_s3_class(deps, "data.frame")
    expect_true(nrow(deps) > 0)
    expect_true("component" %in% names(deps))
    expect_true("french" %in% names(deps))
  }
})

test_that("prep_deployments() subunits", {
  skip_if_no_data()

  for (d in c("deployment1", "deployment2")) {
    expect_silent(
      deps <- prep_deployments(
        deployment_id = d,
        deployment_type = "deployment_subunits"
      )
    )
    expect_s3_class(deps, "sf")
    expect_true(nrow(deps) > 0)
  }
})


test_that("prep_questions()", {
  skip_if_no_data()

  for (c in components) {
    expect_silent(
      q <- prep_questions(
        component_id = !!c,
        deployment_id = "deployment1",
        model_id = "bam_v5_can71",
        species_id = "BBWO"
      )
    )

    expect_s3_class(q, "data.frame")
    expect_true(nrow(q) > 0)
    expect_all_equal(q$component, !!c)
    expect_named(
      q,
      c(
        "component",
        "type",
        "order",
        "part",
        "label",
        "french",
        "values",
        "material_id",
        "question_id"
      )
    )
    expect_type(q[["values"]], "list")
    expect_type(q[["values"]][[1]], "character")
  }
})

test_that("prep_questions() 'ALL'", {
  skip_if_no_data()

  expect_silent(
    q <- prep_questions(
      component_id = "ALL",
      deployment_id = "deployment1",
      model_id = "bam_v5_can71",
      species_id = "BBWO"
    )
  )

  expect_s3_class(q, "data.frame")
  expect_true(nrow(q) > 0)
  expect_true(all(components %in% unique(q$component)))
})

test_that("prep_questions() model-level", {
  skip_if_no_data()

  expect_silent(
    prep_questions(
      component_id = "model_fit",
      deployment_id = "deployment1",
      model_id = "bam_v5_can71"
    )
  )
  expect_silent(
    prep_questions(
      component_id = "model_summary",
      deployment_id = "deployment1",
      model_id = "bam_v5_can71"
    )
  )
})

test_that("prep_questions() handles multiple component_ids", {
  skip_if_no_data()

  expect_silent(
    q <- prep_questions(
      component_id = c("model_summary", "model_fit"),
      deployment_id = "deployment1",
      model_id = "bam_v5_can71"
    )
  )

  expect_s3_class(q, "data.frame")
  expect_true(nrow(q) > 0)
  expect_true(all(q$component %in% c("model_summary", "model_fit")))
})

test_that("prep_questions() uses default questions unlisted deployments", {
  skip_if_no_data()

  expect_silent(
    q <- prep_questions(
      component_id = "observations",
      deployment_id = "foo",
      model_id = "bam_v5_can71",
      species_id = "BBWO"
    )
  )

  expect_s3_class(q, "data.frame")
  expect_true(nrow(q) > 0)
})

test_that("prep_questions() user evaluations", {
  skip_if_no_data()

  expect_silent(
    evals <- prep_questions(
      component_id = "observations",
      deployment_id = "deployment1",
      model_id = "bam_v5_can71",
      species_id = "BBWO",
      user_id = "testuser"
    )
  )

  expect_s3_class(evals, "data.frame")
  expect_true(nrow(evals) > 0)
  expect_all_true(
    c("response", "evaluation_create_user", "last_modified") %in% names(evals)
  )
})


test_that("prep_questions() creates question_id", {
  skip_if_no_data()

  t <- test_inputs()
  q <- do.call(prep_questions, t)

  expect_all_true(c("material_id", "question_id") %in% names(q))
  expect_all_true(stringr::str_detect(
    q$question_id,
    paste(t$deployment_id, t$model_id, t$species_id, t$component, sep = "_")
  ))
})

test_that("prep_questions() ALL/NA species", {
  skip_if_no_data()

  # These should treat missing/empty/ALL the same
  q1 <- prep_questions(
    component_id = "model_fit",
    deployment_id = "deployment1",
    model_id = "bam_v5_can71"
  )

  q2 <- prep_questions(
    component_id = "model_fit",
    deployment_id = "deployment1",
    model_id = "bam_v5_can71",
    species_id = "ALL"
  )

  expect_equal(nrow(q1), nrow(q2))
})
