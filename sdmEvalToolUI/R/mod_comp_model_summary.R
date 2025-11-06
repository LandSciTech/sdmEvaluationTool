#' Title
#'
#' @returns
#'
#' @export
#' @examplesIf have_data()
#' test_comp_model_summary()

test_comp_model_summary <- function() {
  ui <- mod_comp_model_summary_ui()

  server <- function(input, output, session) {
    mod_comp_model_summary_server(
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
mod_comp_model_summary_ui <- function(id = "comp_model_summary") {
  tagList(
    reactable::reactableOutput(NS(id, "model_summary"))
  )
}


mod_comp_model_summary_server <- function(
  id = "comp_model_summary",
  model_id,
  species_id
) {
  moduleServer(id, function(input, output, session) {
    model_summary <- reactive(model_summary_prep(model_id(), species_id()))
    output$model_summary <- reactable::renderReactable(model_summary_table(model_summary()))
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
#' model_summary_prep(model_id = "bam_v5_can71", species_id = "BBWO") |>
#'   model_summary_table()

model_summary_table <- function(model_summary) {
  reactable::reactable(model_summary)
}

#' Title
#'
#' @param obs
#'
#' @returns
#'
#' @export
#' @examplesIf have_data()
#' model_summary_prep(model_id = "bam_v5_can71", species_id = "BBWO")

model_summary_prep <- function(model_id, species_id) {
  prep_files("model_summary", model_id = model_id, species_id = species_id)
}
