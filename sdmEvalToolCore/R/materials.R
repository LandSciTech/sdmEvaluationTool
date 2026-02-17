# Prepare materials: save and add a db entry
# observations - DONE
# model_metadata - DONE
# predictor_metadata - DONE
# predictor_raster - DONE
# spatial_prediction - DONE
# model_summary - DONE
# model_fit - DONE
# deployment_settings - DONE only file upload, but should write to db too?
# deployment_questions - DONE only file upload
# deployment_subunits - DONE only file upload

# FIXME: later add logic here that recognizes local file vs remote upload
# e.g. if path starts with http then use upload
# sdmEvalToolCore::db_write_table have to be replaced by API function
# fun(api_endpoint_url, data, callback_url)

# FIXME: add update=TRUE argument
# this would pull the entry from db and would update the modify user/time fields
# besides overwriting the file itself

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
    rule <- sdmEvalToolCore::get_comp_rule(component_id, "upload")
    fo <- sdmEvalToolCore::make_target_path(
        rule$output$path,
        data = list(
            model_id = model_id,
            species_id = species_id,
            deployment_id = deployment_id
        )
    )
    # FIXME: handle overwrite based on update T/F
    sdmEvalToolCore::write_file(x, fo, ...)

    if (update) {
        mtid <- sdmEvalToolCore::make_material_id(
            model_id = model_id,
            species_id = species_id,
            component_id = component_id
        )
        mt <- sdmEvalToolCore::db_read_table(con, table_name = "materials")
        mt <- mt |>
            dplyr::filter(.data$material_id == .env$mtid)
        mt$material_modify_user <- user_id
        mt$material_modify_time <- sdmEvalToolCore::timestamp_to(sdmEvalToolCore::now())
        if (!is.null(material_settings)) {
            mt$material_settings <- material_settings
        }
    } else {
        mt <- sdmEvalToolCore::prepare_material_entry(
            model_id = model_id,
            species_id = species_id,
            component_id = component_id,
            user_id = user_id,
            material_settings = if (is.null(material_settings)) {
                "[]"
            } else {
                material_settings
            }
        )
    }
    sdmEvalToolCore::db_write_table(
        con = con,
        table = "materials",
        data = mt,
        mode = if (update) "update" else "insert",
        check = TRUE
    )
    invisible(TRUE)
}

#' Prepare Deployment Questions
#'
#' @param deployment_id Deployment ID.
#' @param x Table with questions or `NULL`.
#' @param ... Arguments passed to the write function.
#'
#' @export
prep_deployment_questions <- function(
    deployment_id,
    x = NULL,
    ...
) {
    if (is.null(x)) {
        q <- sdmEvalToolCore::default_questions
    } else {
        q <- x
    }
    q <- sdmEvalToolCore::combine_questions(q)
    v <- sapply(q$values, \(z) {
        paste0(z, collapse = ", ")
    })
    q$values <- v
    upload_material(
        "deployment_questions",
        x = q,
        deployment_id = deployment_id,
        ...
    )
    invisible(TRUE)
}

#' Prepare Deployment Settings
#'
#' @param deployment_id Deployment ID.
#' @param x Lits with deployment.
#' @param ... Arguments passed to the write function.
#'
#' @export
prep_deployment_settings <- function(
    deployment_id,
    x,
    ...
) {
    upload_material(
        "deployment_settings",
        x = jsonlite::toJSON(x),
        deployment_id = deployment_id,
        ...
    )
    invisible(TRUE)
}

#' Prepare Deployment Subunits
#'
#' @param deployment_id Deployment ID.
#' @param x A spatial file with subunits or `NULL`.
#' @param reference Reference raster.
#' @param n Number of grid cells in x and y direction.
#' @param square Logical. If `FALSE``, create hexagonal grid.
#' @param ... Arguments passed to the write function.
#'
#' @export
prep_deployment_subunits <- function(
    deployment_id,
    x = NULL,
    reference,
    n = c(20, 20),
    square = TRUE,
    ...
) {
    if (is.null(x)) {
        bbox <- sf::st_as_sfc(sf::st_bbox(reference))
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
        su <- sf::st_simplify(su, TRUE, 10)
        su <- sf::st_transform(su, 4326)
    }
    upload_material(
        "deployment_subunits",
        x = su,
        deployment_id = deployment_id,
        ...
    )
    invisible(TRUE)
}


