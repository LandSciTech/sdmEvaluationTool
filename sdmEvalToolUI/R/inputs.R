# Single inputs -----------------------------------------------------------

simple_text_input <- function(...) {
  expand_dots(...)
  textInput(id_ns, label, value = response)
}

# yes_no_input <- function(...) {
#   expand_dots(...)
#   radioButtons(
#     inputId = id_ns,
#     label = label,
#     choices = c("Yes" = TRUE, "No" = FALSE),
#     selected = response,
#     inline = TRUE
#   )
# }

# slider_input <- function(...) {
#   expand_dots(...)
#   sliderInput(inputId = id_ns, label = label, value = 0, min = 0, max = 10)
# }

# gold_standard_input <- function(...) {
#   expand_dots(...)
#   selectInput(
#     inputId = id_ns,
#     label = label,
#     choices = c(
#       "Choose one" = "",
#       "Gold" = 5,
#       "Silver" = 4,
#       "Bronze" = 3,
#       "Deficient" = 2,
#       "Unknown" = 1
#     )
#   )
# }

ordinal_input <- function(...) {
  expand_dots(...)
  selectInput(
    inputId = id_ns,
    label = label,
    choices = c(
      "Choose one" = "",
      "Extremely",
      "Very",
      "Moderately",
      "Slightly",
      "Not at all",
      "Uncertain"
    ),
    selected = response
  )
}

spatial_input <- function(
  ...,
  spatial_type = c("points", "subunits")
) {
  expand_dots(...)

  id_inputs <- purrr::map(values, \(v) {
    selectizeInput(
      inputId = glue::glue("{id_ns}-{value_to_input(v)}"),
      label = HTML(glue::glue("Identify any {strong(v)} {spatial_type}")),
      choices = c("Add selected IDs" = ""),
      multiple = TRUE,
      options = list(delimiter = ",", create = TRUE, persist = FALSE)
    )
  })

  tagList(
    strong(label),
    div(class = "sub-question", !!!id_inputs),
    actionButton(
      inputId = paste0(id_ns, "-show"),
      label = glue::glue("Show identified {spatial_type}")
    )
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
#' @param spatial_ids Spatial IDs
#' @param spatial_type Spatial type
#' @param which Which
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
  which = "ui",
  session
) {
  ui <- dplyr::select(
    questions,
    "type",
    "id_ns",
    "label",
    "part",
    "values",
    "response"
  ) |>
    purrr::pmap(\(type, id_ns, label, part, values, response) {
      i <- get(glue::glue("{type}_input"))(
        id_ns = id_ns,
        label = label,
        values = unlist(values),
        spatial_ids = spatial_ids,
        spatial_type = spatial_type,
        response = response,
        which = which
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


ui_questions_update <- function(questions, spatial_ids = NULL) {
  q <- questions |>
    dplyr::filter(.data$type == "spatial") |>
    dplyr::select("id", "values", "response")

  if (any(!is.na(q$response))) {
    q <- q |>
      dplyr::mutate(
        response = purrr::map(.data$response, \(r) r[[names(r) != "values"]])
      ) |>
      tidyr::unnest(cols = c("values", "response"))
  } else {
    q <- q |>
      tidyr::unnest(cols = "values") |>
      dplyr::mutate(subunits = NA)
  }

  q <- q |>
    dplyr::mutate(
      id = glue::glue("{id}-{value_to_input(values)}")
    )

  id <- dplyr::pull(q, .data$id)
  selected <- dplyr::pull(q, "subunits")

  purrr::map2(id, selected, \(i, s) {
    updateSelectizeInput(
      inputId = i,
      choices = spatial_ids,
      selected = s,
      server = TRUE
    )
  })
}

value_to_input <- function(v) {
  stringr::str_replace_all(v, " ", "_")
}

input_to_value <- function(i) {
  stringr::str_replace_all(i, "_", " ")
}
