# Single inputs -----------------------------------------------------------

simple_text_input <- function(...) {
  expand_dots(...)
  textInput(input_id_ns, label, value = response, width = width)
}

yes_no_input <- function(...) {
  expand_dots(...)

  r <- response %||% character(0)

  radioButtons(
    inputId = input_id_ns,
    label = label,
    choices = c("Yes", "No"),
    selected = r,
    inline = TRUE,
    width = width
  )
}

# slider_input <- function(...) {
#   expand_dots(...)
#   sliderInput(inputId = input_id_ns, label = label, value = 0, min = 0, max = 10)
# }

# gold_standard_input <- function(...) {
#   expand_dots(...)
#   selectInput(
#     inputId = input_id_ns,
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
    inputId = input_id_ns,
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
      inputId = glue::glue("{input_id_ns}-{value_to_input(v)}"),
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
      inputId = glue::glue("{input_id_ns}-show"),
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
#' @param spatial_ids Character vector. All possible Spatial ID options for
#'   spatial inputs choices.
#' @param spatial_type Character. Spatial type, either `points` or `areas`.
#' @param width Numeric. Optional width of Shiny UI input.
#'
#' @returns Shiny tagList of UI elements
#'
#' @export
#' @examplesIf have_data()
#' q <- prep_questions("test", "deployment1", "bam_v5_can71", "BBWO")
#' ui_questions(q, spatial_type = "points")
#' q <- prep_questions("observations", "deployment1", "bam_v5_can71", "BBWO")
#' ui_questions(q, spatial_type = "areas")
#'
#' # More than one component
#' q <- prep_questions(
#'   c("model_fit", "model_summary"),
#'   "deployment2",
#'   "bam_v5_can71",
#'   "BBWO",
#'   user_id = "testuser"
#' )
#' u <- ui_questions(q, spatial_type = "areas")

ui_questions <- function(
  questions,
  spatial_ids = NULL,
  spatial_type = "points",
  width = NULL
) {
  ns <- getDefaultReactiveDomain()$ns %||% \(id) paste0("testing-", id)

  ui <- questions |>
    dplyr::mutate(
      parent_spatial = .data$type[1] == "spatial",
      parent_values = list(parent_vals(.data$values)),
      .by = c("component", "order")
    ) |>
    dplyr::select(
      "component",
      "type",
      "question_id",
      "label",
      "part",
      "values",
      "response",
      "parent_spatial",
      "parent_values"
    ) |>
    dplyr::group_split(.data[["component"]], .keep = FALSE) |>
    purrr::map(\(c) {
      purrr::pmap(
        c,
        \(
          type,
          question_id,
          label,
          part,
          values,
          response,
          parent_spatial,
          parent_values
        ) {
          i <- get(glue::glue("{type}_input"))(
            input_id_ns = ns(question_id),
            label = label,
            values = unlist(values),
            spatial_ids = spatial_ids,
            spatial_type = spatial_type,
            response = response,
            width = width
          )

          # Follow up questions
          if (part > 0) {
            parent_id <- stringr::str_replace(question_id, "\\d+$", "0")
            if (parent_spatial) {
              condition <- glue::glue(
                "input['{parent_id}-{parent_values}'].length > 0"
              ) |>
                glue::glue_collapse(sep = " || ")
            } else {
              condition <- glue::glue(
                "['",
                glue::glue_collapse(affirmative(), sep = "', '"),
                "'].includes(input.{parent_id})"
              )
            }

            i <- conditionalPanel(
              #condition = paste0("input.", parent_id, " == 'Extremely'"),
              condition = condition,
              div(class = "sub-question", i),
              ns = ns
            )
          }

          i
        }
      )
    })

  if (length(ui) > 1) {
    ui <- purrr::map2(ui, fmt_pretty(unique(questions$component)), \(u, c) {
      list(h5(c), u)
    })
  }
  tagList(
    ui,
    shinyjs::hidden(
      radioButtons(
        ns("ready"),
        label = "",
        choices = c("TRUE", "FALSE")
      )
    )
  )
}


ui_questions_update <- function(questions, spatial_ids = NULL) {
  q <- questions |>
    dplyr::filter(.data$type == "spatial") |>
    dplyr::select("question_id", "values", "response")

  q <- q |>
    dplyr::mutate(
      response = purrr::map(.data$response, \(r) {
        r <- if ("subunits" %in% names(r)) r$subunits else r
        r <- if (all(is.null(r) | is.na(r))) NA else r
        r
      })
    ) |>
    tidyr::unnest(cols = c("values", "response")) |>
    dplyr::mutate(
      input_id = glue::glue("{question_id}-{value_to_input(values)}")
    )

  input_id <- dplyr::pull(q, .data$input_id)
  selected <- dplyr::pull(q, "response")

  purrr::map2(input_id, selected, \(i, s) {
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

parent_vals <- \(v) {
  v <- value_to_input(unlist(v))
  v[v %in% affirmative("spatial")]
}
