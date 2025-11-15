# Single inputs -----------------------------------------------------------

text_input <- function(...) {
  expand_dots(...)
  textInput(id, label)
}

slider_input <- function(...) {
  expand_dots(...)
  sliderInput(inputId = id, label = label, value = 0, min = 0, max = 10)
}

gold_standard_input <- function(...) {
  expand_dots(...)
  sliderInput(inputId = id, label = label, value = 0, min = 0, max = 5)
}

# Specialized UIs --------------------------------------------------------

#' Create dynamic question inputs
#'
#' Create dynamic question inputs in the server using the prepared questions
#' data frame. This is programatically created in the server module and
#' therefore requires the Shiny session object for namespacing.
#'
#' @param questions Data frame prepared by `prep_questions()`.
#' @param session Shiny session object of module namespacing
#'
#' @returns Shiny tagList of UI elements
#'
#' @export
#' @examplesIf have_data()
#' q <- prep_questions("test", "deployment1", "bam_v5_can71", "BBWO")
#' ui_questions(q, dummy_session)
#' q <- prep_questions("observations", "deployment1", "bam_v5_can71", "BBWO")
#' ui_questions(q, dummy_session)

ui_questions <- function(questions, session) {
  ui <- dplyr::select(questions, "ui", "id", "label") |>
    purrr::pmap(\(ui, id, label) {
      get(ui)(id = session$ns(id), label = label)
    })

  tagList(
    ui,
    actionButton(inputId = session$ns("save"), label = "Save Responses")
  )
}
