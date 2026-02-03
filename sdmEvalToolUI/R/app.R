#' Launch the SDM Evaluation Tool Shiny Application
#'
#' @returns A Shiny app object
#'
#' @export
#' @examplesIf have_data()
#' sdm_tool()

sdm_tool <- function(lang = "english", options = list(port = 8080)) {
  page_options <- c(
    "overview",
    "predictions",
    "observations",
    "model",
    "predictors",
    "model_metadata"
  )

  # Set language
  set_options(lang = lang)

  # Selections
  users <- app_users()
  materials <- app_materials()

  # Data
  #prep_data() |> expand_list()

  # UI --------------------------------------
  pages_ui <- lapply(page_options, \(p) get(paste0("mod_page_", p, "_ui"))())
  ui <- bslib::page_navbar(
    title = "SDM Tool",
    theme = sdm_theme(),
    #sidebar = mod_sidebar_ui("sidebar"),
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
      class = "btn-sm btn-danger"
    ))
  )

  server <- function(input, output, session) {
    # Setup ---------------------------------------------
    # Placeholder reactiveVal until overview created
    # Will be updated by overview module when button clicked to select evaluation
    overview_inputs <- reactiveVal(NULL)

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
        if (isTruthy(input[[id]]) && input[[id]] %in% choices) {
          selected <- input[[id]]
        } else {
          selected <- NULL
        }
      })

      updateSelectInput(session, id, choices = choices, selected = selected)
    }

    observe({
      # Disable Abandon review if no review selected
      shinyjs::toggleState(
        "abandon",
        condition = isTruthy(input$deployment_id) &
          isTruthy(input$model_id) &
          isTruthy(input$species_id)
      )
    })

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
        required = c("deployment_id", "model_id"),
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
      purrr::iwalk(overview_inputs(), \(v, i) {
        # Wait until inputs have settled before applying species_id
        delay_ms <- dplyr::if_else(i != "species_id", 0, 200)
        shinyjs::delay(delay_ms, {
          updateSelectInput(session, inputId = i, selected = v)
        })
      })
    }) |>
      bindEvent(overview_inputs(), ignoreInit = TRUE)

    # Modules --------------------------------
    # - Define overview separately to specify overview_inputs
    mod_page_overview_server(
      deployment_id = reactive(input$deployment_id),
      model_id = reactive(input$model_id),
      species_id = reactive(input$species_id),
      opts = list(
        "user_id" = reactive(input$user_id),
        "user_role" = reactive(input$user_role)
      ),
      overview_inputs = overview_inputs
    )

    pages_server <- lapply(page_options[-1], \(p) {
      get(paste0("mod_page_", p, "_server"))
    })

    for (t in pages_server) {
      t(
        deployment_id = reactive(input$deployment_id),
        model_id = reactive(input$model_id),
        species_id = reactive(input$species_id),
        opts = list(
          "user_id" = reactive(input$user_id),
          "user_role" = reactive(input$user_role)
        )
      )
    }
  }

  shiny::shinyApp(ui, server, options = options)
}


# mod_sidebar_ui <- function(id) {
#   sidebar(uiOutput(NS(id, "ui_selectors")))
# }

# mod_sidebar_server <- function(id, user_id, user_role) {
#   moduleServer(id, function(input, output, session) {
#     ns <- session$ns

#     output$ui_selectors <- renderUI({
#       con <- withr::local_db_connection(db_connect())

#       tagList(
#         #TODO: Add tool tips with model/deployment descriptions on hover? Or other details somewhere?
#         selectInput(
#           ns("deployment_id"),
#           label = "Deployment",
#           choices = c(
#             "Select a deployment" = "",
#             named_ids(dplyr::tbl(con, "deployments"))
#           )
#         ),
#         selectInput(
#           ns("model_id"),
#           label = "Model",
#           choices = c(
#             "Select a model" = "",
#             named_ids(dplyr::tbl(con, "models"))
#           )
#         ),
#         selectInput(
#           ns("species_id"),
#           label = "Species",
#           choices = c(
#             "Select a species" = "",
#             named_ids(
#               fmt_species(
#                 dplyr::tbl(con, "species")
#               ),
#               name = "display"
#             )
#           )
#         ),

#         strong("Developer outputs"),
#         uiOutput(ns("dev_outputs"))
#       )
#     })

#     output$dev_outputs <- renderUI({
#       # React and update to changes in these values, but only show the options
#       user_id()
#       user_role()
#       input$deployment_id
#       input$model_id
#       input$species_id

#       # Show current values
#       glue::glue(
#         "Deployment ID: {input$deployment_id}",
#         "Model: {input$model_id}",
#         "Species: {input$species_id}",
#         "User: {user_id()} ({user_role()})",
#         "Language: {lang()}",
#         .sep = "<br>"
#       ) |>
#         htmltools::HTML()
#     })

#     list(
#       deployment_id = reactive(input$deployment_id),
#       model_id = reactive(input$model_id),
#       species_id = reactive(input$species_id)
#     )
#   })
# }

sdm_theme <- function() {
  bs_theme("card-border-radius" = "0") |>
    bs_add_rules(
      "
      /* Format sub questions */
      .sub-question {
        padding-left: 15px;
        padding-top: 5px;
        border-radius: 5px;
        background-color: #e2eae0;
      }
      /* Create a mini button (Copy button) */
      .btn-mini {
        background-color: transparent;
        border: 0;
        padding: 5px;
        margin: 0;
      }
      /* Create a small button (Nav buttons) */
      li:has(button.btn-sm) {
        margin-top: 3px !important;
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
      }
      
      .answer-changed::after {
        content: ' **';
        color: red;
        font-weight: bold;
      }

      /* Allow Multiple legends (only legends in the bottom left corner) to go side by side */
      .leaflet-bottom.leaflet-left > .info.legend.leaflet-control {
        float: inherit !important;
        display: inline-block;
      }
      /* Fix selectize dropdown appearing below leaflet controls */
        .selectize-dropdown {
          z-index: 1001 !important;
        }
      /* Remove gaps between cards and page */
        .main.bslib-gap-spacing {
          padding: 0 !important;
        }
    "
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
    dplyr::mutate(user_roles = stringr::str_split(user_roles, ", ?")) |>
    tidyr::unnest(user_roles) |>
    dplyr::filter(user_roles != "commenter")
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
