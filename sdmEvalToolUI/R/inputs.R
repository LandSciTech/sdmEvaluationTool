# Single inputs -----------------------------------------------------------

#' Text input for Shiny app
#'
#' Used programmatically by [ui_questions()] depending on the question type.
#' See `get()` usage in `ui_questions()`.
#'
#' @noRd
simple_text_input <- function(...) {
  expand_dots(...)
  textInput(input_id_ns, label, value = response, width = width)
}

#' Yes/No input for Shiny app
#'
#' Used programmatically by [ui_questions()] depending on the question type.
#' See `get()` usage in `ui_questions()`.
#'
#' @noRd
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

#' Ordinal input for Shiny app
#'
#' Used programmatically by [ui_questions()] depending on the question type.
#' See `get()` usage in `ui_questions()`.
#'
#' @noRd
ordinal_input <- function(...) {
  expand_dots(...)
  selectInput(
    inputId = input_id_ns,
    label = label,
    choices = c(
      # NOTE: If modifying these options, must also update `affirmative()`
      # function to define what constitutes a 'positive'/'affirmative' response.
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

#' Spatial input collection for Shiny app
#'
#' Used programmatically by [ui_questions()] depending on the question type.
#' See `get()` usage in `ui_questions()`.
#'
#' Creates a collection of selective inputs to definie spatial selections
#' corresponding to different spatial values.
#'
#' NOTE: If changing the spatial value options, must also update [affirmative()],
#' to ensure the 'positive'/'affirmative' values match.
#'
#' @noRd
spatial_input <- function(
  ...,
  spatial_type = c("points", "subunits")
) {
  expand_dots(...)

  id_inputs <- purrr::map(values, \(v) {
    selectizeInput(
      inputId = glue::glue("{input_id_ns}-{value_to_input(v)}"),
      label = HTML(glue::glue("Identify {strong(v)} {spatial_type}")),
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
#' data frame.
#'
#' @param questions Data frame prepared by `prep_questions()` for a specific
#' `user_id`.
#' @param spatial_ids Character vector. [NOT CURRENTLY USED, see
#'   [ui_questions_update()]]. Only applies if using 'client-side selectize'.
#'   All possible Spatial ID options for spatial inputs choices. Generally
#'   passed in as ReactiveVal (see [mod_page_template_spatial_server()].
#' @param spatial_type Character. Spatial type, either `points` or `areas`.
#' @param width Numeric. Optional width of Shiny UI input.
#'
#' @returns Shiny tagList of UI elements
#'
#' @export
#' @examplesIf have_data()
#' q <- prep_questions(
#'   "test",
#'   "deployment1",
#'   "bam_v5_can71",
#'   "BBWO",
#'   user_id = "testuser"
#' )
#' ui_questions(q, spatial_type = "points")
#'
#' q <- prep_questions(
#'   "observations",
#'   "deployment1",
#'   "bam_v5_can71",
#'   "BBWO",
#'   user_id = "testuser"
#' )
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
  # Grab current namespacing
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


#' Update existing Spatial Shiny inputs
#'
#' Because there many be many possible selections for Spatial inputs, we use
#' Serve-side processing to speed things up. This means that we initialize the
#' Spatial input, and then we have to update it with the spatial input options
#' (i.e. the list of spatial ids in the drop down menu). This function performs
#' that update when the ids are ready (see the use of [ui_questions_update()] in
#' [mod_utils_evaluations_server()].
#'
#' @param questions Data frame prepared by `prep_questions()` for a specific
#' `user_id`.
#' @param spatial_ids Character vector. [NOT CURRENTLY USED, see
#'   [ui_questions_update()]]. Only applies if using 'client-side selectize'.
#'   All possible Spatial ID options for spatial inputs choices. Generally
#'   passed in as ReactiveVal (see [mod_page_template_spatial_server()].
#'
#' @returns Nothing. Performs Javascript update (see [updateSelectizeInput()]).
#'
#' @export
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

#' Helper function to format Question values as Shiny Input names
#'
#' @param v Character vector of Question values.
#'
#' @returns Character string of values formatted for Shiny Inputs
#'
#' @export
#' @examples
#' value_to_input("Strongly Agree")

value_to_input <- function(v) {
  stringr::str_replace_all(v, " ", "_")
}

#' Helper function to format Shiny Input names as Question Values
#'
#' @param i Character vector of Input names
#'
#' @returns Character string of Shiny Inputs names formatted as Question values
#'
#' @export
#' @examples
#' input_to_value("Strongly_Agree")

input_to_value <- function(i) {
  stringr::str_replace_all(i, "_", " ")
}

#' Create vector of values to use downstream
#'
#' Creates a vector of Spatial values to use downstream when referencing parent
#' values in followup questions.
#'
#' @param v Character vector of Questions values.
#'
#' @returns Character vector of Question values formatted for Shiny Inputs,
#' including only spatial values.
#'
#' @export
#' @examples
#' parent_vals(c("Slightly agree", "Very biased", "Moderately biased"))

parent_vals <- \(v) {
  v <- value_to_input(unlist(v))
  v[v %in% affirmative("spatial")]
}
