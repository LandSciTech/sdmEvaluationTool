#' Launch the SDM Evaluation Tool Shiny Application
#'
#' @param lang Character. Language of app; either `english` or `french`.
#' @param options List. Shiny app options (passed to `options` in
#' [shiny::shinyApp()].
#' @param tabs Character. List the tabs/pages that the UI should have.
#' @param user Character. User id. Placeholder for now, may be changed to use
#' authentication later.
#' @param ... Other arguments passed to [shiny::shinyApp()].
#'
#' @returns A Shiny app object. Launched in browser/viewer if interactive.
#'
#' @export
#' @examplesIf have_data()
#' sdm_tool()

sdm_tool <- function(
  lang = "english",
  options = list(host = "0.0.0.0", port = 8080),
  tabs = c(
    "overview",
    "predictions",
    "observations",
    "model",
    "predictors",
    "model_metadata",
    "summary"
  ),
  user = NULL,
  ...
) {
  # Pages - Names become pretty Tab names, values are ids used for navigation (input$sdm)
  page_options <- c(
    "overview" = "Index",
    "predictions" = "Predictions",
    "observations" = "Observations",
    "model" = "Model",
    "predictors" = "Predictors",
    "model_metadata" = "Model Metadata",
    "summary" = "Summary"
  )
  if (anyDuplicated(tabs) > 0) {
    stop("The `tabs` argument must not have duplicate values.")
  }
  tabs <- match.arg(tabs, names(page_options), several.ok = TRUE)
  page_options <- page_options[match(tabs, names(page_options))]

  # Set language
  # Note: setting lang globally might impact users outside of the current user session
  set_options(lang = lang)

  # Selections
  users <- app_users()
  materials <- app_materials()

  # UI --------------------------------------
  pages_ui <- purrr::imap(page_options, \(title, id) {
    get(paste0("mod_page_", id, "_ui"))(title = title, id = id)
  }) |>
    unname()

  ui <- tagList(
    div(
      uiOutput("usecase"),
      style = "text-align:center;",
      class = "alert bg-sdm",
      role = "alert"
    ),
    bslib::page_navbar(
      id = "sdm", # Used for navigation, input$sdm
      title = "SDM Tool",
      theme = sdm_theme(),
      sidebar = mod_utils_details_ui(),
      gap = 0,
      padding = 0,
      header = shinyjs::useShinyjs(),
      !!!pages_ui,
      nav_item(div(
        id = "div_id",
        selectInput(
          "user_role",
          width = 130,
          label = NULL,
          choices = c("Role" = "")
        )
      )),
      nav_spacer(),
      !!!sdm_inputs(users),
      nav_item(actionButton(
        "abandon",
        title = "Abandon/Resume Review",
        label = NULL,
        icon = bsicons::bs_icon(
          "x-lg",
          size = "1em",
          title = "Abandon/Resume Review"
        ),
        class = "btn-sm btn-abandon"
      ))
    ),
    nav_item(actionButton(
      "glossary",
      label = NULL,
      icon = bsicons::bs_icon("question-circle", title = "Toggle Glossary"),
      class = "btn-mini btn-rnd btn-glossary"
    ))
  )

  server <- function(input, output, session) {
    # Setup ---------------------------------------------

    # Placeholder reactiveVals until overview created
    # Will be updated by overview module when button clicked to select evaluation
    overview_inputs <- reactiveVal(NULL)
    overview_update <- reactiveVal(0)

    # Holds inputs to be updated by sdm_update_selector()
    update_inputs <- reactiveVal(NULL)

    # Marker to note if evaluation has been abandoned (species or model)
    abandoned <- reactiveVal(FALSE)

    # Holds ids of pages with TRUE/FALSE for unsaved answers
    unsaved <- reactiveVal(purrr::map_lgl(page_options, \(x) FALSE))

    # Updates Deployment/Model/Species selectors
    #  created locally in order to have access to input & session directly
    sdm_update_selector <- function(
      type,
      required,
      choices,
      id = paste0(type, "_id")
    ) {
      shinyjs::toggleState(
        id,
        condition = all(purrr::map_lgl(required, \(r) {
          isTruthy(input[[r]])
        }))
      )

      sapply(required, \(r) req(input[[r]]))

      if (length(choices) > 1) {
        choices <- c("", choices)
        names(choices)[1] <- glue::glue("Select a {type}")
      }

      isolate({
        if (!is.null(update_inputs()) && id %in% names(update_inputs())) {
          selected <- update_inputs()[id]
        } else if (isTruthy(input[[id]]) && input[[id]] %in% choices) {
          selected <- input[[id]]
        } else {
          selected <- NULL
        }
      })

      updateSelectInput(
        session,
        id,
        choices = choices,
        selected = selected
      )
    }

    # User ID and roles --------------------------------
    user_id <- reactive({
      # TODO: Currently this uses the user_id argument of sdm_tool()
      #   In future may get user_id from somewhere else
      user
    })

    user_roles <- reactive({
      dplyr::filter(
        users,
        .data$user_id == user_id(),
        .data$user_roles != "admin"
      ) |>
        dplyr::pull(.data$user_roles) |>
        unique()
    })

    user_admin <- reactive({
      a <- users$user_roles[users$user_id == user_id()]
      any(a == "admin")
    })

    # Glossary -----------------------------------------
    # Create Glossary Modal when use clicks on (?) button
    observe({
      tab <- system.file("glossary.csv", package = "sdmEvalToolUI") |>
        sdmEvalToolCore::read_file()
      tab$description <- if (lang == "english") {
        tab$english
      } else {
        tab$french
      }
      # colnames(tab) <- tools::toTitleCase(colnames(tab))
      tab <- reactable::reactable(
        tab[, c("topic", "description")],
        searchable = TRUE,
        columns = list(
          topic = reactable::colDef(
            name = "Topic",
            minWidth = 100
          ),
          description = reactable::colDef(
            name = "Description",
            minWidth = 200
          )
        )
      )

      showModal(as_fill_carrier(
        modalDialog(
          size = "xl",
          title = "Glossary",
          reactable::renderReactable(tab),
          easyClose = TRUE
        )
      ))
    }) |>
      bindEvent(input$glossary)

    # Abandon Review -----------------------------------
    # CLEANUP: Similar to mod_utils_evaluations_server... could be merged?
    observe({
      # Disable Abandon review if no review selected
      shinyjs::toggleState(
        "abandon",
        condition = isTruthy(input$deployment_id) &
          isTruthy(input$model_id)
      )
    })

    observe({
      # Highlight button if already abandoned

      shinyjs::toggleCssClass(
        "abandon",
        class = "btn-danger",
        condition = abandoned()
      )
    })

    questions_init <- reactive({
      overview_update() # Trigger on an overview_update() to ensure questions are up-to-date after saving.
      q <- prep_questions(
        "app",
        input$deployment_id,
        input$model_id,
        input$species_id,
        user_id = user_id()
      )
    })

    # Create Modals for Abandon
    observe({
      ui <- ui_questions(questions_init(), width = "100%")

      # Update button label as needed
      id <- questions_init()$question_id[1]
      observe({
        if (is.null(input[[id]])) {
          updateActionButton(
            inputId = session$ns("save"),
            label = "Make a selection",
            disabled = TRUE
          )
        } else if (input[[id]] == "Yes") {
          updateActionButton(
            inputId = session$ns("save"),
            label = "Yes, abandon review",
            disabled = FALSE
          )
        } else if (input[[id]] == "No") {
          updateActionButton(
            inputId = session$ns("save"),
            label = "No, continue with review",
            disabled = FALSE
          )
        }
      }) |>
        bindEvent(input[[id]])

      # Create Modal
      showModal(as_fill_carrier(modalDialog(
        size = "l",
        title = "Abandon Review?",
        card(ui), #page_fillable(card(card_body(as_fill_item(), ui))),
        footer = tagList(
          actionButton("save", "Make a selection", disabled = TRUE),
          modalButton("Cancel")
        )
      )))
    }) |>
      bindEvent(input$abandon)

    # Save the Abandon questions
    observe({
      save_evaluations(
        questions = questions_init(),
        reactiveValuesToList(input),
        user_id = user_id()
      )

      removeModal()
      # nav_select("sdm", "overview") # IDEA: Go back to Overview?
      overview_update(overview_update() + 1)
    }) |>
      bindEvent(input$save)

    # Navbar inputs -------------------------------------------

    # User Role
    observe({
      req(user_id(), user_roles())

      choices <- rlang::set_names(user_roles(), fmt_pretty(user_roles()))
      if (length(choices) > 1) {
        choices <- c("", choices)
        names(choices)[1] <- glue::glue("Select a role")
      }

      updateSelectInput(session, "user_role", choices = choices)
    })

    observe({
      sdm_update_selector(
        type = "deployment",
        required = "user_role",
        choices = {
          users |>
            dplyr::filter(
              .data$user_id == user_id(),
              .data$user_roles == input$user_role
            ) |>
            dplyr::left_join(materials, by = "deployment_id") |>
            named_ids(match = "deployment")
        }
      )
    })

    observe({
      sdm_update_selector(
        type = "model",
        required = "deployment_id",
        choices = {
          dplyr::filter(
            materials,
            .data$deployment_id == input$deployment_id
          ) |>
            named_ids(match = "model")
        }
      )
    })

    observe({
      sdm_update_selector(
        type = "species",
        required = "model_id",
        choices = {
          dplyr::filter(
            materials,
            .data$deployment_id == input$deployment_id,
            .data$model_id == input$model_id,
            !is.na(species_id) # Avoid "Model" in species input choices
          ) |>
            fmt_species() |>
            named_ids(name = "display", match = "species")
        }
      )
    })

    # Update by button clicks from Overview table
    observe({
      loop <- TRUE
      all <- overview_inputs()
      while (loop) {
        v <- all[1]
        i <- names(v)

        # If change needs to be made, make the first one, then allow the
        # sdm_update_selector() to make the rest.
        # If no change, loop through to the next input to update
        # When finished, put remaining (unchanged) inputs in the reactiveVal
        # update_inputs() for sdm_update_selector() to call on.
        if (is.null(input[[i]]) || input[[i]] == "" || input[[i]] != v) {
          updateSelectInput(
            session,
            inputId = i,
            selected = v
          )

          # If selected model alone...
          if (i == "model_id" && !"species_id" %in% names(all)) {
            updateSelectInput(
              session,
              inputId = "species_id",
              selected = NULL
            )
          }

          loop <- FALSE
          update_inputs(all[-1])
        }
        all <- all[-1]
      }
    }) |>
      bindEvent(overview_inputs(), ignoreInit = TRUE)

    # Deployment details -------------------------------------------------------
    details <- reactive({
      validate_ids(deployment_id = input$deployment_id)
      con <- withr::local_db_connection(db_connect())
      d <- dplyr::tbl(con, "deployments") |>
        dplyr::collect() |>
        dplyr::filter(.data$deployment_id == input$deployment_id)

      d
    })

    # Banner ---------------------------------------
    output$usecase <- renderUI({
      req(user_id())

      name <- users$user_name[users$user_id == user_id()] |> unique()
      greet <- tagList("Hi", strong(name))
      if (user_admin()) {
        greet <- tagList(
          greet,
          tooltip(
            icon("crown", a11y = "sem", title = "You are an Admin"),
            "You are an Admin"
          )
        )
      }

      if (!isTruthy(input$user_role)) {
        out <- "- Please select a Role"
      } else if (!isTruthy(input$deployment_id)) {
        out <- "- Please select a Deployment"
      } else if (is_ready(details)) {
        d <- details()
        d <- jsonlite::fromJSON(d$deployment_settings)
        d <- d$use_case[[stringr::str_which(lang(), names(d$use_case))]]
        d <- unlist(d)
        out <- tagList(
          "- You are evaluating models in the context of ",
          strong(d)
        )
      }

      tagList(greet, out)
    })

    # Mark unsaved -----------------------------------------------------------------

    observe({
      # If abandoned Mark all saved
      req(abandoned())
      u <- purrr::map_lgl(page_options, \(x) FALSE)
      unsaved(u)
    }) |>
      bindEvent(abandoned(), ignoreInit = TRUE)

    observe({
      purrr::iwalk(unsaved(), \(v, id) {
        shinyjs::toggleCssClass(
          selector = paste0(".nav-link[data-value='", id, "']"),
          class = "answer-changed",
          condition = v
        )
      })
    }) |>
      bindEvent(unsaved(), ignoreInit = TRUE)

    # Modules --------------------------------

    # User-related options
    opts <- list(
      "user_id" = user_id, # Reactive
      "user_role" = reactive(input$user_role),
      "user_admin" = user_admin # Reactive
    )

    # - Define overview separately to specify overview_inputs
    mod_utils_details_server(details = details)

    mod_page_overview_server(
      deployment_id = reactive(input$deployment_id),
      model_id = reactive(input$model_id),
      species_id = reactive(input$species_id),
      opts = opts,
      overview_inputs = overview_inputs,
      overview_update = overview_update,
      abandoned = abandoned,
      unsaved = unsaved
    )

    pages_server <- purrr::map(names(page_options)[-1], \(id) {
      get(paste0("mod_page_", id, "_server"))
    })

    for (t in pages_server) {
      t(
        deployment_id = reactive(input$deployment_id),
        model_id = reactive(input$model_id),
        species_id = reactive(input$species_id),
        opts = opts,
        abandoned = abandoned,
        unsaved = unsaved
      )
    }
  }

  shiny::shinyApp(ui, server, options = options, ...)
}

