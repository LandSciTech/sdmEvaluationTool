#' Title
#'
#' @param id
#' @param title
#'
#' @returns
#'
#' @export
#' @examples
mod_page_observations_ui <- function(
  id = "observations",
  title = "Observations"
) {
  nav_panel(
    title,
    h2(textOutput(NS(id, "title"))),
    mod_comp_observations_ui(NS(id, "comp_obs"))
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
mod_page_observations_server <- function(id = "observations", ...) {
  moduleServer(id, function(input, output, session) {
    expand_dots(...)

    output$title <- renderText(paste0(
      "Observations for Model: ",
      mod(),
      " and species ",
      sp()
    ))

    mod_comp_observations_server("comp_obs", sp = sp, mod = mod)
  })
}
