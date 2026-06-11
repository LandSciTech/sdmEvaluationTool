# Leaflet mapping functions

#' Base Map with Provider Tiles
#'
#' Create the base Leaflet map with standard tiles, selection draw toolbar and
#' erase selection button. Also includes and custom Javascripts, here one for
#' marking which layers are visible for use in selections filtering (see
#' [mod_utils_map_selections_server()]).
#'
#' @param ns Namespace. Required for spatial selections.
#'
#' @export
#'
#' @examples
#' base_map()

base_map <- function(ns = identity) {
  # Track NS by hand for JS
  button_id <- ns("clear_selection")
  layers_id <- ns("layers_visible")

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
    ) |>
    leaflet::addEasyButton(
      leaflet::easyButton(
        title = "Clear selection",
        icon = bsicons::bs_icon("star-fill", title = "Clear selection"),
        onClick = leaflet::JS(
          # Based on: https://stackoverflow.com/a/62184472
          # Just need to make a change that Shiny can detect and respond to
          # Need to track NS by hand
          glue::glue(
            "function(btn, map){{
            Shiny.onInputChange('{button_id}', Math.random());
          }}"
          )
        )
      )
    ) |>
    htmlwidgets::onRender(
      glue::glue(
        .open = "{{",
        .close = "}}",
        "
    function(el, x) {
      var map = this;
      
      // Track visible layers
      var visibleLayers = [];
      
      // When layer is added
      map.on('overlayadd', function(e) {
        visibleLayers.push(e.name);
        Shiny.setInputValue('{{layers_id}}', visibleLayers);
      });
      
      // When layer is removed
      map.on('overlayremove', function(e) {
        var index = visibleLayers.indexOf(e.name);
        if (index > -1) {
          visibleLayers.splice(index, 1);
        }
        Shiny.setInputValue('{{layers_id}}', visibleLayers);
      });
      
      // Initialize with currently visible layers
      setTimeout(function() {
        map.eachLayer(function(layer) {
          if (layer.options && layer.options.group && map.hasLayer(layer)) {
            if (!visibleLayers.includes(layer.options.group)) {
              visibleLayers.push(layer.options.group);
            }
          }
        });
        Shiny.setInputValue('{{layers_id}}', visibleLayers);
      }, 500);
    }
  "
      )
    )
}

#' Add subunits to Leaflet map
#'
#' @param map Leaflet map object.
#' @param subunits Spatial Data Frame. Subunits
#' @param colour_by Vector. Column to fill by
#' @param opacity Numeric. Opacity.
#'
#' @export
#'
#' @examplesIf have_data()
#' subunits <- deployment_subunits_prep("deployment1")
#'
#' base_map() |>
#'   add_subunits(subunits)

add_subunits <- function(
  map,
  subunits = NULL,
  colour_by = "subunit_id",
  opacity = 0.8
) {
  # Skip if no Subunits
  if (is.null(subunits)) {
    return(map)
  }

  pal <- leaflet::colorFactor("#637261ff", subunits[[colour_by]])

  map |>
    leaflet::addPolygons(
      data = subunits,
      group = "Subunits",
      popup = as.character(subunits$subunit_id),
      weight = 2,
      opacity = opacity,
      color = pal(subunits[[colour_by]]),
      fillOpacity = 0,
      fillColor = pal(subunits[[colour_by]]),
      layerId = ~id,
    )
}

#' Add selected subunits to Leaflet map
#'
#' Similar to [add_subunits()] but colours subunits by fill colour and selection
#' type.
#'
#' @param map Leaflet map object.
#' @param subunits Spatial Data Frame. Subunits
#' @param colour_by Vector. Column to fill by (must be a factor with levels to
#'   get the correct legend).
#' @param opacity,fill_opacity Numeric. Opacity.
#'
#' @export
#'
#' @examplesIf have_data()
#' subunits <- deployment_subunits_prep("deployment1") |>
#'   dplyr::mutate(
#'     type = c(rep("Very biased", 10), rep("Moderately biased", 10), rep(NA, 114)),
#'     type = factor(type)
#'   )
#'
#' base_map() |>
#'   add_selected_subunits(subunits)

add_selected_subunits <- function(
  map,
  subunits = NULL,
  colour_by = "type",
  opacity = 0.8,
  fill_opacity = 0.2
) {
  # Skip if no Subunits
  if (is.null(subunits)) {
    return(map)
  }

  levels <- levels(subunits[[colour_by]])
  pal <- leaflet::colorFactor(
    viridisLite::viridis(n = length(levels)),
    levels = factor(levels, levels = levels),
    ordered = TRUE
  )

  map |>
    leaflet::addPolygons(
      data = subunits,
      group = "Subunits",
      popup = as.character(subunits$subunit_id),
      weight = 2,
      opacity = opacity,
      color = "black",
      fillOpacity = fill_opacity,
      fillColor = pal(subunits[[colour_by]]),
      layerId = ~id,
    ) |>
    leaflet::addLegend(
      "bottomleft",
      pal = pal,
      values = levels,
      title = "Categories",
      opacity = 1,
      position = "bottomright",
      layerId = "legend" # Required to overwrite
    )
}


