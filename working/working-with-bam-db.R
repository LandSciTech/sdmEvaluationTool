# read tables

devtools::load_all("sdmEvalToolCore")
sdmevaltool_options(base = "./misc/base") # use the misc folder

lang <- "english"
userid <- "draper"
deploymentid <- "deployment1"
modelid <- "bam_v5_can71"

con <- db_connect()
DBI::dbListTables(con)

# note: components should be pulled from the package
comps <- sdmEvalToolCore::components

userinfo <- db_read_user_info(con, userid, deploymentid)
attr(userinfo, "user_roles")

dm <- db_read_deployment_materials(con, deploymentid)

comms <- db_read_comments(con, deploymentid)
evals <- db_read_evaluations(con, deploymentid)


z <- dplyr::tbl(con, "materials") |> dplyr::collect()
z$material_id
e <- dplyr::tbl(con, "evaluations") |> dplyr::collect()
dm <- dplyr::tbl(con, "deployment_materials") |> dplyr::collect()

DBI::dbDisconnect(con)

# observations summary

devtools::load_all("../sdmEvalToolCore")
devtools::load_all("../sdmEvalToolUI")
sdmevaltool_options(base = "../misc/base") # use the misc folder

test_comp_predictor_raster()
test_comp_predictor_metadata()
test_page_predictors()
sdm_tool()
# eval_details: could not find function "eval_details"

user_id <- "draper"
deployment_id <- "deployment1"
model_id <- "bam_v5_can71"
species_id <- "BBWA"

read_component <- function(component_id, data = list(), base = NULL, ...) {
    path <- make_target_path(
        sdmEvalToolCore::components$path[
            sdmEvalToolCore::components$component == component_id
        ],
        data = data,
        base = base
    )
    str(path)
    read_file(path, ...)
}


x0 <- read_component(
    "observations",
    model_id = model_id,
    species_id = species_id
)
f <- make_target_path(rule$output$path, data = list(model_id = model_id))

x <- read_file(
    "./misc/base/materials/bam_v5_can71/species/BBWA/observations.gpkg"
)

z <- sf::st_drop_geometry(x)
dt <- as.POSIXlt(z$time)
z$year <- dt$year + 1900
z$month <- dt$mo + 1
table(z$year, z$month)

s1 <- z |>
    dplyr::mutate(det = ifelse(status > 0, 1, 0)) |>
    dplyr::group_by(year, month, method) |>
    dplyr::summarize(
        nobs = dplyr::n(),
        ndet = sum(det),
        .groups = "keep"
    )

s2 <- z |>
    dplyr::mutate(det = ifelse(status > 0, 1, 0)) |>
    dplyr::group_by(year, month, method, det) |>
    dplyr::summarize(
        n = dplyr::n(),
        .groups = "keep"
    )

library(ggplot2)

z |>
    ggplot(aes(x = status, group = as.factor(year), fill = as.factor(year))) +
    geom_bar()
s1 |> ggplot(aes(x = year, y = nobs, fill = method)) + geom_col()
s1 |> ggplot(aes(x = year, y = ndet, fill = method)) + geom_col()

s1 |> ggplot(aes(x = method, y = nobs)) + geom_col()

s2 |> ggplot(aes(x = month, y = n, fill = as.factor(det))) + geom_col()

s1 |>
    dplyr::group_by(month) |>
    dplyr::summarize(nobs = sum(nobs), ndet = sum(ndet)) |>
    ggplot(aes(x = month, y = ndet / nobs)) +
    geom_col(stat = "identity")

s1 |>
    dplyr::group_by(method) |>
    dplyr::summarize(nobs = sum(nobs), ndet = sum(ndet)) |>
    ggplot(aes(x = method, y = ndet / nobs)) +
    geom_col(stat = "identity")

s1 |>
    dplyr::group_by(year) |>
    dplyr::summarize(nobs = sum(nobs), ndet = sum(ndet)) |>
    ggplot(aes(x = year, y = ndet / nobs)) +
    geom_col(stat = "identity")


