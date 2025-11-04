#' Title
#'
#' @returns
#'
#' @export
#' @examples
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

#' Title
#'
#' @param id
#' @param title
#'
#' @returns
#'
#' @export
#' @examples
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


#' Title
#'
#' @param obs
#'
#' @returns
#'
#' @export
#' @examples
#' predictor_metadata_prep(model_id = "bam_v5_can71") |>
#'   predictor_metadata_table()

predictor_metadata_table <- function(predictor_metadata) {
  validate(need(
    nrow(predictor_metadata) > 0,
    "No predictor metadata to display"
  ))
  reactable::reactable(predictor_metadata)
}

#' Title
#'
#' @param obs
#'
#' @returns
#'
#' @export
#' @examples
#' predictor_metadata_prep(model_id = "bam_v5_can71")

predictor_metadata_prep <- function(model_id) {
  prep_files("predictor_metadata", model_id = model_id)
}
