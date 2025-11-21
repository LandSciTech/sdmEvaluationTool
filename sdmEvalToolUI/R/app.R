#' Launch the SDM Evaluation Tool Shiny Application
#'
#' @returns A Shiny app object
#'
#' @export
#' @examplesIf have_data()
#' sdm_tool()

sdm_tool <- function() {
  # TODO: define pages, etc. elsewhere
  page_options <- c(
    "overview",
    "predictions",
    "observations",
    "model",
    "predictors",
    "model_metadata",
    "test"
  )

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
    sidebar = mod_sidebar_ui("sidebar"),
    !!!pages_ui
  )

  server <- function(input, output, session) {
    # Set session-specific options
    # TODO: is this the correct method?
    observe({
      set_options(
        "user_id" = vals$user_id(),
        "user_role" = vals$user_role(),
        "lang" = vals$lang()
      )
    })

    vals <- mod_sidebar_server(id = "sidebar")

    for (t in pages_server) {
      t(
        deployment_id = vals$deployment_id,
        model_id = vals$model_id,
        species_id = vals$species_id,
        user_id = vals$user_id,
        user_role = vals$user_role,
        tbl_models = tbl_models,
        tbl_species = tbl_species
      )
    }
  }

  shiny::shinyApp(ui, server, options = list(port = 8080))
}


mod_sidebar_ui <- function(id) {
  # TODO: Programmatically get species
  # TODO: Use display name

  con <- withr::local_db_connection(db_connect())

  sidebar(
    tagList(
      #TODO: Add tool tips with model/deployment descriptions on hover? Or other details somewhere?
      selectInput(
        NS(id, "user_id"),
        label = "User",
        choices = c(
          "Select a user" = "",
          named_ids(dplyr::tbl(con, "users"))
        )
      ),
      uiOutput(NS(id, "user_role")),
      selectInput(
        NS(id, "deployment_id"),
        label = "Deployment",
        choices = c(
          "Select a deployment" = "",
          named_ids(dplyr::tbl(con, "deployments"))
        )
      ),
      selectInput(
        NS(id, "model_id"),
        label = "Model",
        choices = c(
          "Select a model" = "",
          named_ids(dplyr::tbl(con, "models"))
        )
      ),
      selectInput(
        NS(id, "species_id"),
        label = "Species",
        choices = c(
          "Select a species" = "",
          named_ids(fmt_species(dplyr::tbl(con, "species")), name = "display")
        )
      ),
      selectInput(
        NS(id, "lang"),
        "Language",
        choices = c("English" = "english", "Français" = "french")
      ),

      strong("Developer outputs"),
      uiOutput(NS(id, "dev_outputs"))
    )
  )
}

mod_sidebar_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    output$dev_outputs <- renderUI({
      # React and update to changes in these values, but only show the options
      input$user_id
      input$user_role
      input$lang

      # Show current values
      glue::glue(
        "Deployment ID: {input$deployment_id}",
        "Model: {input$model_id}",
        "Species: {input$species_id}",
        "User (opt): {sdmevaltool_options()$user_id} ({sdmevaltool_options()$user_role})",
        "Language (opt): {sdmevaltool_options()$lang}",
        .sep = "<br>"
      ) |>
        htmltools::HTML()
    })

    output$user_role <- renderUI({
      if (!isTruthy(input$user_id)) {
        choices <- c("First select a User" = "")
      } else {
        con <- withr::local_db_connection(db_connect())
        u <- user_id() # Cannot put in filter() before collection, lazy evaluation goes funny
        roles <- dplyr::tbl(con, "access") |>
          dplyr::filter(.data$user_id == .env$u) |>
          dplyr::pull(.data$user_roles) |>
          stringr::str_split_1(", ?")
        choices <- rlang::set_names(roles, pretty(roles))
      }

      selectInput(
        NS(id, "user_role"),
        label = "Role",
        choices = choices
      )
    })

    list(
      user_id = reactive(input$user_id),
      user_role = reactive(input$user_role),
      deployment_id = reactive(input$deployment_id),
      model_id = reactive(input$model_id),
      species_id = reactive(input$species_id),
      lang = reactive(input$lang)
    )
  })
}