z |>
    dplyr::mutate(det = ifelse(status > 0, 1, 0)) |>
    ggplot(aes(x = round(hssr), fill = method)) +
    geom_bar()

library(terra)
r0 <- read_file(
    "./misc/base/materials/bam_v5_can71/species/BBWA/spatial_prediction.tif"
)
r0 <- terra::resample(r0, 10)

x$status[x$status > 0] <- 1

r <- rasterize(x = x, y = r0, field = "status", fun = max)
plot(r)
# rasterizing points is pretty fast, could combine with filters

base_map_sidebyside <- function(ns = identity, left_id, right_id) {
    base_map(ns = ns) |>
        leaflet::addMapPane(name = "left", zIndex = 0) |>
        leaflet::addMapPane(name = "right", zIndex = 0) |>
        leaflet.extras2::addSidebyside(
            layerId = "sidecontrols",
            leftId = left_id,
            rightId = right_id
        )
}

add_raster_2 <- function(
    map,
    raster,
    layer,
    name,
    palette,
    side,
    opacity = 0.8
) {
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
            opacity = opacity,
            pathOptions(pane = side)
        ) |>
        leaflet::addLegend(
            pal = pal,
            values = c(0, mx),
            position = paste0("bottom", side),
            title = name,
            layerId = name,
            group = name
        )

    map
}

x1 <- read_file(
    "../misc/base/materials/bam_v5_can71/species/BBWA/spatial_prediction.tif"
)
x2 <- read_file(
    "../misc/base/materials/bam_v5_can71/species/CAWA/spatial_prediction.tif"
)
su <- read_file(
    "../misc/base/deployments/deployment1/deployment_subunits.gpkg"
)

x11 = x1[[1]]
x11 <- terra::writeRaster(x11, "../_tmp/bbwa.tif")
x21 = x2[[1]]
x21 <- terra::writeRaster(x21, "../_tmp/cawa.tif")

library(leaflet)
library(leaflet.extras2)

base_map() |>
    add_raster(
        x1,
        layer = "mean",
        name = "Distribution",
        palette = "Spectral"
    ) |>
    # add_subunits(subunits) |>
    add_control(groups = c("Distribution"))

base_map_sidebyside(left_id = "BBWA", right_id = "CAWA") |>
    add_raster_2(
        x1,
        layer = "mean",
        name = "BBWA",
        palette = "Spectral",
        side = "left"
    ) |>
    add_raster_2(
        x2,
        layer = "mean",
        name = "CAWA",
        palette = "Spectral",
        side = "right"
    ) |>
    add_control(groups = c("Distribution"))

library(leaflet)
library(leafem)
library(stars)

leaflet() |>
    # addTiles() |>
    addGeotiff(
        file = "../misc/base/materials/bam_v5_can71/species/BBWA/spatial_prediction.tif",
        opacity = 0.9,
        colorOptions = colorOptions(
            palette = hcl.colors(256, palette = "inferno"),
            na.color = "transparent"
        )
    )

