#' Test the Observations Component
#'
#' @param ... Arguments passed to other functions.
#'
#' @returns A Shiny app object
#'
#' @export
#' @examplesIf have_data()
#' test_comp_observations()

test_comp_observations <- function(...) {
    test_comp("mod_comp_observations", ...)
}

#' Observations Component UI
#'
#' @param id Character. Shiny module ID
#' @param header Header
#'
#' @returns Shiny UI
#'
#' @export
#' @examples
#' mod_comp_observations_ui()

mod_comp_observations_ui <- function(
    id = "comp_observations",
    header = NULL
) {
    tagList(
        sdm_card(
            min_height = "60%",
            header,
            uiOutput(NS(id, "ui_selectors")),
            sdm_spinner(leaflet::leafletOutput(NS(id, "map")))
        ),
        sdm_card(
            min_height = "40%",
            mod_utils_map_selections_ui(
                NS(id, "select"),
                spatial_type = "points"
            )
        )
    )
}


#' Observations component Server
#'
#' @param id Module ID
#' @param deployment_id Deployment ID
#' @param model_id Model ID
#' @param species_id Species ID
#' @param spatial_selection Spatial selection
#' @param spatial_ids Spatial IDs
#'
#' @returns Module server function
#'
#' @export
mod_comp_observations_server <- function(
    id = "comp_observations",
    deployment_id,
    model_id,
    species_id,
    spatial_selection,
    spatial_ids # ReactiveVal to be update
) {
    stopifnot(is.reactive(deployment_id))
    stopifnot(is.reactive(model_id))
    stopifnot(is.reactive(species_id))

    moduleServer(id, function(input, output, session) {
        # Map -------------------------------------------------------------------
        obs <- reactive(obs_prep(model_id(), species_id()))

        subunits <- reactive({
            deployment_subunits_prep(deployment_id())
        })

        # Filter observations on the map
        output$ui_selectors <- renderUI({
            tagList(
                div(
                    style = "display:grid; grid-template-columns: 200px 200px; gap: 10px; padding-bottom:0;",
                    selectInput(
                        "year",
                        label = "Year",
                        choices = sort(unique(obs()$year))
                    ),
                    selectInput(
                        "method",
                        label = "Method",
                        choices = sort(unique(obs()$method))
                    )
                )
            )
        })

        output$map <- leaflet::renderLeaflet(obs_map(
            obs(),
            subunits(),
            ns = session$ns
        ))

        # Process and show map selections ---------------------------------------
        interactions <- map_reactive_vals(input, "map")

        mod_utils_map_selections_server(
            "select",
            data = obs,
            spatial_selection = spatial_selection,
            interactions = interactions,
            spatial_type = "points",
            parent_session = session
        )

        # Return ---------------------
        observe(spatial_ids(obs()$id))

        spatial_ids
    })
}


#' Create a Leaflet Map of Observation Data
#'
#' @param obs sf data frame. Observations
#' @param subunits Subunits
#' @param ns Namespace
#' @param output_type Character. Points or raster.
#' @param ... Other parameters.
#'
#' @returns A leaflet map object
#'
#' @export
#' @examplesIf have_data()
#' o <- obs_prep(model_id = "bam_v5_can71", species_id = "BBWO")
#' s <- deployment_subunits_prep("deployment1")
#' obs_map(o, s)

obs_map <- function(
    obs,
    subunits = NULL,
    ns = identity,
    output_type = c("points", "raster"),
    ...
) {
    output_type <- match.arg(output_type)
    switch(
        output_type,
        "points" = obs_map_points(
            obs = obs,
            subunits = subunits,
            ns = ns,
            ...
        ),
        "raster" = obs_map_raster(
            obs = obs,
            subunits = subunits,
            ns = ns,
            ...
        )
    )
}

obs_map_points <- function(obs, subunits = NULL, ns = identity, ...) {
    base_map(ns = ns) |>
        # Subunits first because selecting by points
        add_subunits(subunits) |>
        add_markers(data = obs) |>
        add_control(groups = c("Absence", "Presence"))
}

obs_map_raster <- function(
    obs,
    subunits = NULL,
    ns = identity,
    ...
) {
    base_map(ns = ns) |>
        add_raster(
            obs,
            layer = "absence",
            name = "Absence",
            palette = "#90d5ff"
        ) |>
        add_raster(
            obs,
            layer = "presence",
            name = "Presence",
            palette = "#36404a"
        ) |>
        add_subunits(subunits) |>
        add_control(groups = c("Absence", "Presence"))
}

#' Prepare Observation Data
#'
#' @param model_id Character. Model ID
#' @param species_id Character. Species ID
#' @param output_type Character. Points or raster.
#' @param ... Other parameters.
#'
#' @returns Spatial data frame
#'
#' @export
#' @examplesIf have_data()
#' obs_prep(model_id = "bam_v5_can71", species_id = "BBWO")
#' obs_prep(model_id = "bam_v5_can71", species_id = "BBWO", output_type = "raster")

obs_prep <- function(
    model_id,
    species_id,
    output_type = c("points", "raster"),
    ...
) {
    output_type <- match.arg(output_type)
    switch(
        output_type,
        "points" = obs_prep_points(
            model_id = model_id,
            species_id = species_id,
            ...
        ),
        "raster" = obs_prep_raster(
            model_id = model_id,
            species_id = species_id,
            ...
        )
    )
}

obs_prep_raster <- function(model_id, species_id, scale = 10, level = 0, ...) {
    obs <- prep_materials(
        "observations",
        model_id = model_id,
        species_id = species_id
    ) |>
        dplyr::filter(
            status >= level
        ) |>
        dplyr::mutate(
            status = ifelse(status > 0, 1, 0)
        )
    rast <- prep_materials(
        "spatial_prediction",
        model_id = model_id,
        species_id = species_id
    ) |>
        terra::resample(scale)

    out0 <- terra::rasterize(
        x = obs[obs$status == 0, ],
        y = rast,
        field = "status",
        fun = max
    )
    out1 <- terra::rasterize(
        x = obs[obs$status > 0, ],
        y = rast,
        field = "status",
        fun = max
    )
    out <- c(out0, out1)
    names(out) <- c("absence", "presence")
    out
}

obs_prep_points <- function(model_id, species_id, ...) {
    obs <- prep_materials(
        "observations",
        model_id = model_id,
        species_id = species_id
    ) |>
        dplyr::mutate(
            year = as.numeric(stringr::str_extract(.data$time, "^\\d{4}")),
            layers = dplyr::if_else(.data$status == 0, "Absence", "Presence"),
            layers = factor(layers),
            # fmt: skip
            popup = paste0(
          "<strong>Method:</strong> ", .data$method, "<br>",
          "<strong>Time:</strong> ", .data$time, "<br>",
          "<strong>Status:</strong> ", .data$status
        )
        ) |>
        # For reasons, the id must be a character, otherwise point can't be removed
        # from selections
        dplyr::mutate(id = paste0("id", dplyr::row_number())) |>
        sf::st_transform(crs = 4326)

    # HTMLify the labels

    obs$popup <- purrr::map(obs$popup, HTML)

    obs
}
