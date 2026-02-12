#' Test the Overview Page
#'
#' @returns A Shiny app object
#' @noRd
#'
#' @examplesIf have_data()
#' test_page_overview()
#' test_page_overview(user_id = "testuser")

test_page_overview <- function(...) {
  test_page("mod_page_overview", ...)
}

#' Overview Page UI
#'
#' @param id Shiny module ID
#' @param title Page title
#'
#' @returns Shiny UI
#'
#' @export
#' @examples
#' mod_page_overview_ui("id", "title")

mod_page_overview_ui <- function(id, title) {
  nav_panel(
    title = title,
    value = id,
    sdm_card(
      card_header(
        "Current status of review",
        actionButton(
          NS(id, "refresh"),
          label = NULL,
          icon = icon("arrows-rotate"),
          class = "btn-mini btn-outline-success"
        )
      ),

      reactable::reactableOutput(NS(id, "tbl_overview"))
    )
  )
}

#' Overview Page Server
#'
#' @param id Shiny module ID
#' @param ... Additional arguments passed via expand_dots including
#' deployment_id, model_id, species_id, and overview_inputs (reactiveVal)
#'
#' @returns Server function for Shiny module
#'
#' @export

mod_page_overview_server <- function(id = "overview", ...) {
  # Expected arguments
  expand_dots(...)
  stopifnot(is.reactive(deployment_id))
  stopifnot(is.reactive(model_id))
  stopifnot(is.reactive(species_id))
  stopifnot(is.reactive(overview_inputs)) # reactiveVal
  stopifnot(is.reactive(overview_update)) # reactiveVal
  stopifnot(is.reactive(abandoned)) # reactiveVal

  purrr::walk(opts, \(o) stopifnot(is.reactive(o)))

  moduleServer(id, function(input, output, session) {
    # Setup
    tbl_updated <- reactiveVal(FALSE) # Tracks when tbl is updated so we can unnest the first column

    # Table for display
    tbl <- reactive({
      evals_details(opts$user_id(), opts$user_role())
    }) |>
      bindEvent(
        opts$user_id(),
        opts$user_role(),
        input$refresh,
        overview_update()
      )

    # Table for input keys
    tbl_top <- reactive({
      tbl() |>
        dplyr::select("deployment_id", "model_id", "species_id") |>
        dplyr::distinct()
    })

    # Mark abandoned
    observe({
      req(tbl(), deployment_id(), model_id())
      if (species_id() == "") {
        s <- "ALL"
      } else {
        s <- species_id()
      }
      a <- dplyr::filter(
        tbl(),
        .data$deployment_id == deployment_id(),
        .data$model_id == model_id(),
        .data$species_id == s
      ) |>
        dplyr::select(
          "abandoned",
          "model_abandoned",
          "deployment_model_name",
          "species_id"
        ) |>
        dplyr::distinct()
      abandoned(a$abandoned || a$model_abandoned)
    })

    output$tbl_overview <- reactable::renderReactable({
      validate(
        need(opts$user_id(), "Please select a user"),
        need(opts$user_role(), "Please select a user role")
      )
      validate(
        need(
          nrow(tbl()) > 0,
          "No deployments for this user in this role"
        )
      )
      tbl_updated(TRUE)

      # Render table
      evals_table(tbl(), opts$user_role())
    })

    # Grab row inputs as Dep/model/species inputs
    observe({
      # Update reactiveVal created by sdm_tool()
      i <- tbl_top() |>
        dplyr::slice(input$button_clicked) |>
        as.list()

      overview_inputs(i)
    }) |>
      bindEvent(input$button_clicked, ignoreInit = TRUE)

    # Expand first tier of nested groups when table updated/created
    observe({
      req(tbl_updated())

      shinyjs::delay(200, {
        for (i in seq_len(dplyr::n_distinct(tbl()$deployment_id))) {
          shinyjs::runjs(
            "var btn = document.querySelector(\".sdm-header .rt-expander-button[aria-expanded='false']\");
          btn.click();"
          )
        }
      })
      tbl_updated(FALSE)
    }) |>
      bindEvent(tbl_updated(), ignoreInit = TRUE)
  })
}

#' Create a Reactable Overview table
#'
#' Creates reactable table displaying evaluation progress for either modelers or
#' evaluators. The table shows deployment-model combinations, species,
#' components, and their completion status.
#'
#' @param tbl Data frame. Evaluation details from `evals_details()`
#' @param user_role Character. User role ("modeler" or "evaluator")
#'
#' @returns A reactable table object
#'
#' @export
#' @examplesIf have_data()
#' #tbl <- evals_details("holden", "modeler")
#' #evals_table(tbl, "modeler")
#' #tbl <- evals_details("draper", "evaluator")
#' #evals_table(tbl, "evaluator")
#' tbl <- evals_details("testuser", "evaluator")
#' evals_table(tbl, "evaluator")

