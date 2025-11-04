#' Title
#'
#' @returns
#' @noRd
#'
#' @examples
#' test_page_overview()

test_page_overview <- function() {
  # TODO: define location, pages, etc. elsewhere
  prep_data() |> expand_list()

  ui <- bslib::page_navbar(
    title = "SDM Tool Testing",
    mod_page_overview_ui()
  )

  server <- function(input, output, session) {
    mod_page_overview_server(
      model_id = reactive("bam_v5_can71"),
      species_id = reactive("BBWO"),
      tbl_materials = tbl_materials,
      tbl_models = tbl_models,
      tbl_species = tbl_species
    )
  }

  shiny::shinyApp(ui, server, options = list(port = 8080))
}

#' Title
#'
#' @param id
#' @param title
#'
#' @returns
#'
#' @export
#' @examples
mod_page_overview_ui <- function(id = "overview", title = "Overview") {
  nav_panel(
    title,
    "Current status of review",
    reactable::reactableOutput(NS(id, "table"))
  )
}

#' Title
#'
#' @param id
#'
#' @returns
#'
#' @export
#' @examples
mod_page_overview_server <- function(id = "overview", ...) {
  moduleServer(id, function(input, output, session) {
    expand_dots(...)

    table <- reactive(tbl_overview(tbl_models, tbl_species, tbl_materials))

    # TODO: Option to click on species/model combination on table to select
    output$table <- reactable::renderReactable({
      reactable::reactable(
        table(),
        highlight = TRUE,
        rowStyle = function(index) {
          if (
            isTruthy(species_id()) &&
              index == which(table()[["species_id"]] == species_id())
          ) {
            list(background = "rgba(0, 0, 0, 0.5)")
          }
        },
        columns = list(
          model_name = reactable::colDef(
            style = reactable::JS(
              "function(rowInfo, column, state) {
              const firstSorted = state.sorted[0]
              // Merge cells if unsorted or sorting by model_name
              if (!firstSorted || firstSorted.id === 'model_name') {
                const prevRow = state.pageRows[rowInfo.viewIndex - 1]
                if (prevRow && rowInfo.values['model_name'] === prevRow['model_name']) {
                  return { visibility: 'hidden' }
                }
              }
            }"
            )
          )
        )
      )
    })
  })
}

tbl_overview <- function(tbl_models, tbl_species, tbl_materials) {
  tbl_materials |>
    dplyr::select("model_id", "species_id", "component_id") |>
    dplyr::filter(!stringr::str_detect(component_id, "^predictor")) |>
    dplyr::mutate(
      done = "yes",
      ready = attr(
        sdmEvalToolCore::get_comp_ready(.data$component_id),
        "percent_ready"
      ),
      .by = c("model_id", "species_id")
    ) |>
    tidyr::complete(
      tidyr::nesting(model_id, species_id),
      component_id,
      fill = list(done = "no")
    ) |>
    tidyr::pivot_wider(names_from = component_id, values_from = done) |>
    fmt_tbl(tbl_models, tbl_species)
}

fmt_tbl <- function(tbl, tbl_models, tbl_species) {
  # TODO: Get pretty column names
  tbl |>
    dplyr::left_join(
      dplyr::select(tbl_species, "species_id", "species_display"),
      by = "species_id"
    ) |>
    dplyr::left_join(
      dplyr::select(tbl_models, "model_id", "model_name"),
      by = "model_id"
    ) |>
    dplyr::select(-"model_id", "species_id") |>
    dplyr::relocate("model_name", "species_display")
}
