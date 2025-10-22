
sdm_tool <- function() {

  sdmEvalToolCore::sdmevaltool_options(base = "../misc/base")
  path_data <- file.path(sdmEvalToolCore::sdmevaltool_options()$base, "sdm_evaluation_db.sqlite")

  db <- DBI::dbConnect(path_data, drv = RSQLite::SQLite())
  tbl_models <- dplyr::tbl(db, "models") |>
    dplyr::collect()
  tbl_species <- dplyr::tbl(db, "species") |>
    dplyr::collect()
  tbl_materials <- dplyr::tbl(db, "materials") |>
    dplyr::collect()

  ui <- bslib::page_navbar(
    title = "SDM Tool",
    sidebar = mod_sidebar_ui(id = "sidebar", tbl_models, tbl_species),
    mod_overview_ui("overview"),
    mod_predictions_ui("predictions"),
    mod_observations_ui("observations"),
    mod_model_ui("model"),
    mod_predictors_ui("predictors")
  )

  server <- function(input, output, session) {

    vals <- mod_sidebar_server(id = "sidebar")

    mod_overview_server(
      "overview",
      mod = vals$mod,
      sp = vals$sp,
      tbl_models,
      tbl_species,
      tbl_materials
    )
    mod_predictions_server(
      "predictions",
      mod = vals$mod,
      sp = vals$sp,
      tbl_materials
    )
    mod_observations_server(
      "observations",
      mod = vals$mod,
      sp = vals$sp,
      tbl_materials
    )
    mod_model_server("model", mod = vals$mod, tbl_materials)
    mod_predictors_server("predictors", mod = vals$mod, tbl_materials)
  }

  shiny::shinyApp(ui, server, options = list(port = 8080))
}


mod_sidebar_ui <- function(id, tbl_models, tbl_species) {
  # TODO: Programmatically get species\
  sidebar(
    tagList(
      selectInput(
        NS(id, "sp"),
        label = "Species",
        choices = c("Select a species" = "", setNames(tbl_species[["species_id"]], nm = tbl_species[["english_name"]]))
      ),
      selectInput(
        NS(id, "mod"),
        label = "Model",
        choices = c("Select a model" = "", setNames(tbl_models[["model_id"]], nm = tbl_models[["model_name"]]))
      )
    )
  )
}

mod_sidebar_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    list(
      sp = reactive(input$sp),
      mod = reactive(input$mod)
    )
  })
}