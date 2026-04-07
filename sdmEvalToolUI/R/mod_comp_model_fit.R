#' Test the Model Fit Component
#'
#' @param ... Arguments passed to other functions.
#'
#' @returns A Shiny app object
#'
#' @export
#' @examplesIf have_data()
#' test_comp_model_fit()
test_comp_model_fit <- function(...) {
  test_comp("mod_comp_model_fit", use = c("model_id", "species_id"), ...)
}

#' Model Fit Component UI
#'
#' @param id Shiny module ID
#' @param header Header
#'
#' @returns Shiny UI
#'
#' @export
#' @examples
#' mod_comp_model_fit_ui()

mod_comp_model_fit_ui <- function(id = "comp_model_fit", header = NULL) {
  sdm_card(
    class = "p-0 sub-card",
    header,
    reactable::reactableOutput(NS(id, "model_fit")),
    card_footer(shiny::textOutput(NS(id, "model_fit_legend")))
  )
}

#' Model Fit Component Server
#'
#' @param id Module ID
#' @param model_id Model ID
#' @param species_id Species ID
#'
#' @returns Module server function
#'
#' @export
mod_comp_model_fit_server <- function(
  id = "comp_model_fit",
  model_id,
  species_id
) {
  moduleServer(id, function(input, output, session) {
    model_fit <- reactive(model_fit_prep(model_id(), species_id()))
    output$model_fit_legend <- renderText({
      get_material_settings(model_fit())$legend[["en"]]
    })
    output$model_fit <- reactable::renderReactable(model_fit_table(model_fit()))
  })
}


#' Create a Table for Model Fit Data
#'
#' @param model_fit Data frame with model fit information
#'
#' @returns Reactable table
#'
#' @export
#' @examplesIf have_data()
#' model_fit_prep(model_id = "bam_v5_can71", species_id = "BBWO") |>
#'   model_fit_table()

model_fit_table <- function(model_fit) {
  reactable::reactable(
    model_fit,
    defaultPageSize = nrow(model_fit),
    minRows = nrow(model_fit),
    columns = list(
      value = reactable::colDef(format = reactable::colFormat(digits = 3))
    ),
    searchable = TRUE
  )
}

#' Prepare Model Fit Data
#'
#' @param model_id Character. Model ID
#' @param species_id Character. Species ID
#'
#' @returns Data frame
#'
#' @export
#' @examplesIf have_data()
#' model_fit_prep(model_ = "bam_v5_can71", species_id = "BBWO")

model_fit_prep <- function(model_id, species_id) {
  prep_materials("model_fit", model_id = model_id, species_id = species_id)
}
