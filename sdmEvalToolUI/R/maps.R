# Leaflet mapping functions

#' Base Map with Provider Tiles
#'
#' @export
base_map <- function() {
    leaflet::leaflet() |>
        leaflet::addTiles(
            urlTemplate = "http://mt0.google.com/vt/lyrs=m&hl=en&x={x}&y={y}&z={z}&s=Ga",
            group = "Google",
            options = leaflet::providerTileOptions(zIndex = 200)
        ) |>
        leaflet::addProviderTiles(
            provider = "CartoDB.Positron",
            group = "CartoDB",
            options = leaflet::providerTileOptions(zIndex = 200)
        ) |>
        leaflet::addProviderTiles(
            provider = "OpenStreetMap",
            group = "Open Street Map",
            options = leaflet::providerTileOptions(zIndex = 200)
        ) |>
        leaflet::addProviderTiles(
            provider = 'Esri.WorldImagery',
            group = "ESRI",
            options = leaflet::providerTileOptions(zIndex = 200)
        )
}

#' Add subunits to Leaflet map
#'
#' @param map Leaflet map object.
#' @param subunits Subunits sf polygon (needs to be crs epsg 4326).
#' @param color Color.
#' @param opacity Opacity.
#'
#' @export
add_subunits <- function(map, subunits, color = "blue", opacity = 0.8) {
    map |>
        leaflet::addPolygons(
            data = subunits,
            group = "Subunits",
            popup = as.character(subunits$subunit_id),
            weight = 2,
            opacity = opacity,
            color = color,
            fillOpacity = 0,
            fillColor = NA
        )
}

#' Spatial predictions raster map
#'
#' @param spatial_prediction Spatial prediction (and uncertainty) raster.
#' @param subunits Subunits sf polygon (needs to be crs epsg 4326).
#' @param opacity Opacity.
#'
#' @export
raster_map <- function(
    spatial_prediction,
    deployment_subunits = NULL,
    opacity = 0.8
) {
    mx1 <- max(
        terra::values(spatial_prediction[[1]]),
        na.rm = TRUE
    )
    pal1 <- leaflet::colorNumeric(
        "Spectral",
        domain = c(0, mx1),
        reverse = TRUE,
        na.color = "transparent"
    )
    m <- base_map() |>
        leaflet::addRasterImage(
            spatial_prediction[[1]],
            colors = pal1,
            group = "Distribution",
            opacity = opacity
        ) |>
        leaflet::addLegend(
            pal = pal1,
            values = c(0, mx1),
            position = "bottomleft",
            title = "Distribution"
        )
    gr <- "Distribution"
    if (dim(spatial_prediction)[3] > 1) {
        mx2 <- max(
            terra::values(spatial_prediction[[2]]),
            na.rm = TRUE
        )
        pal2 <- leaflet::colorNumeric(
            "viridis",
            domain = c(0, mx2),
            reverse = TRUE,
            na.color = "transparent"
        )
        m <- m |>
            leaflet::addRasterImage(
                spatial_prediction[[2]],
                colors = pal2,
                group = "Uncertainty",
                opacity = opacity
            ) |>
            leaflet::addLegend(
                pal = pal2,
                values = c(0, mx2),
                position = "bottomright",
                title = "Uncertainty"
            )

        gr <- c(gr, "Uncertainty")
    }
    if (!is.null(deployment_subunits)) {
        m <- m |>
            add_subunits(deployment_subunits, opacity = opacity)
        gr <- c(gr, "Subunits")
    }
    m <- m |>
        leaflet::addLayersControl(
            baseGroups = c("CartoDB", "ESRI", "Open Street Map", "Google"),
            overlayGroups = gr,
            position = "topright",
            options = leaflet::layersControlOptions(collapsed = FALSE)
        )
    if ("Uncertainty" %in% gr) {
        m <- m |> leaflet::hideGroup("Uncertainty")
    }
    m
}
