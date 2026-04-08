#' Test the Observations Chart Component
#'
#' @param ... Arguments passed to other functions.
#'
#' @returns A Shiny app object
#'
#' @export
#' @examplesIf have_data()
#' test_comp_obs_chart()

test_comp_obs_chart <- function(...) {
  test_comp("mod_comp_obs_chart", use = c("model_id", "species_id"), ...)
}

#' Observations Chart Component UI
#'
#' @param id Character. Shiny module ID
#' @param header Header
#'
#' @returns Shiny UI
#'
#' @export
#' @examples
#' mod_comp_obs_chart_ui()

mod_comp_obs_chart_ui <- function(
  id = "comp_obs_chart",
  header = "Observation Charts"
) {
  sdm_card(
    sdm_card_header(header),
    card_footer(shiny::textOutput(NS(id, "obs_chart_legend"))),
    div(
      style = "display:grid; grid-template-columns: 200px 200px 200px; gap: 10px; padding-bottom:10px;",
      # style = "display:inline-block",
      selectInput(
        NS(id, "summary"),
        label = "Summarize",
        choices = c(
          "Observations" = "nobs",
          "Detections" = "ndet"
        )
      ),
      selectInput(
        NS(id, "groups"),
        label = "Group by",
        choices = c(
          "Year" = "year",
          "Month" = "month",
          "Hours (after sunrise)" = "hours",
          "Method" = "method"
        )
      ),
      selectInput(
        NS(id, "fill"),
        label = "Color by",
        choices = c(
          "None" = "none",
          # "Year" = "year",
          "Month" = "month",
          "Hours (after sunrise)" = "hours",
          "Method" = "method"
        )
      )
    ),
    # Chart output
    layout_column_wrap(
      width = 1 / 2,
      height = 400,
      plotly::plotlyOutput(NS(id, "obs_chart_counts")),
      plotly::plotlyOutput(NS(id, "obs_chart_groups"))
    )
  )
}


#' Observations Chart Component Server
#'
#' @param id Module ID
#' @param model_id Model ID
#' @param species_id Species ID
#'
#' @returns Module server function
#'
#' @export

mod_comp_obs_chart_server <- function(
  id = "comp_obs_chart",
  model_id,
  species_id
) {
  stopifnot(is.reactive(model_id))
  stopifnot(is.reactive(species_id))

  moduleServer(id, function(input, output, session) {
    # Observations -------------------------------------------
    obs <- reactive({
      obs <- sf::st_drop_geometry(obs_prep(model_id(), species_id()))
      dt <- as.POSIXlt(obs$time)
      obs$year <- dt$year + 1900
      obs$month <- factor(month.abb[dt$mo + 1], month.abb)
      obs$hours <- round(obs$hssr)
      obs
    })

    # Legend
    output$obs_chart_legend <- renderText({
      prep_material_settings("observations", model_id(), species_id())$legend[[
        "en"
      ]]
    })

    # Chart -------------------------------------------
    output$obs_chart_counts <- plotly::renderPlotly({
      oo <- obs()
      if (input$summary == "ndet") {
        oo <- oo |> dplyr::filter(.data$status > 0)
      }
      if (input$fill == "none") {
        p_counts <- oo |>
          ggplot2::ggplot(ggplot2::aes(x = .data$status))
      } else {
        p_counts <- oo |>
          ggplot2::ggplot(ggplot2::aes(
            x = .data$status,
            group = .data[[input$fill]],
            fill = as.factor(.data[[input$fill]])
          )) +
          ggplot2::labs(
            fill = tools::toTitleCase(input$fill)
          )
      }
      p_counts <- p_counts +
        ggplot2::geom_bar() +
        ggplot2::theme_light() +
        ggplot2::xlab("Counts") +
        ggplot2::ylab("Frequency") # +
      # ggplot2::scale_y_log10()

      plotly::ggplotly(p_counts) |>
        plotly::config(
          displaylogo = FALSE
        )
    })

    output$obs_chart_groups <- plotly::renderPlotly({
      if (input$fill == "none") {
        det <- obs() |>
          dplyr::mutate(det = ifelse(.data$status > 0, 1, 0)) |>
          dplyr::group_by(.data[[input$groups]]) |>
          dplyr::summarize(
            nobs = dplyr::n(),
            ndet = sum(det),
            .groups = "keep"
          )
        p_groups <- det |>
          ggplot2::ggplot(ggplot2::aes(
            x = .data[[input$groups]],
            y = .data[[input$summary]]
          ))
      } else {
        if (input$groups == input$fill) {
          det <- obs() |>
            dplyr::mutate(det = ifelse(.data$status > 0, 1, 0)) |>
            dplyr::group_by(
              .data[[input$groups]]
            ) |>
            dplyr::summarize(
              nobs = dplyr::n(),
              ndet = sum(det),
              .groups = "keep"
            )
          p_groups <- det |>
            ggplot2::ggplot(ggplot2::aes(
              x = .data[[input$groups]],
              y = .data[[input$summary]],
              fill = as.factor(.data[[input$groups]])
            )) +
            ggplot2::labs(fill = tools::toTitleCase(input$groups))
        } else {
          det <- obs() |>
            dplyr::mutate(det = ifelse(.data$status > 0, 1, 0)) |>
            dplyr::group_by(
              .data[[input$groups]],
              .data[[input$fill]]
            ) |>
            dplyr::summarize(
              nobs = dplyr::n(),
              ndet = sum(det),
              .groups = "keep"
            )
          p_groups <- det |>
            ggplot2::ggplot(ggplot2::aes(
              x = .data[[input$groups]],
              y = .data[[input$summary]],
              fill = as.factor(.data[[input$fill]])
            )) +
            ggplot2::labs(fill = tools::toTitleCase(input$fill))
        }
      }
      p_groups <- p_groups +
        ggplot2::geom_col() +
        ggplot2::theme_light() +
        ggplot2::xlab(tools::toTitleCase(input$groups)) +
        ggplot2::ylab(tools::toTitleCase(input$summary))

      plotly::ggplotly(p_groups) |>
        plotly::config(
          displaylogo = FALSE
        )
    })
  })
}
