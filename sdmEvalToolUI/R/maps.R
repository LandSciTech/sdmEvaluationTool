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
    ) |>
    leaflet.extras::addDrawToolbar(
      polylineOptions = FALSE,
      circleOptions = FALSE,
      rectangleOptions = leaflet.extras::drawRectangleOptions(),
      polygonOptions = leaflet.extras::drawPolygonOptions(),
      markerOptions = FALSE,
      circleMarkerOptions = FALSE
    )
}

#' Add subunits to Leaflet map
#'
#' @param map Leaflet map object.
#' @param deployment_id Character. Deployment ID.
#' @param color Color.
#' @param opacity Opacity.
#'
#' @export

add_subunits <- function(map, deployment_id, color = "blue", opacity = 0.8) {
  # Skip if no Deployment
  if (is.null(deployment_id)) {
    return(map)
  }

  subunits <- deployment_subunits_prep(deployment_id = "deployment1")
  subunits <- sf::st_transform(subunits, crs = 4326) # TODO: Remove if fixed

  map |>
    leaflet::addPolygons(
      data = subunits,
      group = "Subunits",
      popup = as.character(subunits$subunit_id),
      weight = 2,
      opacity = opacity,
      color = color,
      fillOpacity = 0,
      fillColor = NA,
      layerId = ~id,
    )
}


add_raster <- function(map, raster, layer, name, palette, opacity = 0.8) {
  # Skip if no layer
  if (!layer %in% names(raster)) {
    return(map)
  }

  mx <- max(
    terra::values(raster[[layer]]),
    na.rm = TRUE
  )

  pal <- leaflet::colorNumeric(
    palette,
    domain = c(0, mx),
    reverse = TRUE,
    na.color = "transparent"
  )

  map <- map |>
    leaflet::addRasterImage(
      raster[[layer]],
      colors = pal,
      group = name,
      opacity = opacity
    ) |>
    leaflet::addLegend(
      pal = pal,
      values = c(0, mx),
      position = "bottomleft",
      title = name
    )

  map
}

add_control <- function(map, groups = character(0)) {
  # Keep only groups present
  groups <- unique(c(groups, "Subunits"))
  groups <- groups[purrr::map_lgl(groups, \(g) map_has_group(map, g))]

  map <- map |>
    leaflet::addLayersControl(
      baseGroups = c("CartoDB", "ESRI", "Open Street Map", "Google"),
      overlayGroups = groups,
      position = "bottomright",
      options = leaflet::layersControlOptions(collapsed = FALSE)
    )

  if ("Uncertainty" %in% groups) {
    map <- leaflet::hideGroup(map, "Uncertainty")
  }
  map
}

add_markers <- function(
  map,
  data = leaflet::getMapData(map),
  colour_by = "detections"
) {
  pal <- leaflet::colorFactor("#637261ff", data[[colour_by]])

  map <- leaflet::addCircleMarkers(
    map,
    color = ~"#000000",
    label = ~popup,
    layerId = ~id,
    data = data,
    radius = 5,
    fillOpacity = 0.7,
    opacity = 1,
    weight = 1,
    fillColor = pal(data[[colour_by]])
  )

  map
}

add_selected_markers <- function(
  map,
  data = leaflet::getMapData(map),
  colour_by = "type"
) {
  levels <- levels(data[[colour_by]])
  pal <- leaflet::colorFactor(
    viridisLite::viridis(n = length(levels)),
    levels = factor(levels, levels = levels),
    ordered = TRUE
  )
  #"#fde725", data$detections)

  map <- map |>
    leaflet::addCircleMarkers(
      color = ~"#000000",
      label = ~popup,
      layerId = ~id,
      data = data,
      radius = 5,
      fillOpacity = 0.7,
      opacity = 1,
      weight = 1,
      fillColor = pal(data[[colour_by]])
    ) |>
    leaflet::addLegend(
      "bottomleft",
      pal = pal,
      values = levels,
      title = "Categories",
      opacity = 1,
      layerId = "legend" # Required to overwrite
    )

  map
}
