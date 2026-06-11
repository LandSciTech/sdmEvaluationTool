#' Create Test App for Page Modules
#'
#' Not all arguments are used by all modules.
#'
#' @param module Character. Module Name.
#' @param deployment_id Character. Example Deployment ID.
#' @param model_id Character. Example Model ID.
#' @param species_id Character. Example Species ID.
#' @param user_id Character. Example User ID.
#' @param user_role Character. Example User Role.
#' @param user_admin Logical Example User Admin status.
#'
#' @returns Shiny App
#'
#' @export

test_page <- function(
  module,
  deployment_id = "deployment1",
  model_id = "bam_v5_can71",
  species_id = "BBWO",
  user_id = "testuser",
  user_role = "evaluator",
  user_admin = FALSE
) {
  opts <- list(
    user_id = user_id,
    user_role = user_role,
    user_admin = user_admin
  )

  ui <- bslib::page_navbar(
    title = "SDM Tool Testing",
    theme = sdm_theme(),
    header = shinyjs::useShinyjs(),
    get(paste0(module, "_ui"))(
      title = stringr::str_remove_all(module, "mod_page_") |> fmt_pretty(),
      id = stringr::str_remove_all(module, "mod_page_")
    )
  )

  if (module == "mod_page_overview") {
    server <- function(input, output, session) {
      mod_page_overview_server(
        deployment_id = reactive(deployment_id),
        model_id = reactive(model_id),
        species_id = reactive(species_id),
        opts = purrr::map(opts, \(o) reactive(force(o))),
        overview_inputs = reactiveVal(NULL),
        overview_update = reactiveVal(NULL),
        abandoned = reactiveVal(NULL),
        unsaved = reactiveVal(NULL)
      )
    }
  } else {
    server <- function(input, output, session) {
      get(paste0(module, "_server"))(
        deployment_id = reactive(deployment_id),
        model_id = reactive(model_id),
        species_id = reactive(species_id),
        opts = purrr::map(opts, \(o) reactive(force(o))),
        abandoned = reactiveVal(FALSE),
        unsaved = reactiveVal(FALSE)
      )
    }
  }

  shiny::shinyApp(ui, server, options = list(port = 7405))
}

#' Create Test App for Component Modules
#'
#' Not all arguments are used by all modules.
#'
#' @param module Character. Module Name.
#' @param use Character vector. Objects to include
#' @param deployment_id Character. Example Deployment ID.
#' @param model_id Character. Example Model ID.
#' @param species_id Character. Example Species ID.
#' @param spatial_ids Character. Optional starting spatial ids.
#' @param spatial_selection List. Optional starting spatial selection
#' (`show_clicked` and `show_spatial_ids`).
#'
#' @returns Shiny App
#'
#' @export
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
  if (testthat::is_testing()) {
    sdmevaltool_options(
      base = testthat::test_path("../../../misc/base")
    )
  }

  ui <- bslib::page(theme = sdm_theme(), get(paste0(module, "_ui"))())

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

  shiny::shinyApp(ui, server, options = list(port = 7405))
}


#' Skip testthat tests if no data is detected
#'
#' @returns Logical
#'
#' @export

skip_if_no_data <- function() {
  if (!have_data()) {
    testthat::skip(
      paste0(
        "No data available for testing: ",
        normalizePath(sdmEvalToolCore::sdmevaltool_options()$base)
      )
    )
  }
}
