#' Launch the SDM Evaluation Tool Shiny Application
#'
#' @param lang Character. Language of app; either `english` or `french`.
#' @param options List. Shiny app options.
#'
#' @returns A Shiny app object
#'
#' @export
#' @examplesIf have_data()
#' sdm_tool()

sdm_tool <- function(lang = "english", options = list(port = 8080)) {
  # Pages - Names become pretty Tab names, values are ids used for navigation (input$sdm)
  page_options <- c(
    "overview" = "Overview",
    "predictions" = "Predictions",
    "observations" = "Observations",
    "model" = "Model",
    "predictors" = "Predictors",
    "model_metadata" = "Model Metadata"
  )

  # Set language
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
    bslib::page_navbar(
      id = "sdm", # Used for navigation, input$sdm
      title = "SDM Tool",
      theme = sdm_theme(),
      sidebar = mod_details_ui(),
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
      class = "btn-mini btn-glossary"
    ))
  )

  server <- function(input, output, session) {
    # Setup ---------------------------------------------
    # Placeholder reactiveVal until overview created
    # Will be updated by overview module when button clicked to select evaluation
    overview_inputs <- reactiveVal(NULL)
    overview_update <- reactiveVal(0)
    update_inputs <- reactiveVal(NULL) # Holds inputs to be updated by sdm_update_selector()
    abandoned <- reactiveVal(FALSE) # Marker to note if evaluation has been abandoned (species or model)

    sdm_update_selector <- function(
      type,
      required,
      choices,
      id = paste0(type, "_id")
    ) {
      shinyjs::toggleState(
        id,
        condition = all(purrr::map_lgl(required, \(r) isTruthy(input[[r]])))
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

      updateSelectInput(session, id, choices = choices, selected = selected)
    }

    # Glossary -----------------------------------------
    observe({
      # PLACEHOLDER
      deets <- list(
        "overview" = "This is the information regarding the overview",
        "predictions" = "This is how to evaluated predictions",
        "observations" = "Nothing here",
        "model" = "Model fit and summary information here",
        "predictors" = "These apply to the model as a whole",
        "model_metadata" = "Not yet implemented"
      )

      if (!all(names(deets) %in% names(page_options))) {
        stop("Some glossary terms do not match a tab", call. = FALSE)
      }

      showModal(as_fill_carrier(
        modalDialog(
          size = "l",
          title = "Glossary",
          card(
            card_header(page_options[input$sdm]),
            card_body(deets[[input$sdm]])
          ),
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

    observe({
      save_evaluations(
        questions = questions_init(),
        reactiveValuesToList(input),
        user_id = input$user_id
      )

      removeModal()
      # nav_select("sdm", "overview") # TODO: Go back to Overview?
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

    # Modules --------------------------------
    # - Define overview separately to specify overview_inputs
    mod_details_server(deployment_id = reactive(input$deployment_id))

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
      abandoned = abandoned
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
        abandoned = abandoned
      )
    }
  }

  shiny::shinyApp(ui, server, options = options)
}

sdm_theme <- function() {
  bs_theme(
    `species-colour` = "#2E5266",
    `model-colour` = "#DC851F",
    `enable-rounded` = FALSE,
    `modal-header-padding` = "1rem"
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
       
       .answer-changed::after {
         content: ' **';
         color: red;
         font-weight: bold;
       }
       .answer-changed + input,
       .answer-changed + input.form-control:focus,
       .answer-changed + div,
       .answer-changed + div input,
       .answer-changed + div .selectize-input,
       .answer-changed + div textarea {
         background: #a6a8cc4f;
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
  # TODO: Add tool tips with model/deployment descriptions on hover?
  # Or other details somewhere?
  list(
    nav_item(
      tags$style("#div_id .selectize-input:after{content: none;}"),
      div(
        id = "div_id",
        selectInput(
          "user_id",
          width = 150,
          label = NULL,
          choices = c("Select a user" = "", named_ids(users, match = "user"))
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
          width = 175,
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
    dplyr::mutate(user_roles = stringr::str_split(.data$user_roles, ", ?")) |>
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
