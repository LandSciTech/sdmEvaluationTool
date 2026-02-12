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
            con <- withr::local_db_connection(db_connect())
            dplyr::tbl(con, "deployments") |>
                dplyr::collect() |>
                dplyr::filter(.data$deployment_id == deployment_id())
        })

        output$details <- renderUI({
            # note: same info is in the db as in the json file
            # need to decide which to use
            sett <- jsonlite::fromJSON(deets()$deployment_settings)
            tagList(
                h3(deets()$deployment_name),
                markdown(sett$instructions_to_evaluators)
            )
        })
        output$name <- renderText(deets()$deployment_name)
    })
}
