# FIXME: later add logic here that recognizes local file vs remote upload
# e.g. if path starts with http then use upload
# db_write_table have to be replaced by API function
# fun(api_endpoint_url, data, callback_url)

#' Write File and Insert/Update Material DB Entry
#'
#' @param x Object.
#' @param model_id Model ID.
#' @param species_id Species ID.
#' @param component_id Component ID.
#' @param user_id User ID.
#' @param deployment_id Deployment ID.
#' @param material_settings Material settings.
#' @param con Database connection (use `NULL` to avoid inserting a record).
#' @param update Logical. Is this a new entry (`FALSE`, default)
#'   or an update (`TRUE`) to an existing material entry.
#' @param ... Arguments passed to the write function.
#'
#' @export
upload_material <- function(
    component_id,
    x,
    model_id,
    species_id,
    user_id,
    deployment_id = NULL,
    material_settings = NULL,
    con = NULL,
    update = FALSE,
    ...
) {
    rule <- get_comp_rule(component_id, "upload")
    fo <- make_target_path(
        rule$output$path,
        data = list(
            model_id = model_id,
            species_id = species_id,
            deployment_id = deployment_id
        )
    )
    # FIXME: handle overwrite based on update T/F
    write_file(x, fo, ...)

    if (!is.null(con)) {
        if (update) {
            mtid <- make_material_id(
                model_id = model_id,
                species_id = species_id,
                component_id = component_id
            )
            mt <- db_read_table(con, table_name = "materials")
            mt <- mt |>
                dplyr::filter(.data$material_id == .env$mtid)
            mt$material_modify_user <- user_id
            mt$material_modify_time <- timestamp_to(now())
            if (!is.null(material_settings)) {
                mt$material_settings <- material_settings
            }
        } else {
            drule <- get_comp_rule(component_id, "display")
            ms <- jsonlite::toJSON(drule$materials_settings)
            mt <- prepare_material_entry(
                model_id = model_id,
                species_id = species_id,
                component_id = component_id,
                user_id = user_id,
                material_settings = if (is.null(material_settings)) {
                    ms
                } else {
                    material_settings
                }
            )
        }
        db_write_table(
            con = con,
            table = "materials",
            data = mt,
            mode = if (update) "update" else "insert",
            check = TRUE
        )
    }
    invisible(TRUE)
}

#' Prepare Deployment Materials
#'
#' @param deployment_id Deployment ID.
#' @param x An object to upload.
#' @param reference Reference raster.
#' @param n Number of grid cells in x and y direction.
#' @param square Logical. If `FALSE``, create hexagonal grid.
#' @param ... Arguments passed to the write function.
#'
#' @name upload-deployments
NULL

#' @rdname upload-deployments
#' @export
prep_deployment_questions <- function(
    deployment_id,
    x = NULL,
    ...
) {
    cat("> Preparing deployment questions\n")
    if (is.null(x)) {
        q <- sdmEvalToolCore::default_questions
    } else {
        q <- x
    }
    q <- combine_questions(q)
    v <- sapply(q$values, \(z) {
        paste0(z, collapse = ", ")
    })
    q$values <- v
    upload_material(
        "deployment_questions",
        x = q,
        deployment_id = deployment_id,
        model_id = NA_character_,
        species_id = NA_character_,
        ...
    )
    invisible(TRUE)
}

#' @rdname upload-deployments
#' @export
prep_deployment_settings <- function(
    deployment_id,
    x,
    ...
) {
    cat("> Preparing deployment settings\n")
    upload_material(
        "deployment_settings",
        x = jsonlite::toJSON(x),
        deployment_id = deployment_id,
        model_id = NA_character_,
        species_id = NA_character_,
        ...
    )
    invisible(TRUE)
}

#' @rdname upload-deployments
#' @export
prep_deployment_subunits <- function(
    deployment_id,
    x = NULL,
    reference,
    n = c(20, 20),
    square = TRUE,
    ...
) {
    cat("> Preparing deployment subunits\n")
    reference <- terra::project(reference, "epsg:4326")
    bbox <- sf::st_as_sfc(sf::st_bbox(reference))
    if (is.null(x)) {
        su_gr <- sf::st_make_grid(bbox, n = n, square = square)
        su <- sf::st_sf(
            subunit_id = as.character(seq_len(length(su_gr))),
            id = seq_len(length(su_gr)),
            geometry = su_gr
        )
        su <- sf::st_transform(su, 4326)
        u <- terra::rasterize(su, reference[[1]], "id")
        terra::values(u)[is.na(terra::values(reference[[1]]))] <- NA
        su$keep <- su$id %in% stats::na.omit(unique(terra::values(u)[, 1]))
        su <- su[su$keep, ]
        su$keep <- NULL
        su$id <- NULL
    } else {
        su <- x[, "subunit_id"]
        su <- sf::st_transform(su, 4326)
        su <- sf::st_simplify(su, TRUE, 10)
        su <- suppressWarnings(sf::st_intersection(su, bbox))
    }
    upload_material(
        "deployment_subunits",
        x = su,
        deployment_id = deployment_id,
        model_id = NA_character_,
        species_id = NA_character_,
        ...
    )
    invisible(TRUE)
}


