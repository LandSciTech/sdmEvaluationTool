mod_utils_evaluations_ui <- function(id = "evals", review_width = NULL) {
  review_width <- review_width %||% "35%"
  sidebar(
    width = review_width,
    position = "right",
    h3("Evaluations"),
    uiOutput(NS(id, "ui_questions"))
  )
}


mod_utils_evaluations_server <- function(
  id = "evaluations",
  spatial_type = "points",
  deployment_id,
  model_id,
  species_id,
  spatial_ids
) {
  stopifnot(is.reactive(deployment_id))
  stopifnot(is.reactive(model_id))
  stopifnot(is.reactive(species_id))
  stopifnot(is.reactive(spatial_ids))

  moduleServer(id, function(input, output, session) {
    # Evaluations ----------------------------------------------------
    questions_init <- reactive({
      #TODO: Read values from disk?
      prep_questions(
        component_id = "observations",
        deployment_id = deployment_id(),
        model_id = model_id(),
        species_id = species_id()
      )
    }) |>
      bindCache(deployment_id(), model_id(), species_id())

    output$ui_questions <- renderUI({
      req(spatial_ids())
      ui_questions(
        questions_init(),
        spatial_ids = spatial_ids(),
        spatial_type = spatial_type,
        session = session
      )
    })

    # TODO: Save values temporarily, so not lost if don't "Save Responses"?
    #   Highlight Save Responses in different colours if not saved
    #   Highlight Page tab in different colours if not saved
    #   Modal warns user when switching deployments/models/species if have unsaved work.

    questions <- reactive({
      #TODO: capture values as...JSON?
      #TODO: Save values to disk
      #TODO: Warn user if overwriting?
      dplyr::mutate(
        questions_init(),
        evaluations = purrr::map(.data$id, \(q) rlang::set_names(input[[q]], q))
      )
    })

    questions_output <- reactive({
      questions()
    }) |>
      bindEvent(input$save)

    output$saved <- renderText({
      questions()$evaluations[1][[1]]
    })

    # Reactive values --------------------------
    show_clicked <- reactiveVal()

    # Server logic -----------------------------
    show_spatial_ids <- reactive({
      req(show_clicked())
      ids <- questions_init() |>
        dplyr::filter(id == stringr::str_remove(show_clicked(), "-show")) |>
        dplyr::mutate(
          id_spatial = purrr::map2(id, values, \(i, v) {
            paste0(i, "-", unlist(v))
          })
        ) |>
        dplyr::pull(id_spatial) |>
        unlist() |>
        sapply(\(x) input[[x]])

      rlang::set_names(ids, stringr::str_extract(names(ids), "[^-]*$"))
    })

    show_btn_ids <- reactive({
      dplyr::filter(questions_init(), type == "spatial") |>
        dplyr::pull(id) |>
        paste0("-show")
    })

    show_clicked_observe <- reactiveVal() # Store observers to create/destroy

    # If show button clicked, mark the last to happen in `show_clicked()`
    # These observes are created/destroyed when Evaluation questions change
    observe({
      # Destroy old
      purrr::walk(show_clicked_observe(), \(o) o$destroy())

      # Create new
      new_obs <- purrr::map(show_btn_ids(), \(i) {
        observe(show_clicked(rlang::set_names(i, input[[i]]))) |>
          bindEvent(input[[i]])
      })

      show_clicked_observe(new_obs)
    }) |>
      bindEvent(questions_init()) # Only react if we have a new set of questions

    # Return --------------------------------------------------------
    list(
      "show_spatial_ids" = show_spatial_ids,
      "show_clicked" = show_clicked
    )
  })
}