#' Add raster as image layer to leaflet map
#'
#' Note that raster layers are attached to a new map pane with a defined
#' z-index. This is so we can be sure the raster is above the map tiles (z-index
#' 200, see `base_map()`), and yet below the subunits (default z-index of 400).
#'
#' @param map Leaflet map
#' @param raster Terra raster to add
#' @param layer Layer in raster to add
#' @param name Name of leaflet layer (for controls and ids)
#' @param palette Character. Colour palette to use
#' @param opacity Numeric. Opacity of raster layer
#' @param add_legend Logical. Whether or not to add a legend.
#' @param min_0 Logical. Whether to force the legend to start at zero.
#'
#' @returns Leaflet map
#'
#' @export
#'
#' @examples
#' r <- template_spatial_prep()
#' base_map() |>
#'   add_raster(r, layer = "mean", palette = "viridis", name = "Mean")

add_raster <- function(
  map,
  raster,
  layer,
  name,
  palette,
  opacity = 0.8,
  add_legend = TRUE,
  min_0 = TRUE
) {
  # Skip if no layer
  if (!layer %in% names(raster)) {
    return(map)
  }

  rg <- range(
    terra::values(raster[[layer]]),
    na.rm = TRUE
  )
  if (min_0) {
    rg[1L] <- 0
  }

  pal <- leaflet::colorNumeric(
    palette,
    domain = rg,
    reverse = TRUE,
    na.color = "transparent"
  )

  map <- map |>
    leaflet::addMapPane(paste0(name, "-pane"), zIndex = 390) |>
    leaflet::addRasterImage(
      raster[[layer]],
      colors = pal,
      group = name,
      opacity = opacity,
      options = leaflet::pathOptions(pane = paste0(name, "-pane"))
    )
  if (add_legend) {
    map <- map |>
      leaflet::addLegend(
        pal = pal,
        values = rg,
        position = "bottomleft",
        title = name,
        layerId = name,
        group = name
      )
  }

  map
}

#' Add Layers control to map
#'
#' @param map Leaflet map
#' @param groups Character vector. Layers or Group names to add to the control.
#' Subunits are included by default. Only existing layers are included.
#'
#' @returns Leaflet map with layer control buttons
#'
#' @export
#' @examples
#' # No subunits
#' r <- template_spatial_prep()
#' base_map() |>
#'   add_raster(r, layer = "mean", palette = "viridis", name = "Mean") |>
#'   add_control(groups = "Mean")
#'
#' # With subunits
#' if(have_data()) {
#'   r <- template_spatial_prep()
#'   s <- deployment_subunits_prep("deployment1")
#'   base_map() |>
#'     add_raster(r, layer = "mean", palette = "viridis", name = "Mean") |>
#'     add_subunits(s) |>
#'     add_control(groups = "Mean")
#' }

add_control <- function(map, groups = character(0)) {
  # Keep only groups present
  groups <- unique(c(groups, "Subunits"))
  groups <- groups[purrr::map_lgl(groups, \(g) map_has_group(map, g))]

  map <- map |>
    leaflet::addLayersControl(
      baseGroups = c("CartoDB", "ESRI", "Open Street Map", "Google"),
      overlayGroups = groups,
      position = "topright",
      options = leaflet::layersControlOptions(collapsed = FALSE)
    )

  #if ("Uncertainty" %in% groups) {
  map <- leaflet::hideGroup(map, "Uncertainty")
  map <- leaflet::hideGroup(map, "Absence")
  #}
  map
}

#' Add point markers to Leaflet map
#'
#' @param map Leaflet map object.
#' @param data Spatial data with markers to plot (defaults to data in the `map`
#' object).
#' @param colour_by Character. Column to use when colouring points.
#' @param layer_by Character. Column to use to group points into layers (for
#' [add_control()]).
#'
#' @returns Leaflet map.
#'
#' @export
#' @examples
#' base_map() |>
#'   add_markers(data = test_points()) |>
#'   add_control(groups = c("present", "absent")) # From 'layers' column

add_markers <- function(
  map,
  data = leaflet::getMapData(map),
  colour_by = "layers",
  layer_by = "layers"
) {
  levels <- levels(data[[colour_by]])
  pal <- leaflet::colorFactor(
    grDevices::grey.colors(
      dplyr::n_distinct(levels),
      start = 0,
      end = 1
    ),
    factor(levels, levels = levels)
  )

  dd <- split(data, data[[layer_by]])
  for (d in dd) {
    if (nrow(d) > 0) {
      map <- leaflet::addCircleMarkers(
        map,
        color = ~"#000000",
        label = ~popup,
        layerId = ~id,
        group = as.character(unique(d[[layer_by]])),
        data = d,
        radius = 5,
        fillOpacity = 0.7,
        opacity = 1,
        weight = 1,
        fillColor = pal(factor(d[[colour_by]]))
      )
    }
  }

  map
}

#' Add selected point markers to Leaflet map
#'
#' Very similar to [add_markers()] but colours according to `type` column which
#' defines the selections and no option to add to controls.
#'
#' @param map Leaflet map object.
#' @param data Spatial data with markers to plot (defaults to data in the `map`
#' object).
#' @param colour_by Character. Column to use when colouring points.
#'
#' @returns Leaflet map.
#'
#' @export
#' @examples
#' base_map() |>
#'   add_selected_markers(data = test_points())

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
      position = "bottomright",
      layerId = "legend" # Required to overwrite
    )

  map
}


set_view <- function(map, map_views, tab = NULL) {
  set_by <- map_views$set_by()
  if (!is.null(set_by) && (is.null(tab) || set_by != tab)) {
    map <- leaflet::setView(
      map,
      lng = map_views$view()[[2]]$lng,
      lat = map_views$view()[[2]]$lat,
      zoom = map_views$view()[[1]]
    )
  }
  map
}
