# Single inputs -----------------------------------------------------------

simple_text_input <- function(...) {
  expand_dots(...)
  textInput(id, label)
}

yes_no_input <- function(...) {
  expand_dots(...)
  radioButtons(
    inputId = id,
    label = label,
    choices = c("Yes" = TRUE, "No" = FALSE),
    selected = character(),
    inline = TRUE
  )
}

slider_input <- function(...) {
  expand_dots(...)
  sliderInput(inputId = id, label = label, value = 0, min = 0, max = 10)
}

gold_standard_input <- function(...) {
  expand_dots(...)
  selectInput(
    inputId = id,
    label = label,
    choices = c(
      "Choose one" = "",
      "Gold" = 5,
      "Silver" = 4,
      "Bronze" = 3,
      "Deficient" = 2,
      "Unknown" = 1
    )
  )
}


ordinal_input <- function(...) {
  expand_dots(...)
  selectInput(
    inputId = id,
    label = label,
    choices = c(
      "Choose one" = "",
      "Extremely" = 2,
      "Very" = 1,
      "Moderately" = 0,
      "Slightly" = -1,
      "Not at all" = -2,
      "Uncertain" = NA #TODO: What should uncertain (or above, Unknown) score as?
    )
  )
}

spatial_input <- function(..., spatial_type = c("points", "subunits")) {
  expand_dots(...)
  id_inputs <- purrr::map(values, \(v) {
    selectizeInput(
      inputId = glue::glue("{id}-{v}"),
      label = HTML(glue::glue("Identify any {strong(v)} {spatial_type}")),
      choices = c("Add selected IDs" = "", spatial_ids),
      multiple = TRUE,
      options = list(delimiter = ",", create = TRUE, persist = FALSE)
    )
  })

  tagList(
    strong(label),
    div(class = "sub-question", !!!id_inputs),
    actionButton(
      inputId = paste0(id, "-show"),
      label = glue::glue("Show identified {spatial_type}")
    )
    #textOutput(inputId = paste0(id, "-problem"))
  )
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
#' ui_questions(q, spatial_type = "points", session = dummy_session)
#' q <- prep_questions("observations", "deployment1", "bam_v5_can71", "BBWO")
#' ui_questions(q, spatial_type = "areas", session = dummy_session)

ui_questions <- function(
  questions,
  spatial_ids = NULL,
  spatial_type = "points",
  session
) {
  ui <- dplyr::select(
    questions,
    "type",
    "id",
    "label",
    "part",
    "values"
  ) |>
    purrr::pmap(\(type, id, label, part, values) {
      i <- get(glue::glue("{type}_input"))(
        id = session$ns(id),
        label = label,
        values = unlist(values),
        spatial_ids = spatial_ids,
        spatial_type = spatial_type
      )

      # Follow up questions
      if (part > 0) {
        i <- div(class = "sub-question", i)
      }

      i
    })

  tagList(
    ui,
    actionButton(inputId = session$ns("save"), label = "Save Responses")
  )
}
