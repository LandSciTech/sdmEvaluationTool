#' Title
#'
#' @returns
#'
#' @export
#' @examples
#' test_comp_model_metadata()
test_comp_model_metadata <- function() {
  ui <- mod_comp_model_metadata_ui()

  server <- function(input, output, session) {
    mod_comp_model_metadata_server(
      model_id = reactive("bam_v5_can71")
    )
  }

  shiny::shinyApp(ui, server, options = list(port = 8080))
}

#' Title
#'
#' @param id
#'
#' @returns
#'
#' @export
#' @examples
mod_comp_model_metadata_ui <- function(id = "comp_model_metadata") {
  tagList(
    "Placeholder for UI elements"
  )
}


mod_comp_model_metadata_server <- function(
  id = "comp_model_metadata",
  model_id
) {
  moduleServer(id, function(input, output, session) {
    stopifnot(is.reactive(model_id))

    model_metadata <- reactive(model_metadata_prep(model_id()))
    output$model_metadata <- leaflet::renderLeaflet({
      model_metadata() |>
        model_metadata_XXXX()
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
#' model_metadata_prep(model_id = "bam_v5_can71") |>
#'   model_metadata_XXXX()

model_metadata_XXXX <- function(model_metadata) {
  #TODO: Model metadata display
}

#' Title
#'
#' @param obs
#'
#' @returns
#'
#' @export
#' @examples
#' model_metadata_prep(model_id = "bam_v5_can71")

model_metadata_prep <- function(model_id) {
  prep_files("model_metadata", model_id = model_id)
}
