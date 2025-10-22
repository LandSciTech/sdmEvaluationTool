#' Title
#'
#' @param id
#' @param title
#'
#' @returns 
#'
#' @export
#' @examples
mod_predictors_ui <- function(id, title = "Predictors") {
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
mod_predictors_server <- function(id, mod, tbl_materials) {
  moduleServer(id, function(input, output, session) {
    output$title <- renderText(paste0("Model predictors for model ", mod()))
  })
}

