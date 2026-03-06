#' Launch the SDM Evaluation Tool Shiny Application
#'
#' @param lang Character. Language of app; either `english` or `french`.
#' @param options List. Shiny app options.
#' @param tabs Character. List the tabs that the UI should have.
#' @param ... Other arguments passed to [shiny::shinyApp()].
#'
#' @returns A Shiny app object
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
    "model_metadata"
  ),
  ...
) {
  # Pages - Names become pretty Tab names, values are ids used for navigation (input$sdm)
  page_options <- c(
    "overview" = "Overview",
    "predictions" = "Predictions",
    "observations" = "Observations",
    "model" = "Model",
    "predictors" = "Predictors",
    "model_metadata" = "Model Metadata"
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

  # Data
  #prep_data() |> expand_list()

  # UI --------------------------------------
  pages_ui <- purrr::imap(page_options, \(title, id) {
    get(paste0("mod_page_", id, "_ui"))(title = title, id = id)
  }) |>
    unname()

  ui <- tagList(
    div(
      uiOutput("usecase"),
      style = "text-align:center;",
      class = "alert alert-success",
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
      nav_spacer(),
      !!!sdm_inputs(users),
      nav_item(actionButton(
        "abandon",
        label = NULL,
        icon = icon("x"),
        class = "btn-sm btn-abandon"
      ))
    ),
    nav_item(actionButton(
      "glossary",
      label = NULL,
      icon = icon("circle-question", ),
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

    # Updates User/Role/Deployment/Model/Species selectors
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
          # card(card_header("Legend"), legend),
          # card(
          #     card_header(page_options[input$sdm]),
          #     card_body(deets[[input$sdm]])
          # ),
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
        user_id = input$user_id
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
        user_id = input$user_id
      )

      removeModal()
      # nav_select("sdm", "overview") # IDEA: Go back to Overview?
      overview_update(overview_update() + 1)
    }) |>
      bindEvent(input$save)

    # Navbar inputs -------------------------------------------
    observe({
      sdm_update_selector(
        type = "role",
        id = "user_role",
        required = "user_id",
        choices = {
          c <- users |>
            dplyr::filter(.data$user_id == input$user_id) |>
            dplyr::pull(.data$user_roles) |>
            unique()
          rlang::set_names(c, pretty(c))
        }
      )
    })

    observe({
      sdm_update_selector(
        type = "deployment",
        required = c("user_id", "user_role"),
        choices = {
          users |>
            dplyr::filter(
              .data$user_id == input$user_id,
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

    output$usecase <- renderUI({
      req(!is.null(details()))
      d <- details()
      d <- jsonlite::fromJSON(d$deployment_settings)
      usecase <- d$use_case[[stringr::str_which(lang(), names(d$use_case))]]
      tagList("Evaluating models in the context of ", strong(unlist(usecase)))
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
    # - Define overview separately to specify overview_inputs
    mod_utils_details_server(details = details)

    mod_page_overview_server(
      deployment_id = reactive(input$deployment_id),
      model_id = reactive(input$model_id),
      species_id = reactive(input$species_id),
      opts = list(
        "user_id" = reactive(input$user_id),
        "user_role" = reactive(input$user_role)
      ),
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
        opts = list(
          "user_id" = reactive(input$user_id),
          "user_role" = reactive(input$user_role)
        ),
        abandoned = abandoned,
        unsaved = unsaved
      )
    }
  }

  shiny::shinyApp(ui, server, options = options, ...)
}

sdm_theme <- function() {
  bs_theme(
    `species-colour` = "#2E5266",
    `model-colour` = "#DC851F",
    `enable-rounded` = FALSE,
    `modal-header-padding` = "1rem",
    `success` = "#476146",
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
       /* Modal formatting */
       .modal-body, .modal-footer {
         padding: 1rem;
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
       }
       li:has(button.btn-abandon) {
         margin-top: 3px !important;
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

       /* Mini Button (e.g. Copy) */
       .btn-mini {
         background-color: transparent;
         border: 0;
         padding: 2px 5px 2px 5px;
         margin: 0;
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
      tags$style(
        "#div_id .selectize-input:after{content: none;} .selectize-input{white-space:nowrap;}"
      ),
      div(
        id = "div_id",
        selectInput(
          "user_id",
          width = 140,
          label = NULL,
          choices = c(
            "Select a user" = "",
            named_ids(users, match = "user")
          )
        )
      )
    ),
    nav_item(div(
      id = "div_id",
      shinyjs::disabled(selectInput(
        "user_role",
        width = 100,
        label = NULL,
        choices = c("Role" = "")
      ))
    )),
    nav_item(
      div(
        id = "div_id",
        shinyjs::disabled(selectInput(
          "deployment_id",
          width = 180,
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
