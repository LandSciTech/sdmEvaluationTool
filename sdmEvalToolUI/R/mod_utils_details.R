#' Utility Module 'Details' UI
#'
#' Used in [sdm_tool()] to create the Deployment Details left-hand sidebar.
#'
#' @param id Shiny module ID
#'
#' @returns Shiny UI
#'
#' @export
#' @examples
#' mod_utils_details_ui()

mod_utils_details_ui <- function(id = "details") {
  sidebar(
    title = NULL,
    open = TRUE,
    uiOutput(NS(id, "details")),
    width = 400
  )
}

#' Utility Module 'Details' Server
#'
#' Used in [sdm_tool()] to create the Deployment Details left-hand sidebar.
#'
#' @param id Shiny module ID
#' @param details Data frame of details to display.
#'
#' @returns Server function for Shiny module
#'
#' @export

mod_utils_details_server <- function(id = "details", details) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    output$details <- renderUI({
      # note: same info is in the db as in the json file
      # need to decide which to use
      sett <- jsonlite::fromJSON(details()$deployment_settings)
      tagList(
        h3(details()$deployment_name),
        markdown(sett$instructions_to_evaluators)
      )
    })
    output$name <- renderText(details()$deployment_name)
  })
}