leaflet() |>
    addMapPane("left", zIndex = 0) |>
    addMapPane("right", zIndex = 0) |>
    addTiles(
        group = "base",
        layerId = "baseid",
        options = pathOptions(pane = "right")
    ) |>
    addProviderTiles(
        providers$CartoDB.DarkMatter,
        group = "carto",
        layerId = "cartoid",
        options = pathOptions(pane = "left")
    ) |>
    leafem::addGeotiff(
        #   url = url[[1]],
        file = "../misc/base/materials/bam_v5_can71/species/BBWA/spatial_prediction.tif",
        project = TRUE,
        opacity = 0.8,
        autozoom = FALSE,
        group = "baseid",
        layerId = "spp1_id",
        options = leaflet::tileOptions(
            pane = "left",
            maxNativeZoom = 10,
            zIndex = 400
            # ),
            # colorOptions = leafem::colorOptions(
            #     palette = grDevices::hcl.colors(
            #         101,
            #         "spectral",
            #         rev = TRUE
            #     )[seq_len(pal_max1)],
            #     domain = c(min1, max1),
            #     na.color = "transparent"
        )
    ) |>
    leafem::addGeotiff(
        #   url = url[[1]],
        file = "../misc/base/materials/bam_v5_can71/species/CAWA/spatial_prediction.tif",
        project = TRUE,
        opacity = 0.8,
        autozoom = FALSE,
        group = "cartoid",
        layerId = "spp2_id",
        options = leaflet::tileOptions(
            pane = "left",
            maxNativeZoom = 10,
            zIndex = 400
            # ),
            # colorOptions = leafem::colorOptions(
            #     palette = grDevices::hcl.colors(
            #         101,
            #         "spectral",
            #         rev = TRUE
            #     )[seq_len(pal_max1)],
            #     domain = c(min1, max1),
            #     na.color = "transparent"
        )
    ) |>
    # leaflet::addRasterImage(
    #     x1[["mean"]],
    #     colors = "Spectral",
    #     group = "baseid",
    #     pathOptions(pane = "left")
    # ) |>
    # leaflet::addRasterImage(
    #     x1[[1]],
    #     colors = "Spectral",
    #     group = "cartoid",
    #     pathOptions(pane = "right")
    # ) |>
    addSidebyside(
        layerId = "sidecontrols",
        rightId = "baseid",
        leftId = "cartoid"
    )


library(shiny)
library(leaflet)
library(leafem)
library(leaflet.extras2)


ui <- tagList(
    h1("Side-by-side"),
    leaflet::leafletOutput("map", height = "600px")
)
server <- function(input, output, session) {
    output$map <- leaflet::renderLeaflet({
        leaflet::leaflet() |>
            leaflet::addMapPane(name = "left", zIndex = 0) |>
            leaflet::addMapPane(name = "right", zIndex = 0) |>
            leaflet::addProviderTiles(
                provider = "Esri.WorldImagery",
                group = "carto_left",
                options = leaflet::tileOptions(pane = "left"),
                layerId = "leftid"
            ) |>
            leaflet::addProviderTiles(
                provider = "Esri.WorldImagery",
                group = "carto_right",
                options = leaflet::tileOptions(pane = "right"),
                layerId = "rightid"
            ) |>
            leaflet.extras2::addSidebyside(
                layerId = "sidecontrols",
                leftId = "gr1",
                rightId = "gr2"
            ) |>
            leafem::addGeotiff(
                #   url = url[[1]],
                file = "../_tmp/bbwa.tif",
                project = FALSE,
                opacity = 0.8,
                autozoom = TRUE,
                group = "gr1",
                layerId = "spp1",
                options = pathOptions(pane = "left"),
                # options = leaflet::tileOptions(
                #     pane = "left",
                #     maxNativeZoom = 10,
                #     zIndex = 400
                # ),
                colorOptions = colorOptions(
                    palette = hcl.colors(256, palette = "inferno"),
                    na.color = "transparent"
                )
            ) |>
            leafem::addGeotiff(
                #   url = url[[1]],
                file = "../_tmp/cawa.tif",
                project = FALSE,
                opacity = 0.8,
                autozoom = TRUE,
                group = "gr2",
                layerId = "spp2",
                options = pathOptions(pane = "right"),
                # options = leaflet::tileOptions(
                #     pane = "right",
                #     maxNativeZoom = 10,
                #     zIndex = 400
                # ),
                colorOptions = colorOptions(
                    palette = hcl.colors(256, palette = "viridis"),
                    na.color = "transparent"
                )
            )
        # leaflet::addRasterImage(
        #     x1[["mean"]],
        #     colors = "Spectral",
        #     group = "baseid",
        #     pathOptions(pane = "left")
        # ) |>
        # leaflet::addRasterImage(
        #     x1[[1]],
        #     colors = "Spectral",
        #     group = "cartoid",
        #     pathOptions(pane = "right")
        # ) |>
        # addSidebyside(
        #     layerId = "sidecontrols",
        #     rightId = "gr1",
        #     leftId = "gr2"
        # )
    })
}
shinyApp(ui, server, options = list(port = 8080))
