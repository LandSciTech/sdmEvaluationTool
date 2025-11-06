#' Title
#'
#' @returns
#' @noRd
#'
#' @examplesIf have_data()
#' test_page_observations()

test_page_observations <- function() {
  # TODO: define location, pages, etc. elsewhere
  prep_data() |> expand_list()

  ui <- bslib::page_navbar(
    title = "SDM Tool Testing",
    mod_page_observations_ui()
  )

  server <- function(input, output, session) {
    mod_page_observations_server(
      model_id = reactive("bam_v5_can71"),
      species_id = reactive("BBWO"),
      tbl_materials = tbl_materials,
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
  expand_dots(...)
  stopifnot(is.reactive(deployment_id))
  stopifnot(is.reactive(model_id))
  stopifnot(is.reactive(species_id))

  moduleServer(id, function(input, output, session) {
    output$title <- renderText(paste0(
      "Observations for Model: ",
      model_id(),
      " and species ",
      species_id()
    ))

    mod_comp_observations_server(
      "comp_obs",
      model_id = model_id,
      species_id = species_id
    )
  })
}
