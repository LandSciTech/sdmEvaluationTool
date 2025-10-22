#' Title
#'
#' @param id
#' @param title
#'
#' @returns 
#'
#' @export
#' @examples
mod_predictions_ui <- function(id, title = "Predictions") {
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
mod_predictions_server <- function(id, mod, sp, tbl_materials) {
  moduleServer(id, function(input, output, session) {
    output$title <- renderText(paste0("Predictions for Model: ", mod(), " and species ", sp()))
  })
}

