mod_utils_evaluations_ui <- function(id = "evaluations", review_width = NULL) {
  review_width <- review_width %||% "35%"
  sidebar(
    width = review_width,
    position = "right",
    layout_column_wrap(
      width = NULL,
      fill = FALSE,
      style = css(grid_template_columns = "3fr 1fr"),
      div(
        h3("Evaluations"),
        span(
          span("", class = "answer-changed"),
          "Indicates a modified response (not yet saved)"
        )
      ),
      uiOutput(NS(id, "modified"), class = "corner")
    ),
    uiOutput(NS(id, "ui_questions")),
    actionButton(inputId = NS(id, "save"), label = "Save Responses")
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
  opts
) {
  stopifnot(is.reactive(deployment_id))
  stopifnot(is.reactive(model_id))
  stopifnot(is.reactive(species_id))
  stopifnot(is.reactive(spatial_ids))
  purrr::walk(opts, \(o) stopifnot(is.reactive(o)))

  moduleServer(id, function(input, output, session) {
    # Setup ----------------------------------------------------------
    show_clicked <- reactiveVal()
    saved <- reactiveVal(0)
    spatial_ready <- reactiveVal(FALSE)
    ns <- session$ns

    # Evaluations ----------------------------------------------------
    questions_init <- reactive({
      req(opts$user_id(), deployment_id(), model_id(), species_id())

      saved() # Also trigger refresh if values are saved

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
          question_id == stringr::str_remove(show_clicked(), "-show")
        ) |>
        dplyr::mutate(
          id_spatial = purrr::map2(question_id, values, \(i, v) {
            paste0(i, "-", value_to_input(unlist(v)))
          })
        ) |>
        dplyr::pull(id_spatial) |>
        unlist() |>
        sapply(\(x) input[[x]])

      nms <- names(spatial_ids) |>
        stringr::str_extract("[^-]*$") |>
        pretty()

      rlang::set_names(spatial_ids, nms)
    })

    show_btn_ids <- reactive({
      dplyr::filter(questions_init(), type == "spatial") |>
        dplyr::pull(question_id) |>
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

    # Save button -------------------------------------------

    observe({
      req(answers_changed())

      chg <- any(unlist(answers_changed()))

      if (!chg) {
        updateActionButton(
          inputId = "save",
          label = "No Changes to Save",
          disabled = TRUE
        )
      } else {
        updateActionButton(
          inputId = "save",
          label = "Save Responses",
          disabled = FALSE
        )
      }
      shinyjs::toggleClass("save", class = "btn-success", condition = chg)
    })

    # Return --------------------------------------------------------
    list(
      "show_spatial_ids" = show_spatial_ids,
      "show_clicked" = show_clicked
    )
  })
}
