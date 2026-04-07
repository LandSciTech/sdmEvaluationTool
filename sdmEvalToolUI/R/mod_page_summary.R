#' Test the Summary Page
#'
#' @returns A Shiny app object
#' @noRd
#'
#' @examplesIf have_data()
#' test_page_summary()
#' test_page_summary(deployment_id = "deployment2")
#' test_page_summary(user_id = "testuser")

test_page_summary <- function(...) {
  test_page("mod_page_summary", ...)
}

#' Summary Page UI
#'
#' @param id Shiny module ID
#' @param title Page title
#' @param review_width Review width
#'
#' @returns Shiny UI
#'
#' @export
#' @examples
#' mod_page_summary_ui("id", "title")
mod_page_summary_ui <- function(
  id,
  title,
  review_width = NULL
) {
  nav_panel(
    title = span(title, class = "sdm-species-lvl"),
    value = id,

    sdm_layout_sidebar(
      sidebar = mod_utils_evaluations_ui(NS(id, "eval"), review_width),

      mod_comp_deployment_subunits_ui(
        NS(id, "deployment_subunits"),
        header = sdm_card_header("Comfort zones")
      )
    )
  )
}

#' Summary Page Server
#'
#' @param id Shiny module ID
#' @param ... Additional arguments passed via expand_dots including
#' `deployment_id`, `model_id`, `species_id`, `abandoned`, `unsaved`, `opts`
#' list (see [sdm_tool()] which programmatically calls all module pages.
#'
#' @returns Server function for Shiny module
#'
#' @export

mod_page_summary_server <- function(id = "summary", ...) {
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
      component_id = c("deployment_settings", "deployment_subunits"),
      deployment_id = deployment_id,
      model_id = model_id,
      species_id = species_id,
      opts = opts,
      abandoned = abandoned,
      unsaved = unsaved,
      spatial_type = "area", # "points" or "area"
      spatial_ids = spatial_ids
    )

    mod_comp_deployment_subunits_server(
      "deployment_subunits",
      deployment_id = deployment_id,
      model_id = model_id,
      species_id = species_id,
      spatial_selection = spatial_selection,
      spatial_ids = spatial_ids #reactiveVal with selectatable spatial units
    )
  })
}