#' Theme for bslib
#'
#' @returns bslib theme
#'
#' @export
#' @examples
#' sdm_theme()

sdm_theme <- function() {
  bs_theme(
    `primary` = "#2E5266",
    `theme-colors` = "('sdm': #d8ded8)",
    `success` = "#476146", # For the secondary questions
    `species-colour` = "#2E5266",
    `model-colour` = "#DC851F",
    `enable-rounded` = FALSE,
    `modal-header-padding` = "1rem",
    `alert-padding-x` = "0.3rem",
    `alert-padding-y` = "0.3rem"
  ) |>

    # General styling
    bs_add_rules(
      "h5 {
         padding: 0;
         margin: 0;
         line-spacing: 0;
       }

       /* Validate/need messages */
      .shiny-output-error {
        padding-left:0.5em;
       }

       /* Modal formatting */
       .modal-body, .modal-footer {
         padding: 1rem;
       }

       
       /* Cards within Cards (e.g. spatial maps over selection tables) */
       .sub-card > .card-body {
         padding: 0 !important;
       }
       div:has(> .sub-card) {
         gap: 0 !important;
         padding: 0px !important;
       }
       .card.sub-card {
         border: 0 !important;
       }

       /* Cards within Tabs (e.g., observations map) */
       .sdm-tab-pane .card {
         border: 0 !important;
       }

       /* Remove gaps between cards and page */
       .main.bslib-gap-spacing {
         padding: 0 !important;
         padding-left: 20px !important;
       }
      /* Even out the spacing as the Overview page doesn't have an evaluation tab */
       .main.bslib-gap-spacing [data-value='overview']{
         padding: 0 !important;
         padding-left: 20px !important;
       }"
    ) |>

    # Species- vs. Model-level differentiation
    bs_add_rules(
      "a.nav-link > .sdm-species-lvl {
         text-shadow: $species-colour 0 0 2px;
       }
       a.nav-link > .sdm-model-lvl {
         text-shadow: $model-colour 0 0 2px;
       }"
    ) |>

    # Evaluations
    bs_add_rules(
      ".sub-question {
         padding-left: 15px;
         padding-top: 5px;
         border-radius: 5px;
         background-color: #e2eae0;
       }
       /* For last-modified note */
       .corner {
         position: relative;
         right: 0;
         top: -25px;
         margin-bottom: -25px;
         margin-right: 25px;
         display: block;
         text-align: right;     
         font-size: 90%;   
       }
       
       /* Unsaved changes indicator */
       .answer-changed {
         position: relative;
       }
       .answer-changed::before {
         content: '\u25CF';
         color: #ef4444;
         font-size: 1em;
         margin-right: 6px;
        }

        label.answer-changed {
        padding-left: 15px;
        text-indent: -15px;
        }
   
        .answer-changed + input,
        .answer-changed + div input,
        .answer-changed + div .selectize-input,
        .answer-changed + div textarea {
           background-color: #fef2f2;
           transition: all 0.2s ease;
        }
        .answer-changed + input:focus,
        .answer-changed + div .selectize-input.focus {
           box-shadow: 0 0 0 0.2rem rgba(239, 68, 68, 0.15);
        }"
    ) |>

    # Buttons
    bs_add_rules(
      "/* Overview selection buttons */
       .btn-species {
         color: white;
         background-color: $species-colour;
         border-color: $species-colour;
         width: 150px;
       } 
       .btn-model {
         color: white;
         background-color: $model-colour;
         border-color: $model-colour;
         width: 150px;
       }

       /* Abandon Evaluation Button */
       .btn-abandon {
        border-radius: 100px;
        /* trim space around button */
        margin-left: -0.25rem !important;
        margin-right: -0.5rem !important;
        /* Match margin of form items */
        margin-bottom: 1rem !important; 
       }

       .btn-abandon.btn-danger {
         background-color: $danger;
         color: white;
       }

       .btn-abandon.btn-danger:hover {
        background-color: $danger-border-subtle;
      }

       /* Glossary Button */
        .btn-glossary {
          position: fixed;
          bottom: 20px;
          right: 40px;
          z-index: 1000;
          font-size: 2em;
          color: grey;
        }
        .btn-glossary:hover {
          color: black;
          background-color: transparent;
        }
        /* Copy Button */
        .btn-copy {
          padding: 2px 5px 2px 5px;
        }

       /* Mini Button */
       .btn-mini {
         background-color: transparent;
         border: 0;
         margin: 0;
         padding: 2px 10px 2px 10px;
       }      
       .btn-refresh {
        color: $success;
        padding: 2px 8px 2px 8px;
       }

       .btn-rnd {
        border-radius: 50%;         
       }"
    ) |>

    # Leaflet maps
    bs_add_rules(
      "/* Allow Multiple legends (only legends in the bottom left corner) to go side by side */
       .leaflet-bottom.leaflet-left > .info.legend.leaflet-control {
         float: inherit !important;
         display: inline-block;
       }
       /* Fix selectize dropdown appearing below leaflet controls */
       .selectize-dropdown {
         z-index: 1001 !important;
    }"
    )
}

