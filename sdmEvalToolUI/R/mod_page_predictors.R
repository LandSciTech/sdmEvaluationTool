#' Title
#'
#' @param id
#' @param title
#'
#' @returns
#'
#' @export
#' @examples
mod_page_predictors_ui <- function(id = "predictors", title = "Predictors") {
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
mod_page_predictors_server <- function(id = "predictors", ...) {
  moduleServer(id, function(input, output, session) {
    expand_dots(...)
    output$title <- renderText(paste0("Model predictors for model ", mod()))
  })
}
