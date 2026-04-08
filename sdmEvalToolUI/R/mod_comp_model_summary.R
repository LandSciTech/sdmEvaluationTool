#' Test the Model Summary Component
#'
#' @param ... Arguments passed to other functions.
#'
#' @returns A Shiny app object
#'
#' @export
#' @examplesIf have_data()
#' test_comp_model_summary()

test_comp_model_summary <- function(...) {
  test_comp("mod_comp_model_summary", use = c("model_id", "species_id"), ...)
}

#' Model Summary Component UI
#'
#' @param id Shiny module ID
#' @param header Header
#'
#' @returns Shiny UI
#'
#' @export
#' @examples
#' mod_comp_model_summary_ui()

mod_comp_model_summary_ui <- function(
  id = "comp_model_summary",
  header = "Model Summary"
) {
  sdm_card(
    class = "p-0 sub-card",
    sdm_card_header(header),
    reactable::reactableOutput(NS(id, "model_summary")),
    card_footer(shiny::textOutput(NS(id, "model_summary_legend")))
  )
}

#' Model Summary component Server
#'
#' @param id Module ID
#' @param model_id Model ID
#' @param species_id Species ID
#'
#' @returns Module server function
#'
#' @export

mod_comp_model_summary_server <- function(
  id = "comp_model_summary",
  model_id,
  species_id
) {
  moduleServer(id, function(input, output, session) {
    model_summary <- reactive(model_summary_prep(model_id(), species_id()))
    output$model_summary_legend <- renderText({
      get_material_settings(model_summary())$legend[["en"]]
    })
    output$model_summary <- reactable::renderReactable(model_summary_table(model_summary()))
  })
}


#' Create a Table for Model Summary Data
#'
#' @param model_summary Data frame. Model summary information
#'
#' @returns A reactable table object
#'
#' @export
#' @examplesIf have_data()
#' model_summary_prep(model_id = "bam_v5_can71", species_id = "BBWO") |>
#'   model_summary_table()

model_summary_table <- function(model_summary) {
  if (nrow(model_summary) > 50) {
    size <- 50
  } else {
    size <- nrow(model_summary)
  }
  reactable::reactable(
    model_summary,
    searchable = TRUE,
    defaultPageSize = size,
    minRows = size,
    columns = list(
      mean_rel_inf = reactable::colDef(
        format = reactable::colFormat(digits = 3)
      ),
      sd_rel_inf = reactable::colDef(
        format = reactable::colFormat(digits = 3)
      )
    )
  )
}

#' Prepare Model Summary Data
#'
#' @param model_id Character. Model ID
#' @param species_id Character. Species ID
#'
#' @returns Data frame
#'
#' @export
#' @examplesIf have_data()
#' model_summary_prep(model_id = "bam_v5_can71", species_id = "BBWO")

model_summary_prep <- function(model_id, species_id) {
  prep_materials(
    "model_summary",
    model_id = model_id,
    species_id = species_id
  )
}