#' Prepare Predictor Raster
#'
#' @param x Raster file.
#' @param resolution Raster resampling resolution
#' @param model_id Model ID.
#' @param user_id User ID.
#' @param material_settings Material settings.
#' @param con Database connection (use `NULL` to avoid inserting new record).
#' @param update Logical. Is this a new entry or an update to an existing one.
#' @param ... Arguments passed to the write function.
#'
#' @export
prep_predictor_raster <- function(
    x,
    resolution = 5,
    model_id,
    user_id,
    material_settings = "[]",
    con = NULL,
    update = FALSE,
    ...
) {
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

#' Prepare Predictor Metadata
#'
#' @param x Predictor metadata table.
#' @param model_id Model ID.
#' @param user_id User ID.
#' @param material_settings Material settings.
#' @param con Database connection (use `NULL` to avoid inserting new record).
#' @param update Logical. Is this a new entry or an update to an existing one.
#' @param ... Arguments passed to the write function.
#'
#' @export
prep_predictor_metadata <- function(
    x,
    model_id,
    user_id,
    material_settings = "[]",
    con = NULL,
    update = FALSE,
    ...
) {
    rule <- sdmEvalToolCore::get_comp_rule("predictor_metadata", "upload")
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

#' Prepare Model Metadata
#'
#' @param x ODMAP table.
#' @param model_id Model ID.
#' @param user_id User ID.
#' @param material_settings Material settings.
#' @param con Database connection (use `NULL` to avoid inserting new record).
#' @param update Logical. Is this a new entry or an update to an existing one.
#' @param ... Arguments passed to the write function.
#'
#' @export
prep_model_metadata <- function(
    x,
    model_id,
    user_id,
    material_settings = "[]",
    con = NULL,
    update = FALSE,
    ...
) {
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

#' Prepare Spatial Prediction
#'
#' @param x Raster file.
#' @param model_id Model ID.
#' @param species_id Species ID.
#' @param user_id User ID.
#' @param material_settings Material settings.
#' @param con Database connection (use `NULL` to avoid inserting new record).
#' @param update Logical. Is this a new entry or an update to an existing one.
#' @param ... Arguments passed to the write function.
#'
#' @export
prep_spatial_prediction <- function(
    x,
    model_id,
    species_id,
    user_id,
    material_settings = "[]",
    con = NULL,
    update = FALSE,
    ...
) {
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

#' Prepare Observations
#'
#' @param x Table with multi species observations.
#' @param species Reference species table.
#' @param model_id Model ID.
#' @param species_id Species ID.
#' @param user_id User ID.
#' @param material_settings Material settings.
#' @param con Database connection (use `NULL` to avoid inserting new record).
#' @param update Logical. Is this a new entry or an update to an existing one.
#' @param ... Arguments passed to the write function.
#'
#' @export
prep_observations <- function(
    x,
    species,
    model_id,
    species_id,
    user_id,
    material_settings = "[]",
    con = NULL,
    update = FALSE,
    ...
) {
    SPP <- colnames(x)[colnames(x) %in% species$species_id]
    x$date <- as.POSIXct(x$date)
    for (species_id in SPP) {
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

#' Prepare Model Summary
#'
#' @param x Table with multi species model summary.
#' @param species Reference species table.
#' @param model_id Model ID.
#' @param species_id Species ID.
#' @param user_id User ID.
#' @param material_settings Material settings.
#' @param con Database connection (use `NULL` to avoid inserting new record).
#' @param update Logical. Is this a new entry or an update to an existing one.
#' @param ... Arguments passed to the write function.
#'
#' @export
prep_model_summary <- function(
    x,
    species,
    model_id,
    species_id,
    user_id,
    material_settings = "[]",
    con = NULL,
    update = FALSE,
    ...
) {
    SPP <- colnames(x)[colnames(x) %in% species$species_id]
    for (species_id in SPP) {
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

#' Prepare Observations
#'
#' @param x Table with multi species observations.
#' @param species Reference species table.
#' @param model_id Model ID.
#' @param species_id Species ID.
#' @param user_id User ID.
#' @param material_settings Material settings.
#' @param con Database connection (use `NULL` to avoid inserting new record).
#' @param update Logical. Is this a new entry or an update to an existing one.
#' @param ... Arguments passed to the write function.
#'
#' @export
prep_model_fit <- function(
    x,
    species,
    model_id,
    species_id,
    user_id,
    material_settings = "[]",
    con = NULL,
    update = FALSE,
    ...
) {
    SPP <- colnames(x)[colnames(x) %in% species$species_id]
    for (species_id in SPP) {
        z <- x[x$species_id == species_id, ]
        # z <- data.frame(metric = colnames(z), value = unlist(z))
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
