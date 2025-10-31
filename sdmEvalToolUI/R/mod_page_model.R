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
mod_page_model_server <- function(id = "model", ...) {
  moduleServer(id, function(input, output, session) {
    rlang::env_bind(rlang::current_env(), !!!list(...))
    output$title <- renderText(paste0("Model statistics for model ", mod()))
  })
}

