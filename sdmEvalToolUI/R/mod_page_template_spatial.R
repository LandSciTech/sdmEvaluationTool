#' Test the Template Spatial Page
#'
#' @returns A Shiny app object
#' @noRd
#'
#' @examplesIf have_data()
#' test_page_template_spatial()
#' test_page_template_spatial(deployment_id = "deployment2")
#' test_page_template_spatial(user_id = "testuser")

test_page_template_spatial <- function(...) {
  test_page("mod_page_template_spatial", ...)
}

#' Template Spatial Page UI
#'
#' @param id Shiny module ID
#' @param title Page title
#' @param review_width Review width
#'
#' @returns Shiny UI
#'
#' @export
#' @examples
#' mod_page_template_spatial_ui("id", "title")

mod_page_template_spatial_ui <- function(
  id,
  title,
  review_width = NULL
) {
  nav_panel(
    title = span(title, class = "sdm-species-lvl"),
    value = id,

    sdm_layout_sidebar(
      sidebar = mod_utils_evaluations_ui(NS(id, "eval"), review_width),

      # EXAMPLE: Layout for with two columns, 1:3 ratio widths
      layout_column_wrap(
        width = NULL,
        gap = 0,
        style = css(grid_template_columns = "1fr 3fr"),

        # EXAMPLE: Arrange component modules
        mod_comp_template_ui(
          NS(id, "template"),
          header = sdm_card_header("Template")
        ),
        mod_comp_template_spatial_ui(
          NS(id, "template_spatial"),
          header = sdm_card_header("Template Spatial")
        )
        # mod_comp_...._ui(), etc.
      )
    )
  )
}

#' Template Page Server
#'
#' @param id Shiny module ID
#' @param ... Additional arguments passed via expand_dots including
#' `deployment_id`, `model_id`, `species_id`, `abandoned`, `unsaved`, `opts`
#' list (see [sdm_tool()] which programmatically calls all module pages.
#'
#' @returns Server function for Shiny module
#'
#' @export

mod_page_template_spatial_server <- function(id = "template_spatial", ...) {
  expand_dots(...) # Turn `...` into arguments
  # TEMPLATE: This section checks if all standard args are reactive
  # This also serves to remind the developer which args are passed from
  # the main app (in `app.R`) via `...`
  # It also includes `opts` which is a list of option-like reactives
  stopifnot(is.reactive(deployment_id))
  stopifnot(is.reactive(model_id))
  stopifnot(is.reactive(species_id))
  stopifnot(is.reactive(abandoned)) # reactiveVal
  stopifnot(is.reactive(unsaved)) # reactiveVal
  purrr::walk(opts, \(o) stopifnot(is.reactive(o)))

  moduleServer(id, function(input, output, session) {
    # TEMPLATE: For Pages with spatial components,
    #   Placeholder reactiveVal until map created
    spatial_ids <- reactiveVal(NULL)

    # TEMPLATE: Prepare the evaluation questions
    #  The evaluation side bar is on the level of the page
    # NOTE: In our example there will be no questions because there are no
    # questions available for component_id "template".

    spatial_selection <- mod_utils_evaluations_server(
      "eval",
      # TEMPLATE: The following are required in each page
      component_id = c("template", "template_spatial"), # component types included
      deployment_id = deployment_id,
      model_id = model_id,
      species_id = species_id,
      opts = opts,
      abandoned = abandoned,
      unsaved = unsaved,
      # TEMPLATE: These are required for pages with spatial components
      spatial_type = "area", # "points" or "area"
      spatial_ids = spatial_ids
    )

    # Non-spatial Component
    # Create charts
    mod_comp_template_server(
      "template",
      model_id = model_id,
      species_id = species_id
    )

    # Spatial Component
    mod_comp_template_spatial_server(
      "template_spatial",
      deployment_id = deployment_id, # Require deployment_id for subunits on maps
      model_id = model_id,
      species_id = species_id,
      spatial_selection = spatial_selection,
      spatial_ids = spatial_ids #reactiveVal to update in module which is referred to by the evaluations module to create lists of ids to select
    )
  })
}
