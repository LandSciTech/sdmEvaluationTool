#' Title
#'
#' @returns
#'
#' @export
#' @examples
#' sdm_tool()
sdm_tool <- function() {
  # TODO: define pages, etc. elsewhere
  page_options <- c(
    "overview",
    "predictions",
    "observations",
    "model",
    "predictors",
    "model_metadata"
  )
  lang <- "english"

  # Pages
  pages_ui <- lapply(page_options, \(p) get(paste0("mod_page_", p, "_ui"))())
  pages_server <- lapply(page_options, \(p) {
    get(paste0("mod_page_", p, "_server"))
  })

  # Data
  prep_data() |> expand_list()

  ui <- bslib::page_navbar(
    title = "SDM Tool",
    sidebar = mod_sidebar_ui(id = "sidebar", tbl_models, tbl_species),
    !!!pages_ui
  )

  server <- function(input, output, session) {
    vals <- mod_sidebar_server(id = "sidebar")

    for (t in pages_server) {
      t(
        model_id = vals$model_id,
        species_id = vals$species_id,
        tbl_models = tbl_models,
        tbl_species = tbl_species,
        tbl_materials = tbl_materials
      )
    }
  }

  shiny::shinyApp(ui, server, options = list(port = 8080))
}


mod_sidebar_ui <- function(id, tbl_models, tbl_species) {
  # TODO: Programmatically get species
  # TODO: Use display name
  sidebar(
    tagList(
      selectInput(
        NS(id, "model_id"),
        label = "Model",
        choices = c(
          "Select a model" = "",
          setNames(tbl_models[["model_id"]], nm = tbl_models[["model_name"]])
        )
      ),
      selectInput(
        NS(id, "species_id"),
        label = "Species",
        choices = c(
          "Select a species" = "",
          setNames(
            tbl_species[["species_id"]],
            nm = tbl_species[["english_name"]]
          )
        )
      )
    )
  )
}

mod_sidebar_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    list(
      model_id = reactive(input$model_id),
      species_id = reactive(input$species_id)
    )
  })
}