evals_table <- function(tbl, user_role) {
  # If evaluator only show evaluations created
  # If modeler only show deployments created
  group_by <- "deployment_model_name"
  if (user_role == "modeler") {
    group_by <- c(group_by, "evaluation_create_user_name")
  }

  # Grouped tables https://glin.github.io/reactable/articles/examples.html?q=collaps#grouping-and-aggregation
  # Nested tables https://glin.github.io/reactable/articles/examples.html?q=collaps#nested-tables

  #pal <- c("white", grDevices::colorRampPalette(c("#d9fbfb", "#081a1c"))(100))
  # scales::show_col(pal, ncol = 10)
  pal <- c("white", grDevices::colorRampPalette(c("#88A187", "#031F02"))(100))
  pal_text <- c(rep("black", 50), rep("white", 101 - 50))

  tbl_components <- tbl

  tbl_top <- tbl |>
    dplyr::summarize(
      progress = sum(.data$n_q_complete) / sum(.data$n_q),
      .by = c(
        "deployment_model_name",
        "evaluation_create_user_name",
        "species_display",
        "species_id", # Key which determines button presence
        "abandoned",
        "model_abandoned"
      )
    ) |>
    dplyr::mutate(button = NA) |>
    dplyr::relocate("button", .after = "species_display")

  deployment_width <- 250

  reactable::reactable(
    tbl_top,
    groupBy = group_by,
    defaultColDef = reactable::colDef(
      vAlign = "center",
      headerVAlign = "bottom"
    ),
    # Sub Table with component-level progress
    details = function(index) {
      comp <- dplyr::filter(
        tbl_components,
        .data$deployment_model_name == tbl_top$deployment_model_name[index],
        .data$species_display == tbl_top$species_display[index]
      ) |>
        dplyr::mutate(
          progress_perc = round(.data$n_q_complete / .data$n_q * 100)
        ) |>
        dplyr::select(
          "Component" = "component_name",
          "Progress" = "n_q_display",
          "progress_perc"
        )
      div(
        # fmt: skip
        style = paste0(
          "margin-left:", deployment_width * 1.2, "px;",
          "margin-bottom: 20px"),
        reactable::reactable(
          comp,
          outlined = TRUE,
          width = 558,
          columns = list(
            progress_perc = reactable::colDef(show = FALSE),
            Progress = reactable::colDef(
              align = "center",
              maxWidth = 150,
              # Colour by percent complete
              style = \(v, i) {
                bg <- pal[comp$progress_perc[i]]
                txt <- pal_text[comp$progress_perc[i]]
                list(background = bg, color = txt)
              }
            )
          )
        )
      )
    },
    columns = list(
      species_id = reactable::colDef(show = FALSE),
      model_abandoned = reactable::colDef(show = FALSE),
      # Button column
      button = reactable::colDef(
        align = "center",
        name = "",
        sortable = FALSE,
        maxWidth = 175,
        cell = \(v, i) {
          if (!is.na(tbl_top$species_id[i]) & tbl_top$species_id[i] != "ALL") {
            tags$button(
              "Select Species",
              class = "btn btn-sm btn-species",
              width = 175
            )
          } else {
            tags$button(
              "Select Model only",
              class = "btn btn-sm btn-model",
              width = 175
            )
          }
        }
      ),
      abandoned = reactable::colDef(
        name = "",
        align = "left",
        sortable = FALSE,
        cell = \(v, i) {
          if (tbl_top$model_abandoned[i]) {
            "Model Abandoned"
          } else if (tbl_top$abandoned[i]) {
            "Species Abandoned"
          } else if (tbl_top$progress[i] == 1) {
            "All Answered"
          }
        },
        style = \(v, i) {
          s <- "black"
          if (tbl_top$abandoned[i]) {
            s <- "dimgrey"
          } else if (tbl_top$progress[i] == 1) {
            s <- pal[20]
          }
          list(color = s, `font-style` = "italic")
        }
      ),
      deployment_model_name = reactable::colDef(
        name = "Deployment - Model",
        html = TRUE,
        minWidth = 200,
        maxWidth = 250,
        class = "sdm-header",
        grouped = reactable::JS(
          "function(cellInfo, state) {
        let [d, m] = cellInfo.value.split('---');

        d = `<span style = 'font-weight:600'>${d}</span>`
        m = `<div style = 'padding-left:20px; font-size:0.75rem'>${m}</div>`

      return `${d}<br>${m}`
      }"
        )
      ),
      evaluation_create_user_name = reactable::colDef(
        name = "Evaluator",
        minWidth = 200,
        maxWidth = 250,
        show = user_role == "modeler"
      ),
      species_display = reactable::colDef(
        name = "Species",
        html = TRUE,
        minWidth = 200,
        maxWidth = 400,
        cell = \(v, i) {
          if (!stringr::str_detect(v, "Model")) {
            s <- span(
              stringr::str_extract(v, "^[^\\(]+\\("),
              span(
                stringr::str_extract(v, "(?<=\\().+(?=\\))"),
                style = "font-style:italic;"
              ),
              ")"
            )
          } else {
            s <- v
          }
          if (tbl_top$abandoned[i]) {
            s <- span(s, style = "color:darkgrey;")
          } else if (tbl_top$progress[i] == 1) {
            s <- span(s, style = paste0("color:", pal[20], ";"))
          }
          s
        }
      ),
      progress = reactable::colDef(
        name = "Progress",
        align = "center",
        minWidth = 100,
        maxWidth = 150,
        format = reactable::colFormat(percent = TRUE, digits = 0),

        # Colour by percent complete
        style = \(v) {
          bg <- pal[round(v * 100)]
          txt <- pal_text[round(v * 100)]
          list(background = bg, color = txt)
        }
      )
    ),
    meta = list(pal = pal, pal_text = pal_text),
    highlight = TRUE,
    onClick = reactable::JS(
      "function(rowInfo, column) {
         // Only handle click events on this column specifically
         if (column.id !== 'button') {
           return
         }
  
         Shiny.setInputValue('overview-button_clicked', rowInfo.index + 1, { priority: 'event' })
      }"
    )
  )
}
