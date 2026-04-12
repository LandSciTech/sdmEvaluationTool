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
#' test_page_observations(deployment_id = NULL)
#' test_page_observations(user_id = "testuser")
#' test_page_observations(deployment_id = "deployment1")
#' test_page_observations(deployment_id = "deployment2")

test_page_observations <- function(...) {
  test_page("mod_page_observations", ...)
}

#' Observations Page UI
#'
#' @param id Shiny module ID
#' @param title Page title
#' @param review_width Character. Width of the review sidebar in percentage of
#'   the screen
#'
#' @returns Shiny UI
#'
#' @export
#' @examples
#' mod_page_observations_ui("id", "title")

mod_page_observations_ui <- function(
  id,
  title,
  review_width = NULL
) {
  nav_panel(
    title = span(title, class = "sdm-species-lvl"),
    value = id,
    sdm_layout_sidebar(
      sidebar = mod_utils_evaluations_ui(NS(id, "eval"), review_width),
      navset_card_tab(
        sdm_nav_panel(
          "Charts",
          card_body(
            class = "p-0",
            mod_comp_obs_chart_ui(NS(id, "comp_obs_chart"))
          )
        ),
        sdm_nav_panel(
          "Map",
          card_body(
            class = "p-0",
            mod_comp_observations_ui(NS(id, "comp_obs"))
          )
        )
      )
    )
  )
}

#' Observations Page Server
#'
#' @param id Shiny module ID
#' @param ... Additional arguments passed via expand_dots including
#' `deployment_id`, `model_id`, `species_id`, `abandoned`, `unsaved`, `opts`
#' list (see [sdm_tool()] which programmatically calls all module pages.
#'
#' @returns Server function for Shiny module
#'
#' @export

mod_page_observations_server <- function(id = "observations", ...) {
  expand_dots(...)
  stopifnot(is.reactive(deployment_id))
  stopifnot(is.reactive(model_id))
  stopifnot(is.reactive(species_id))
  stopifnot(is.reactive(abandoned)) # reactiveVal
  stopifnot(is.reactive(unsaved)) # reactiveVal
  purrr::walk(opts, \(o) stopifnot(is.reactive(o)))

  moduleServer(id, function(input, output, session) {
    # Placeholder reactiveVal until map created
    spatial_ids <- reactiveVal(NULL)

    # Prepare the evaluation questions
    spatial_selection <- mod_utils_evaluations_server(
      "eval",
      component_id = "observations",
      spatial_type = "area",
      deployment_id = deployment_id,
      model_id = model_id,
      species_id = species_id,
      spatial_ids = spatial_ids,
      opts = opts,
      abandoned = abandoned,
      unsaved = unsaved
    )

    # Create charts
    mod_comp_obs_chart_server(
      "comp_obs_chart",
      model_id = model_id,
      species_id = species_id
    )

    # Create the map and return all spatial ids available
    mod_comp_observations_server(
      "comp_obs",
      deployment_id = deployment_id,
      model_id = model_id,
      species_id = species_id,
      spatial_selection = spatial_selection,
      spatial_ids = spatial_ids #reactiveVal to update in module
    )
  })
}
