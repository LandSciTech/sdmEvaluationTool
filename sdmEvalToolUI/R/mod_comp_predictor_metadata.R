#' Test the Predictor Metadata Component
#'
#' @returns A Shiny app object
#'
#' @export
#' @examplesIf have_data()
#' test_comp_predictor_metadata()

test_comp_predictor_metadata <- function() {
  ui <- mod_comp_predictor_metadata_ui()

  server <- function(input, output, session) {
    mod_comp_predictor_metadata_server(
      model_id = reactive("bam_v5_can71")
    )
  }

  shiny::shinyApp(ui, server, options = list(port = 8080))
}

#' Predictor Metadata Component UI
#'
#' @param id Shiny module ID
#'
#' @returns Shiny UI
#'
#' @export
#' @examples
#' mod_comp_predictor_metadata_ui()
mod_comp_predictor_metadata_ui <- function(id = "comp_predictor_metadata") {
  tagList(
    reactable::reactableOutput(NS(id, "predictor_metadata"))
  )
}


mod_comp_predictor_metadata_server <- function(
  id = "comp_predictor_metadata",
  model_id
) {
  moduleServer(id, function(input, output, session) {
    predictor_metadata <- reactive(predictor_metadata_prep(model_id()))
    output$predictor_metadata <- leaflet::renderLeaflet({
      predictor_metadata() |>
        predictor_metadata_table()
    })
  })
}


#' Create a Table for Predictor Metadata
#'
#' @param predictor_metadata Data frame. Predictor metadata
#'
#' @returns A reactable table object
#'
#' @export
#' @examplesIf have_data()
#' skip_eg()
#' # predictor_metadata_prep("bam_v5_can71") |> predictor_metadata_table()

predictor_metadata_table <- function(predictor_metadata) {
  validate(need(
    nrow(predictor_metadata) > 0,
    "No predictor metadata to display"
  ))
  reactable::reactable(predictor_metadata)
}

#' Prepare Predictor Metadata Data
#'
#' @param model_id Character. Model ID
#'
#' @returns Data frame
#'
#' @export
#' @examplesIf have_data()
#' skip_eg()
#' predictor_metadata_prep("bam_v5_can71")

predictor_metadata_prep <- function(model_id) {
  prep_materials("predictor_metadata", model_id = model_id)
}
