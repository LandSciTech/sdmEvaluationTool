# PLACEHOLDER - Side bar modules

mod_details_ui <- function(id = "details") {
  sidebar(
    title = NULL,
    open = TRUE,
    uiOutput(NS(id, "details")),
    width = 400
  )
}

mod_details_server <- function(id = "details", deployment_id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Logic to present side bar information

    deets <- reactive({
      validate_ids(deployment_id = deployment_id())

      withr::with_db_connection(
        list(con = db_connect()),
        dplyr::tbl(con, "deployments") |> dplyr::collect()
      ) |>
        dplyr::filter(deployment_id == deployment_id())
    })

    output$details <- renderUI({
      tagList(
        h3(deets()$deployment_name),
        "Information on the current deployment"
      )
    })
    output$name <- renderText(deets()$deployment_name)
  })
}