#' Create list of selector inputs
#'
#' @returns Shiny tagList.
#'
#' @noRd
#' @examples
#' sdm_inputs()

sdm_inputs <- function(users) {
  # IDEA: Add tool tips with model/deployment descriptions on hover?
  # Or other details somewhere?
  list(
    nav_item(
      div(
        id = "div_id",
        shinyjs::disabled(selectInput(
          "deployment_id",
          width = 250,
          label = NULL,
          choices = c("Deployment" = "")
        ))
      )
    ),
    nav_item(
      div(
        id = "div_id",
        shinyjs::disabled(selectInput(
          "model_id",
          width = 175,
          label = NULL,
          choices = c("Model" = "")
        ))
      )
    ),
    nav_item(
      div(
        id = "div_id",
        shinyjs::disabled(selectInput(
          "species_id",
          width = 350,
          label = NULL,
          choices = c("Species" = "")
        ))
      )
    )
  )
}

#' Get Users details
#'
#' @returns Data frame of user details
#'
#' @export
#' @examplesIf have_data()
#' app_users()

app_users <- function() {
  con <- withr::local_db_connection(db_connect())
  dplyr::tbl(con, "users") |>
    dplyr::select("user_id", "user_name") |>
    dplyr::left_join(dplyr::tbl(con, "access"), by = "user_id") |>
    dplyr::collect() |>
    dplyr::mutate(
      user_roles = stringr::str_split(.data$user_roles, ", ?")
    ) |>
    tidyr::unnest("user_roles") |>
    dplyr::filter(.data$user_roles != "commenter")
}

#' Get all materials available
#'
#' @returns Data frame of all materials available
#'
#' @export
#' @examplesIf have_data()
#' app_materials()

app_materials <- function() {
  con <- withr::local_db_connection(db_connect())
  db_read_deployment_materials(con) |>
    dplyr::select(
      "deployment_id",
      "deployment_name",
      "model_id",
      "model_name",
      "species_id",
      "scientific_name",
      "english_name",
      "french_name"
    )
}
