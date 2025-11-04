#' Title
#'
#' @returns
#'
#' @export
#' @examplesIf have_data()
#' test_comp_model_fit()
test_comp_model_fit <- function() {
  ui <- mod_comp_model_fit_ui()

  server <- function(input, output, session) {
    mod_comp_model_fit_server(
      model_id = reactive("bam_v5_can71"),
      species_id = reactive("BBWO")
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
mod_comp_model_fit_ui <- function(id = "comp_model_fit") {
  tagList(
    reactable::reactableOutput(NS(id, "model_fit"))
  )
}


mod_comp_model_fit_server <- function(
  id = "comp_model_fit",
  model_id,
  species_id
) {
  moduleServer(id, function(input, output, session) {
    model_fit <- reactive(model_fit_prep(model_id(), species_id()))
    output$model_fit <- reactable::renderReactable(model_fit_table(model_fit()))
  })
}


#' Title
#'
#' @param obs
#'
#' @returns
#'
#' @export
#' @examplesIf have_data()
#' model_fit_prep(model_id = "bam_v5_can71", species_id = "BBWO") |>
#'   model_fit_table()

model_fit_table <- function(model_fit) {
  reactable::reactable(model_fit)
}

#' Title
#'
#' @param obs
#'
#' @returns
#'
#' @export
#' @examplesIf have_data()
#' model_fit_prep(model_ = "bam_v5_can71", species_id = "BBWO")

model_fit_prep <- function(model_id, species_id) {
  prep_files("model_fit", model_id = model_id, species_id = species_id)
}
