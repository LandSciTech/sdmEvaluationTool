#' Title
#'
#' @param id
#' @param title
#'
#' @returns
#'
#' @export
#' @examples
mod_page_model_metadata_ui <- function(
  id = "model_metadata",
  title = "Model_Metadata"
) {
  nav_panel(
    title,
    h2(textOutput(NS(id, "title"))),
    mod_comp_model_metadata_ui(NS(id, "model_metadata"))
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
mod_page_model_metadata_server <- function(id = "model_metadata", ...) {
  moduleServer(id, function(input, output, session) {
    rlang::env_bind(rlang::current_env(), !!!list(...))
    output$title <- renderText(paste0("Model Metadata: ", model_id()))

    mod_comp_model_metadata_server("model_metadata", model_id())
  })
}