#' Prepare Upload Materials
#'
#' @param x An object to upload.
#' @param resolution Raster resampling resolution
#' @param model_id Model ID.
#' @param species_id Species ID.
#' @param user_id User ID.
#' @param material_settings Material settings.
#' @param species Reference species table.
#' @param con Database connection (use `NULL` to avoid inserting new record).
#' @param update Logical. Is this a new entry or an update to an existing one.
#' @param ... Arguments passed to the write function.
#'
#' @name upload-materials
NULL

#' @rdname upload-materials
#' @export
prep_predictor_raster <- function(
    x,
    resolution = 5,
    model_id,
    user_id,
    material_settings = NULL,
    con = NULL,
    update = FALSE,
    ...
) {
    cat("> Preparing predictor raster\n")
    x <- terra::resample(x, resolution)
    x <- terra::project(x, "epsg:4326")
    upload_material(
        "predictor_raster",
        x = x,
        model_id = model_id,
        species_id = NA_character_,
        user_id = user_id,
        material_settings = material_settings,
        con = con,
        update = update,
        ...
    )
    invisible(TRUE)
}

#' @rdname upload-materials
#' @export
prep_predictor_metadata <- function(
    x,
    model_id,
    user_id,
    material_settings = NULL,
    con = NULL,
    update = FALSE,
    ...
) {
    cat("> Preparing predictor metadata\n")
    rule <- get_comp_rule("predictor_metadata", "upload")
    x <- x[, rule$output$columns]
    upload_material(
        "predictor_metadata",
        x = x,
        model_id = model_id,
        species_id = NA_character_,
        user_id = user_id,
        material_settings = material_settings,
        con = con,
        update = update,
        ...
    )
    invisible(TRUE)
}

#' @rdname upload-materials
#' @export
prep_model_metadata <- function(
    x,
    model_id,
    user_id,
    material_settings = NULL,
    con = NULL,
    update = FALSE,
    ...
) {
    cat("> Preparing model metadata\n")
    upload_material(
        "model_metadata",
        x = x,
        model_id = model_id,
        species_id = NA_character_,
        user_id = user_id,
        material_settings = material_settings,
        con = con,
        update = update,
        ...
    )
    invisible(TRUE)
}

#' @rdname upload-materials
#' @export
prep_spatial_prediction <- function(
    x,
    model_id,
    species_id,
    user_id,
    material_settings = NULL,
    con = NULL,
    update = FALSE,
    ...
) {
    cat("> Preparing spatial prediction for species", species_id, "\n")
    x <- terra::project(x, "epsg:4326")
    upload_material(
        "spatial_prediction",
        x = x,
        model_id = model_id,
        species_id = species_id,
        user_id = user_id,
        material_settings = material_settings,
        con = con,
        update = update,
        ...
    )
    invisible(TRUE)
}

#' @rdname upload-materials
#' @export
prep_observations <- function(
    x,
    species,
    model_id,
    user_id,
    material_settings = NULL,
    con = NULL,
    update = FALSE,
    ...
) {
    SPP <- sort(colnames(x)[colnames(x) %in% species$species_id])
    x$time <- as.POSIXct(x$time)
    for (species_id in SPP) {
        cat("> Preparing observations for species", species_id, "\n")
        z <- x[, c("latitude", "longitude", "time", "method", species_id)]
        colnames(z) <- c("latitude", "longitude", "time", "method", "status")
        z <- sf::st_as_sf(z, coords = c("longitude", "latitude"))
        sf::st_crs(z) <- 4326
        sr <- suntools::sunriset(
            crds = z,
            dateTime = z$time,
            direction = "sunrise",
            POSIXct.out = TRUE
        )
        z$hssr <- as.numeric(difftime(z$time, sr$time, units = "hours"))
        upload_material(
            "observations",
            x = z,
            model_id = model_id,
            species_id = species_id,
            user_id = user_id,
            material_settings = material_settings,
            con = con,
            update = update,
            ...
        )
    }
    invisible(TRUE)
}

#' @rdname upload-materials
#' @export
prep_model_summary <- function(
    x,
    species,
    model_id,
    user_id,
    material_settings = NULL,
    con = NULL,
    update = FALSE,
    ...
) {
    SPP <- sort(unique(x$species_id[x$species_id %in% species$species_id]))
    for (species_id in SPP) {
        cat("> Preparing model summary for species", species_id, "\n")
        z <- x[x$species_id == species_id, ]
        upload_material(
            "model_summary",
            x = z,
            model_id = model_id,
            species_id = species_id,
            user_id = user_id,
            material_settings = material_settings,
            con = con,
            update = update,
            ...
        )
    }
    invisible(TRUE)
}

#' @rdname upload-materials
#' @export
prep_model_fit <- function(
    x,
    species,
    model_id,
    user_id,
    material_settings = NULL,
    con = NULL,
    update = FALSE,
    ...
) {
    SPP <- sort(unique(x$species_id[x$species_id %in% species$species_id]))
    for (species_id in SPP) {
        cat("> Preparing model fit for species", species_id, "\n")
        z <- x[x$species_id == species_id, ]
        z$species_id <- NULL
        z <- data.frame(metric = colnames(z), value = unlist(z))
        upload_material(
            "model_fit",
            x = z,
            model_id = model_id,
            species_id = species_id,
            user_id = user_id,
            material_settings = material_settings,
            con = con,
            update = update,
            ...
        )
    }
    invisible(TRUE)
}
