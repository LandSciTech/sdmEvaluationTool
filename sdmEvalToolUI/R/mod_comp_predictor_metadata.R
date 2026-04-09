#' Test the Predictor Metadata Component
#'
#' @param ... Arguments passed to other functions.
#'
#' @returns A Shiny app object
#'
#' @export
#' @examplesIf have_data()
#' test_comp_predictor_metadata()

test_comp_predictor_metadata <- function(...) {
  test_comp("mod_comp_predictor_metadata", use = "model_id", ...)
}

#' Predictor Metadata Component UI
#'
#' @param id Shiny module ID
#' @param height Height
#' @param header Header
#'
#' @returns Shiny UI
#'
#' @export
#' @examples
#' mod_comp_predictor_metadata_ui()

mod_comp_predictor_metadata_ui <- function(
  id = "comp_predictor_metadata",
  height = "40%",
  header = "Predictor Metadata"
) {
  sdm_card(
    min_height = height,
    class = "sub-card",
    sdm_card_header(header, uiOutput(NS(id, "tooltip"))),
    card_body(reactable::reactableOutput(NS(id, "predictor_metadata")))
  )
}

#' Predictor Metadata component Server
#'
#' @param id Module ID
#' @param model_id Model ID
#'
#' @returns Module server function
#'
#' @export

mod_comp_predictor_metadata_server <- function(
  id = "comp_predictor_metadata",
  model_id
) {
  moduleServer(id, function(input, output, session) {
    predictor_metadata <- reactive(predictor_metadata_prep(model_id()))
    output$tooltip <- renderUI(tt_material_settings(predictor_metadata()))
    output$predictor_metadata <- reactable::renderReactable({
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
#' predictor_metadata_prep("bam_v5_can71") |>
#'   predictor_metadata_table()

predictor_metadata_table <- function(predictor_metadata) {
  validate(need(
    nrow(predictor_metadata) > 0,
    "No predictor metadata to display"
  ))
  reactable::reactable(
    predictor_metadata,
    defaultPageSize = nrow(predictor_metadata),
    pagination = FALSE,
    highlight = TRUE,
    searchable = TRUE,
    details = \(i) {
      tagList(
        div(
          style = "padding-left: 2em;",
          p(
            style = "margin: 0.5em;",
            strong("Provider: "),
            predictor_metadata$provider[i]
          ),
          p(
            style = "margin: 0.5em;",
            strong("Source: "),
            a(
              href = predictor_metadata$source[i],
              predictor_metadata$source[i]
            )
          ),
          p(
            style = "margin: 0.5em;",
            strong("Citation: "),
            predictor_metadata$citation[i]
          )
        )
      )
    },
    defaultColDef = reactable::colDef(minWidth = 175),
    columns = list(
      # From reactable docs
      predictor = reactable::colDef(
        sticky = "left",
        # Add a right border style to visually distinguish the sticky column
        style = list(borderRight = "1px solid #eee"),
        headerStyle = list(borderRight = "1px solid #eee")
      ),
      covariate_extraction = reactable::colDef(minWidth = 200),
      prediction_resolution = reactable::colDef(minWidth = 200),
      temporal_matching = reactable::colDef(minWidth = 200),
      provider = reactable::colDef(show = FALSE),
      citation = reactable::colDef(show = FALSE),
      source = reactable::colDef(show = FALSE)
    )
  )
}

#' Prepare Predictor Metadata Data
#'
#' @param model_id Character. Model ID
#'
#' @returns Data frame
#'
#' @export
#' @examplesIf have_data()
#' predictor_metadata_prep("bam_v5_can71")

predictor_metadata_prep <- function(model_id) {
  prep_materials("predictor_metadata", model_id = model_id)
}
