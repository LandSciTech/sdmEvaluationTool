#' Title
#'
#' @returns
#' @noRd
#'
#' @examplesIf have_data()
#' test_page_observations()
#' test_page_observations(NULL, NULL, NULL)

test_page_observations <- function(
  deployment_id = "deployment1",
  model_id = "bam_v5_can71",
  species_id = "BBWO"
) {
  # TODO: define location, pages, etc. elsewhere
  prep_data() |> expand_list()

  ui <- bslib::page_navbar(
    title = "SDM Tool Testing",
    mod_page_observations_ui()
  )

  server <- function(input, output, session) {
    mod_page_observations_server(
      deployment_id = reactive(deployment_id),
      model_id = reactive(model_id),
      species_id = reactive(species_id),
      tbl_deployments = tbl_deployments,
      tbl_models = tbl_models,
      tbl_species = tbl_species
    )
  }

  shiny::shinyApp(ui, server, options = list(port = 8080))
}

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
  title = "Observations",
  review_width = "50%"
) {
  nav_panel(
    title,
    layout_sidebar(
      sidebar = sidebar(
        width = review_width,
        position = "right",
        "TESTING CONTENTS",
        uiOutput(NS(id, "ui_evaluation"))
      ),
      h2(textOutput(NS(id, "title"))),
      mod_comp_observations_ui(NS(id, "comp_obs"))
    )
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
  expand_dots(...)
  stopifnot(is.reactive(deployment_id))
  stopifnot(is.reactive(model_id))
  stopifnot(is.reactive(species_id))

  moduleServer(id, function(input, output, session) {
    output$title <- renderText({
      paste0(
        "Observations for Model: ",
        model_id(),
        " and species ",
        species_id()
      )
    })

    output$ui_evaluation <- renderUI({
      #TODO: Save values so don't loose filled data when switching
      evaluation(
        component_id = "observations",
        deployment_id = deployment_id(),
        model_id = model_id(),
        species_id = species_id()
      )
    })

    mod_comp_observations_server(
      "comp_obs",
      model_id = model_id,
      species_id = species_id
    )
  })
}
