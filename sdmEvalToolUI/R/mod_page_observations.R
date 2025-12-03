#' Test the Observations Page
#'
#' @param deployment_id Character. Deployment ID
#' @param model_id Character. Model ID
#' @param species_id Character. Species ID
#'
#' @returns A Shiny app object
#' @noRd
#'
#' @examplesIf have_data()
#' test_page_observations()
#' test_page_observations(NULL, NULL, NULL)

test_page_observations <- function(
  deployment_id = "deployment1",
  model_id = "bam_v5_can71",
  species_id = "BBWO"
) {
  ui <- bslib::page_navbar(
    title = "SDM Tool Testing",
    theme = sdm_theme(),
    mod_page_observations_ui()
  )

  server <- function(input, output, session) {
    mod_page_observations_server(
      deployment_id = reactive(deployment_id),
      model_id = reactive(model_id),
      species_id = reactive(species_id)
    )
  }

  shiny::shinyApp(ui, server, options = list(port = 8080))
}

#' Observations Page UI
#'
#' @param id Shiny module ID
#' @param title Page title
#' @param review_width Character. Width of the review sidebar in percentage of the screen
#'
#' @returns Shiny UI
#'
#' @export
#' @examples
#' mod_page_observations_ui()
mod_page_observations_ui <- function(
  id = "observations",
  title = "Observations",
  review_width = "50%"
) {
  nav_panel(
    title,
    layout_sidebar(
      sidebar = mod_utils_evaluations_ui(NS(id, "eval"), review_width),
      h2(textOutput(NS(id, "title"))),
      mod_comp_observations_ui(NS(id, "comp_obs"))
    )
  )
}

#' Observations Page Server
#'
#' @param id Shiny module ID
#' @param ... Additional arguments passed via expand_dots including deployment_id, model_id, species_id, tbl_models, tbl_species
#'
#' @returns Server function for Shiny module
#'
#' @export

mod_page_observations_server <- function(id = "observations", ...) {
  expand_dots(...)
  stopifnot(is.reactive(deployment_id))
  stopifnot(is.reactive(model_id))
  stopifnot(is.reactive(species_id))

  moduleServer(id, function(input, output, session) {
    output$title <- renderText({
      paste0(
        "Observations for Model: ",
        model_id(),
        " and species ",
        species_id()
      )
    })

    # Placeholder reactiveVal until map created
    spatial_ids <- reactiveVal(NULL)

    # Prepare the evaluation questions
    spatial_selection <- mod_utils_evaluations_server(
      "eval",
      deployment_id,
      model_id,
      species_id,
      spatial_ids
    )

    # Create the map and return all spatial ids available
    mod_comp_observations_server(
      "comp_obs",
      model_id = model_id,
      species_id = species_id,
      spatial_selection = spatial_selection,
      spatial_ids = spatial_ids #reactiveVal to update in module
    )
  })
}
