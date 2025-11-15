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

  # Data
  prep_data() |> expand_list()

  ui <- bslib::page_navbar(
    title = "SDM Tool",
    sidebar = mod_sidebar_ui(
      id = "sidebar",
      tbl_deployments,
      tbl_models,
      tbl_species
    ),
    !!!pages_ui
  )

  server <- function(input, output, session) {
    vals <- mod_sidebar_server(id = "sidebar")

    for (t in pages_server) {
      t(
        deployment_id = vals$deployment_id,
        model_id = vals$model_id,
        species_id = vals$species_id,
        tbl_models = tbl_models,
        tbl_species = tbl_species
      )
    }
  }

  shiny::shinyApp(ui, server, options = list(port = 8080))
}


mod_sidebar_ui <- function(id, tbl_deployments, tbl_models, tbl_species) {
  # TODO: Programmatically get species
  # TODO: Use display name

  sidebar(
    tagList(
      #TODO: Add tool tips with model/deployment descriptions on hover? Or other details somewhere?
      selectInput(
        NS(id, "deployment_id"),
        label = "Deployment",
        choices = c(
          "Select a deployment" = "",
          stats::setNames(
            tbl_deployments[["deployment_id"]],
            nm = tbl_deployments[["deployment_name"]]
          )
        )
      ),
      selectInput(
        NS(id, "model_id"),
        label = "Model",
        choices = c(
          "Select a model" = "",
          stats::setNames(
            tbl_models[["model_id"]],
            nm = tbl_models[["model_name"]]
          )
        )
      ),
      selectInput(
        NS(id, "species_id"),
        label = "Species",
        choices = c(
          "Select a species" = "",
          stats::setNames(
            tbl_species[["species_id"]],
            nm = tbl_species[["display_name"]]
          )
        )
      )
    )
  )
}

mod_sidebar_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    list(
      deployment_id = reactive(input$deployment_id),
      model_id = reactive(input$model_id),
      species_id = reactive(input$species_id)
    )
  })
}
