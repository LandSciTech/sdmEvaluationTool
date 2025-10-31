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
    rlang::env_bind(rlang::current_env(), !!!list(...))
    output$title <- renderText(paste0("Model predictions for model ", mod(), " and species ", sp()))
  })
}

