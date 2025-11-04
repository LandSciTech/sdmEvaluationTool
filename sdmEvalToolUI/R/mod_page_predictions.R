#' Title
#'
#' @param id
#' @param title
#'
#' @returns
#'
#' @export
#' @examples
mod_page_predictions_ui <- function(id = "predictions", title = "Predictions") {
  nav_panel(
    title,
    h2(textOutput(NS(id, "title")))
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
mod_page_predictions_server <- function(id = "predictions", ...) {
  moduleServer(id, function(input, output, session) {
    expand_dots(...)

    output$title <- renderText(paste0(
      "Spatial predictions for model ",
      model_id(),
      " and species ",
      species_id()
    ))
  })
}
