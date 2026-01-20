#' Launch the SDM Evaluation Tool Shiny Application
#'
#' @returns A Shiny app object
#'
#' @export
#' @examplesIf have_data()
#' sdm_tool()

sdm_tool <- function(lang = "english", options = list(port = 8080)) {
  # TODO: define pages, etc. elsewhere
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

  # Pages
  pages_ui <- lapply(page_options, \(p) get(paste0("mod_page_", p, "_ui"))())
  pages_server <- lapply(page_options, \(p) {
    get(paste0("mod_page_", p, "_server"))
  })

  # Users
  # TODO: How do we know which user it is?
  # For now, see option set in zzz.R

  # Data
  prep_data() |> expand_list()

  ui <- bslib::page_navbar(
    title = "SDM Tool",
    theme = sdm_theme(),
    #sidebar = mod_sidebar_ui("sidebar"),
    gap = 0,
    padding = 0,
    shinyjs::useShinyjs(),
    !!!pages_ui,
    nav_spacer(),
    !!!sdm_inputs(),
    nav_item(actionButton(
      "abandon",
      label = NULL,
      icon = icon("x"),
      class = "btn-sm btn-danger"
    ))
  )

  server <- function(input, output, session) {
    output$user_role <- renderUI({
      if (!isTruthy(input$user_id)) {
        i <- shinyjs::disabled(selectInput(
          "user_role",
          width = 100,
          label = NULL,
          choices = c("Role" = "")
        ))
      } else {
        con <- withr::local_db_connection(db_connect())
        u <- input$user_id # Cannot put function user_id() in filter() before collection, lazy evaluation goes funny
        roles <- dplyr::tbl(con, "access") |>
          dplyr::filter(.data$user_id == .env$u) |>
          dplyr::pull(.data$user_roles) |>
          stringr::str_split(", ?") |>
          unlist() |>
          unique()
        choices <- rlang::set_names(roles, pretty(roles))

        i <- selectInput(
          "user_role",
          width = 100,
          label = NULL,
          choices = choices
        )
      }
      i
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


mod_sidebar_ui <- function(id) {
  sidebar(uiOutput(NS(id, "ui_selectors")))
}

mod_sidebar_server <- function(id, user_id, user_role) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    output$ui_selectors <- renderUI({
      con <- withr::local_db_connection(db_connect())

      tagList(
        #TODO: Add tool tips with model/deployment descriptions on hover? Or other details somewhere?
        selectInput(
          ns("deployment_id"),
          label = "Deployment",
          choices = c(
            "Select a deployment" = "",
            named_ids(dplyr::tbl(con, "deployments"))
          )
        ),
        selectInput(
          ns("model_id"),
          label = "Model",
          choices = c(
            "Select a model" = "",
            named_ids(dplyr::tbl(con, "models"))
          )
        ),
        selectInput(
          ns("species_id"),
          label = "Species",
          choices = c(
            "Select a species" = "",
            named_ids(
              fmt_species(
                dplyr::tbl(con, "species")
              ),
              name = "display"
            )
          )
        ),

        strong("Developer outputs"),
        uiOutput(ns("dev_outputs"))
      )
    })

    output$dev_outputs <- renderUI({
      # React and update to changes in these values, but only show the options
      user_id()
      user_role()
      input$deployment_id
      input$model_id
      input$species_id

      # Show current values
      glue::glue(
        "Deployment ID: {input$deployment_id}",
        "Model: {input$model_id}",
        "Species: {input$species_id}",
        "User: {user_id()} ({user_role()})",
        "Language: {lang()}",
        .sep = "<br>"
      ) |>
        htmltools::HTML()
    })

    list(
      deployment_id = reactive(input$deployment_id),
      model_id = reactive(input$model_id),
      species_id = reactive(input$species_id)
    )
  })
}

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

#' Title
#'
#' @returns
#'
#' @noRd
#' @examples
#' sdm_inputs()

sdm_inputs <- function() {
  con <- withr::local_db_connection(db_connect())

  list(
    nav_item(
      tags$style("#div_id .selectize-input:after{content: none;}"),
      div(
        id = "div_id",
        selectInput(
          "user_id",
          width = 150,
          label = NULL,
          choices = c(
            "Select a user" = "",
            named_ids(dplyr::tbl(con, "users"))
          )
        )
      )
    ),
    nav_item(div(id = "div_id", uiOutput("user_role"))),
    nav_item(
      div(
        id = "div_id",
        #TODO: Add tool tips with model/deployment descriptions on hover? Or other details somewhere?
        selectInput(
          "deployment_id",
          label = NULL,
          width = 200,
          choices = c(
            "Select a deployment" = "",
            named_ids(dplyr::tbl(con, "deployments"))
          )
        )
      )
    ),
    nav_item(
      div(
        id = "div_id",
        selectInput(
          "model_id",
          label = NULL,
          width = 200,
          choices = c(
            "Select a model" = "",
            named_ids(dplyr::tbl(con, "models"))
          )
        )
      )
    ),
    nav_item(
      div(
        id = "div_id",
        selectInput(
          "species_id",
          label = NULL,
          choices = c(
            "Select a species" = "",
            named_ids(
              fmt_species(dplyr::tbl(con, "species")),
              name = "display"
            )
          )
        )
      )
    )
  )
}
