mod_utils_evaluations_ui <- function(
  id = "evaluations",
  review_width = NULL,
  level = "species"
) {
  review_width <- review_width %||% "35%"
  sidebar(
    width = review_width,
    position = "right",
    layout_column_wrap(
      width = NULL,
      fill = FALSE,
      style = css(grid_template_columns = "2fr 1fr"),
      h3("Evaluations"),
      uiOutput(NS(id, "modified"), class = "corner")
    ),
    div(
      if (level == "model") {
        strong("Note: Responses apply to Model across all Species", br())
      },
      span(
        span("", class = "answer-changed"),
        "Modified (unsaved) response",
        style = "font-size: 90%"
      ),
      style = "margin-top: -15px;"
    ),
    uiOutput(NS(id, "ui_questions")),
    layout_column_wrap(
      actionButton(inputId = NS(id, "save"), label = "Save Responses"),
      actionButton(inputId = NS(id, "reset"), label = "Reset Responses")
    )
  )
}


mod_utils_evaluations_server <- function(
  id = "evaluations",
  spatial_type = "points",
  component_id,
  deployment_id,
  model_id,
  species_id,
  spatial_ids = reactive(NULL),
  opts,
  abandoned,
  unsaved
) {
  stopifnot(is.reactive(deployment_id))
  stopifnot(is.reactive(model_id))
  stopifnot(is.reactive(species_id))
  stopifnot(is.reactive(spatial_ids))
  stopifnot(is.reactive(abandoned)) # reactiveVal
  stopifnot(is.reactive(unsaved)) # reactiveVal

  purrr::walk(opts, \(o) stopifnot(is.reactive(o)))

  moduleServer(id, function(input, output, session) {
    # Setup ----------------------------------------------------------
    show_clicked <- reactiveVal()
    saved <- reactiveVal(0)
    spatial_ready <- reactiveVal(FALSE)
    ns <- session$ns

    # Evaluations ----------------------------------------------------
    questions_init <- reactive({
      req(
        opts$user_id(),
        deployment_id(),
        model_id(),
        species_id(),
        !abandoned()
      )

      # Also trigger refresh if values are saved or reset
      saved()
      input$reset

      # Get Questions and any existing Evaluations
      q <- prep_questions(
        component_id = component_id,
        deployment_id = deployment_id(),
        model_id = model_id(),
        species_id = species_id(),
        user_id = opts$user_id()
      )

      # If no spatial, it's ready now
      if (!any(q$type %in% "spatial")) {
        spatial_ready(TRUE)
      }

      q
    })

    # Questions UI ---------------------------------------------------------

    output$ui_questions <- renderUI({
      validate(need(
        !abandoned(),
        "This evaluation has been abandoned. To resume, click on the Red 'X' in the upper right corner and modify your response. "
      ))

      req(questions_init())

      ui_questions(
        questions_init(),
        spatial_type = spatial_type
      )
    })

    # Add server side processing for inputs that pre-list the spatial ids
    observe({
      req(input$ready, spatial_ids(), questions_init())

      spatial_ready(TRUE)
      ui_questions_update(
        questions_init(),
        spatial_ids = spatial_ids()
      )
    })

    # TODO: Save values temporarily, so not lost if don't "Save Responses"?
    #   Highlight Save Responses in different colours if not saved
    #   Highlight Page tab in different colours if not saved
    #   Modal warns user when switching deployments/models/species if have unsaved work.

    # Changes ------------------------
    # Reactive which holds currently answered questions
    # If the same as questions_init(), no change, else answered
    answers_changed <- reactive({
      req(questions_init(), input$ready, spatial_ready())
      q <- evals_list(questions_init())
      r <- sapply(names(q), \(qq) input[[qq]])

      chgs <- purrr::imap(q, \(qq, i) !identical_loose(qq, r[[i]]))

      chgs
    })

    observe({
      req(answers_changed())

      # Mark tab name as unsaved
      u <- unsaved()
      # Get parent session     # TODO: Is this fragile?
      id <- stringr::str_extract(session$ns(""), "^[^-]+")
      u[id] <- any(unlist(answers_changed()))
      unsaved(u)

      # Mark answers as changed and unsaved
      purrr::imap(answers_changed(), \(r, i) {
        shinyjs::toggleClass(
          paste0(i, "-label"),
          class = "answer-changed",
          condition = r
        )
      })
    })

    # Date last modified ---------------------------
    output$modified <- renderUI({
      req(!is.na(questions_init()$last_modified))
      tagList(
        em("Last modified"),
        br(),
        HTML(unique(questions_init()$last_modified))
      )
    })

    # Show Spatial IDs -----------------------------
    show_spatial_ids <- reactive({
      req(show_clicked())
      spatial_ids <- questions_init() |>
        dplyr::filter(
          .data$question_id == stringr::str_remove(show_clicked(), "-show")
        ) |>
        dplyr::mutate(
          id_spatial = purrr::map2(.data$question_id, .data$values, \(i, v) {
            paste0(i, "-", value_to_input(unlist(v)))
          })
        ) |>
        dplyr::pull(.data$id_spatial) |>
        unlist() |>
        sapply(\(x) input[[x]])

      nms <- names(spatial_ids) |>
        stringr::str_extract("[^-]*$") |>
        pretty()

      rlang::set_names(spatial_ids, nms)
    })

    show_btn_ids <- reactive({
      dplyr::filter(questions_init(), type == "spatial") |>
        dplyr::pull(.data$question_id) |>
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

    # Save evaluations ----------------------------------------------

    observe({
      # TODO: Warn user if overwriting?
      save_evaluations(
        questions = questions_init(),
        reactiveValuesToList(input),
        user_id = opts$user_id()
      )
      saved(saved() + 1)
    }) |>
      bindEvent(input$save)

    # Save/reset buttons -------------------------------------------

    observe({
      req(answers_changed())

      chg <- any(unlist(answers_changed()))

      if (!chg) {
        updateActionButton(
          inputId = "save",
          label = "No Changes to Save",
          disabled = TRUE
        )
        updateActionButton(
          inputId = "reset",
          label = "No Changes to Reset",
          disabled = TRUE
        )
      } else {
        updateActionButton(
          inputId = "save",
          label = "Save Responses",
          disabled = FALSE
        )
        updateActionButton(
          inputId = "reset",
          label = "Reset Responses",
          disabled = FALSE
        )
      }
      shinyjs::toggleClass("save", class = "btn-success", condition = chg)
      shinyjs::toggleClass("reset", class = "btn-warning", condition = chg)
    })

    # Return --------------------------------------------------------
    list(
      "show_spatial_ids" = show_spatial_ids,
      "show_clicked" = show_clicked
    )
  })
}
