#' Test the Model Page
#'
#' @returns A Shiny app object
#' @noRd
#'
#' @examplesIf have_data()
#' test_page_model()
#' test_page_model(deployment_id = "deployment2")
#' test_page_model(user_id = "testuser")

test_page_model <- function(...) {
  test_page("mod_page_model", ...)
}

#' Model Page UI
#'
#' @param id Shiny module ID
#' @param title Page title
#' @param review_width Review width
#'
#' @returns Shiny UI
#'
#' @export
#' @examples
#' mod_page_model_ui()
mod_page_model_ui <- function(
  id = "model",
  title = "Model",
  review_width = NULL
) {
  nav_panel(
    span(title, class = "sdm-species-lvl"),
    sdm_layout_sidebar(
      sidebar = mod_utils_evaluations_ui(NS(id, "eval"), review_width),

      layout_column_wrap(
        width = NULL,
        gap = 0,
        style = css(grid_template_columns = "1fr 3fr"),
        mod_comp_model_fit_ui(
          NS(id, "model_fit"),
          header = card_header("Model Fit")
        ),
        mod_comp_model_summary_ui(
          NS(id, "model_summary"),
          header = card_header("Model Summary")
        )
      )
    )
  )
}

#' Model Page Server
#'
#' @param id Shiny module ID
#' @param ... Additional arguments passed via expand_dots including model_id, species_id, tbl_models, tbl_species
#'
#' @returns Server function for Shiny module
#'
#' @export

mod_page_model_server <- function(id = "model", ...) {
  expand_dots(...)
  stopifnot(is.reactive(deployment_id))
  stopifnot(is.reactive(model_id))
  stopifnot(is.reactive(species_id))
  purrr::walk(opts, \(o) stopifnot(is.reactive(o)))

  moduleServer(id, function(input, output, session) {
    # Prepare the evaluation questions
    mod_utils_evaluations_server(
      "eval",
      component_id = c("model_fit", "model_summary"),
      deployment_id = deployment_id,
      model_id = model_id,
      species_id = species_id,
      opts = opts
    )

    mod_comp_model_summary_server("model_summary", model_id, species_id)
    mod_comp_model_fit_server("model_fit", model_id, species_id)
  })
}
