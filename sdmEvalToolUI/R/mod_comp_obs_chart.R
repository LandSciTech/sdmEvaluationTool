#' Test the Observations Chart Component
#'
#' @returns A Shiny app object
#'
#' @export
#' @examplesIf have_data()
#' test_comp_obs_chart()

test_comp_obs_chart <- function(...) {
  test_comp("mod_comp_obs_chart", use = c("model_id", "species_id"), ...)
}

#' Observations Chart Component UI
#'
#' @param id Character. Shiny module ID
#'
#' @returns Shiny UI
#'
#' @export
#' @examples
#' mod_comp_obs_chart_ui()

mod_comp_obs_chart_ui <- function(id = "comp_obs_chart") {
  tagList(
    # Chart output
  )
}


#' Observations Chart Component Server
#'
#' @param id
#' @param model_id
#' @param species_id
#'
#' @returns
#'
#' @export
#' @examples
mod_comp_obs_chart_server <- function(
  id = "comp_obs_chart",
  model_id,
  species_id
) {
  stopifnot(is.reactive(model_id))
  stopifnot(is.reactive(species_id))

  moduleServer(id, function(input, output, session) {
    # Chart -------------------------------------------
  })
}
