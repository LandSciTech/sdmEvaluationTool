#' Test the Observations Chart Component
#'
#' @returns A Shiny app object
#'
#' @export
#' @examplesIf have_data()
#' test_comp_obs_chart()

test_comp_obs_chart <- function() {
  ui <- mod_comp_obs_chart_ui()

  server <- function(input, output, session) {
    mod_comp_obs_chart_server(
      deployment_id = reactive("deployment1"),
      model_id = reactive("bam_v5_can71"),
      species_id = reactive("BBWO")
    )
  }

  shiny::shinyApp(ui, server, options = list(port = 8080))
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
#' @param deployment_id
#' @param model_id
#' @param species_id
#'
#' @returns
#'
#' @export
#' @examples
mod_comp_obs_chart_server <- function(
  id = "comp_obs_chart",
  deployment_id,
  model_id,
  species_id
) {
  stopifnot(is.reactive(deployment_id))
  stopifnot(is.reactive(model_id))
  stopifnot(is.reactive(species_id))

  moduleServer(id, function(input, output, session) {
    # Chart -------------------------------------------
  })
}
