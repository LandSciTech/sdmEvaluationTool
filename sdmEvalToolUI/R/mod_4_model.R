#' Title
#'
#' @param id
#' @param title
#'
#' @returns 
#'
#' @export
#' @examples
mod_model_ui <- function(id, title = "Model") {
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
mod_model_server <- function(id, mod, tbl_materials) {
  moduleServer(id, function(input, output, session) {
    output$title <- renderText(paste0("Model statistics for model ", mod()))
  })
}

