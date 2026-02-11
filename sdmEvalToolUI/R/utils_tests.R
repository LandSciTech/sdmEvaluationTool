test_page <- function(
  module,
  deployment_id = "deployment1",
  model_id = "bam_v5_can71",
  species_id = "BBWO",
  user_id = "holden",
  user_role = "evaluator"
) {
  opts <- list(user_id = user_id, user_role = user_role)

  ui <- bslib::page_navbar(
    title = "SDM Tool Testing",
    theme = sdm_theme(),
    header = shinyjs::useShinyjs(),
    get(paste0(module, "_ui"))(
      title = stringr::str_remove_all(module, "mod_page_") |> fmt_pretty(),
      id = stringr::str_remove_all(module, "mod_page_"),
    )
  )

  if (module == "mod_page_overview") {
    server <- function(input, output, session) {
      mod_page_overview_server(
        deployment_id = reactive(deployment_id),
        model_id = reactive(model_id),
        species_id = reactive(species_id),
        opts = list(
          "user_id" = reactive(user_id),
          "user_role" = reactive(user_role)
        ),
        overview_inputs = reactiveVal(NULL),
        overview_update = reactiveVal(NULL),
        abandoned = reactiveVal(NULL)
      )
    }
  } else {
    server <- function(input, output, session) {
      get(paste0(module, "_server"))(
        deployment_id = reactive(deployment_id),
        model_id = reactive(model_id),
        species_id = reactive(species_id),
        opts = purrr::map(opts, \(o) reactive(force(o))),
        abandoned = reactiveVal(FALSE)
      )
    }
  }

  shiny::shinyApp(ui, server, options = list(port = 8080))
}

test_comp <- function(
  module,
  use = c(
    "deployment_id",
    "model_id",
    "species_id",
    "spatial_ids",
    "spatial_selection"
  ),
  deployment_id = "deployment1",
  model_id = "bam_v5_can71",
  species_id = "BBWO",
  spatial_ids = NULL,
  spatial_selection = list(show_clicked = NULL, show_spatial_ids = NULL)
) {
  ui <- get(paste0(module, "_ui"))()

  u <- list(
    "deployment_id" = reactive(deployment_id),
    "model_id" = reactive(model_id),
    "species_id" = reactive(species_id),
    "spatial_ids" = reactiveVal(spatial_ids),
    "spatial_selection" = purrr::map(spatial_selection, \(s) reactive(force(s)))
  )

  u <- u[names(u) %in% use]

  server <- function(input, output, session) {
    do.call(get(paste0(module, "_server")), u)
  }

  shiny::shinyApp(ui, server, options = list(port = 8080))
}
