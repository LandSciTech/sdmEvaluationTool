#' Test the Template Component
#'
#' @param ... Arguments passed to other functions.
#'
#' @returns A Shiny app object
#'
#' @export
#' @examplesIf have_data()
#' test_comp_template()

test_comp_template <- function(...) {
  test_comp("mod_comp_template", use = c("model_id", "species_id"), ...)
}

#' Template Component UI
#'
#' @param id Shiny module ID
#' @param header Header
#'
#' @returns Shiny UI
#'
#' @export
#' @examples
#' mod_comp_template_ui()

mod_comp_template_ui <- function(id = "comp_template", header = NULL) {
  sdm_card(
    header,
    reactable::reactableOutput(NS(id, "template"))
  )
}


mod_comp_template_server <- function(
  id = "comp_template",
  model_id,
  species_id
) {
  # NOTE: No deployment id required because materials only associated
  #   with model and species

  moduleServer(id, function(input, output, session) {
    template <- reactive(template_prep(model_id(), species_id()))
    output$template <- reactable::renderReactable(template_table(template()))
  })
}


#' Create a Table for Template Data
#'
#' @param template Data frame with template information
#'
#' @returns Reactable table
#'
#' @export
#' @examplesIf have_data()
#' template_prep(model_id = "bam_v5_can71", species_id = "BBWO") |>
#'   template_table()

template_table <- function(template) {
  reactable::reactable(
    template,
    defaultPageSize = nrow(template),
    minRows = nrow(template),
    columns = list(
      disp = reactable::colDef(format = reactable::colFormat(digits = 3))
    ),
    searchable = TRUE
  )
}

#' Prepare Template Data
#'
#' @param model_id Character. Model ID
#' @param species_id Character. Species ID
#'
#' @returns Data frame
#'
#' @export
#' @examplesIf have_data()
#' template_prep(model_ = "bam_v5_can71", species_id = "BBWO")

template_prep <- function(model_id, species_id) {
  # TEMPLATE: Normally would use `prep_materials` function to prepare the
  # component materials, see the following example for the "model_fit"
  # component:

  # prep_materials("model_fit", model_id = model_id, species_id = species_id)

  # TEMPLATE: For this example, we'll use dummy data
  datasets::mtcars
}
