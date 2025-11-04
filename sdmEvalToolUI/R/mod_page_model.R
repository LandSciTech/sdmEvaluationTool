#' Title
#'
#' @param id
#' @param title
#'
#' @returns
#'
#' @export
#' @examples
mod_page_model_ui <- function(id = "model", title = "Model") {
  nav_panel(
    title,
    h2(textOutput(NS(id, "title"))),

    h4("Model summary"),
    mod_comp_model_summary_ui(NS(id, "model_summary")),

    h4("Model fit"),
    mod_comp_model_fit_ui(NS(id, "model_fit"))
  )
}

#' Title
#'
#' @param id
#'
#' @returns
#'
#' @export
#' @examples
mod_page_model_server <- function(id = "model", ...) {
  moduleServer(id, function(input, output, session) {
    expand_dots(...)
    output$title <- renderText(paste0(
      "Model statistics for model ",
      model_id(),
      " and species ",
      species_id()
    ))

    mod_comp_model_summary_server("model_summary", model_id, species_id)
    mod_comp_model_fit_server("model_fit", model_id, species_id)
  })
}
