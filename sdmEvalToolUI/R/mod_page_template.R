#' Test the Template Page
#'
#' @returns A Shiny app object
#' @noRd
#'
#' @examplesIf have_data()
#' test_page_template()
#' test_page_template(deployment_id = "deployment2")
#' test_page_template(user_id = "testuser")

test_page_template <- function(...) {
  test_page("mod_page_template", ...)
}

#' Template Page UI
#'
#' @param id Shiny module ID
#' @param title Page title
#' @param review_width Review width
#'
#' @returns Shiny UI
#'
#' @export
#' @examples
#' mod_page_template_ui("id", "title")

mod_page_template_ui <- function(
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
        mod_comp_template_ui(NS(id, "template1"), header = "Template 1"),
        mod_comp_template_ui(NS(id, "template2"), header = "Template 2")
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

mod_page_template_server <- function(id = "template", ...) {
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
    # TEMPLATE: Prepare the evaluation questions
    #  The evaluation side bar is on the level of the page
    # NOTE: In our example there will be no questions because there are no
    # questions available for component_id "template".

    mod_utils_evaluations_server(
      "eval",
      component_id = c("template"), # component types included
      # TEMPLATE: The following are required in each page
      deployment_id = deployment_id,
      model_id = model_id,
      species_id = species_id,
      opts = opts,
      abandoned = abandoned,
      unsaved = unsaved
    )

    # NOTE: No deployment id required because materials only associated
    #   with model and species
    mod_comp_template_server("template1", model_id, species_id)
    mod_comp_template_server("template2", model_id, species_id)
  })
}
