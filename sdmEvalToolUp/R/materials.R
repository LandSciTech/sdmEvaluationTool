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

#' Prepare Deployment Questions
#'
#' @param deployment_id Deployment ID.
#' @param x Table with questions or `NULL`.
#'
#' @export
prep_deployment_questions <- function(
    deployment_id,
    x = NULL
) {
    rule <- sdmEvalToolCore::get_comp_rule("deployment_questions", "upload")
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
    fo <- sdmEvalToolCore::make_target_path(
        rule$output$path,
        data = list(deployment_id = deployment_id)
    )
    sdmEvalToolCore::write_file(q, fo)

    invisible(TRUE)
}

#' Prepare Deployment Settings
#'
#' @param deployment_id Deployment ID.
#' @param x Lits with deployment.
#'
#' @export
prep_deployment_settings <- function(
    deployment_id,
    x
) {
    rule <- sdmEvalToolCore::get_comp_rule("deployment_settings", "upload")
    fo <- sdmEvalToolCore::make_target_path(
        rule$output$path,
        data = list(deployment_id = deployment_id)
    )
    # FIXME: should we use the default template from config here?
    sdmEvalToolCore::write_file(jsonlite::toJSON(x), fo)

    invisible(TRUE)
}

#' Prepare Deployment Subunits
#'
#' @param deployment_id Deployment ID.
#' @param x A spatial file with subunits or `NULL`.
#' @param reference Reference raster.
#' @param n Number of grid cells in x and y direction.
#' @param square Logical. If `FALSE``, create hexagonal grid.
#'
#' @export
prep_deployment_subunits <- function(
    deployment_id,
    x = NULL,
    reference,
    n = c(20, 20),
    square = TRUE
) {
    rule <- sdmEvalToolCore::get_comp_rule("deployment_subunits", "upload")

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

    fo <- sdmEvalToolCore::make_target_path(
        rule$output$path,
        data = list(deployment_id = deployment_id)
    )
    sdmEvalToolCore::write_file(su, fo)

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
#'
#' @export
prep_predictor_raster <- function(
    x,
    resolution = 5,
    model_id,
    user_id,
    material_settings = "[]",
    con = NULL
) {
    rule <- sdmEvalToolCore::get_comp_rule("predictor_raster", "upload")
    x <- terra::resample(x, resolution)
    x <- terra::project(x, "epsg:4326")
    fo <- sdmEvalToolCore::make_target_path(
        rule$output$path,
        data = list(model_id = model_id)
    )
    sdmEvalToolCore::write_file(x, fo)
    if (!is.null(con)) {
        new_material <- sdmEvalToolCore::prepare_material_entry(
            model_id = model_id,
            species_id = NA_character_,
            component_id = "predictor_raster",
            user_id = user_id,
            material_settings = material_settings
        )
        sdmEvalToolCore::db_write_table(
            con = con,
            table = "materials",
            data = new_material,
            mode = "insert", # will fail if already exists
            check = TRUE
        )
    }
    invisible(TRUE)
}

#' Prepare Predictor Metadata
#'
#' @param x Predictor metadata table.
#' @param model_id Model ID.
#' @param user_id User ID.
#' @param material_settings Material settings.
#' @param con Database connection (use `NULL` to avoid inserting new record).
#'
#' @export
prep_predictor_metadata <- function(
    x,
    model_id,
    user_id,
    material_settings = "[]",
    con = NULL
) {
    rule <- sdmEvalToolCore::get_comp_rule("predictor_metadata", "upload")
    x <- x[, rule$output$columns]
    fo <- sdmEvalToolCore::make_target_path(
        rule$output$path,
        data = list(model_id = model_id)
    )
    sdmEvalToolCore::write_file(x, fo)

    if (!is.null(con)) {
        new_material <- sdmEvalToolCore::prepare_material_entry(
            model_id = model_id,
            species_id = NA_character_,
            component_id = "predictor_metadata",
            user_id = user_id,
            material_settings = material_settings
        )
        sdmEvalToolCore::db_write_table(
            con = con,
            table = "materials",
            data = new_material,
            mode = "insert", # will fail if already exists
            check = TRUE
        )
    }
    invisible(TRUE)
}

#' Prepare Model Metadata
#'
#' @param x ODMAP table.
#' @param model_id Model ID.
#' @param user_id User ID.
#' @param material_settings Material settings.
#' @param con Database connection (use `NULL` to avoid inserting new record).
#'
#' @export
prep_model_metadata <- function(
    x,
    model_id,
    user_id,
    material_settings = "[]",
    con = NULL
) {
    rule <- sdmEvalToolCore::get_comp_rule("model_metadata", "upload")
    fo <- sdmEvalToolCore::make_target_path(
        rule$output$path,
        data = list(model_id = model_id)
    )
    sdmEvalToolCore::write_file(x, fo)

    if (!is.null(con)) {
        new_material <- sdmEvalToolCore::prepare_material_entry(
            model_id = model_id,
            species_id = NA_character_,
            component_id = "model_metadata",
            user_id = user_id,
            material_settings = material_settings
        )
        sdmEvalToolCore::db_write_table(
            con = con,
            table = "materials",
            data = new_material,
            mode = "insert", # will fail if already exists
            check = TRUE
        )
    }
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
#'
#' @export
prep_spatial_prediction <- function(
    x,
    model_id,
    species_id,
    user_id,
    material_settings = "[]",
    con = NULL
) {
    rule <- sdmEvalToolCore::get_comp_rule("spatial_prediction", "upload")
    x <- terra::project(x, "epsg:4326")
    fo <- sdmEvalToolCore::make_target_path(
        rule$output$path,
        data = list(model_id = model_id, species_id = species_id)
    )
    sdmEvalToolCore::write_file(x, fo)

    if (!is.null(con)) {
        new_material <- sdmEvalToolCore::prepare_material_entry(
            model_id = model_id,
            species_id = species_id,
            component_id = "spatial_prediction",
            user_id = user_id,
            material_settings = material_settings
        )
        sdmEvalToolCore::db_write_table(
            con = con,
            table = "materials",
            data = new_material,
            mode = "insert", # will fail if already exists
            check = TRUE
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
#'
#' @export
prep_observations <- function(
    x,
    species,
    model_id,
    species_id,
    user_id,
    material_settings = "[]",
    con = NULL
) {
    rule <- get_comp_rule("observations", "upload")
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

        fo <- sdmEvalToolCore::make_target_path(
            rule$output$path,
            data = list(model_id = model_id, species_id = species_id)
        )
        sdmEvalToolCore::write_file(z, fo)

        if (!is.null(con)) {
            new_material <- sdmEvalToolCore::prepare_material_entry(
                model_id = model_id,
                species_id = species_id,
                component_id = "observations",
                user_id = user_id,
                material_settings = material_settings
            )
            sdmEvalToolCore::db_write_table(
                con = con,
                table = "materials",
                data = new_material,
                mode = "insert", # will fail if already exists
                check = TRUE
            )
        }
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
#'
#' @export
prep_model_summary <- function(
    x,
    species,
    model_id,
    species_id,
    user_id,
    material_settings = "[]",
    con = NULL
) {
    rule <- sdmEvalToolCore::get_comp_rule("model_summary", "upload")
    SPP <- colnames(x)[colnames(x) %in% species$species_id]
    for (species_id in SPP) {
        z <- x[x$species_id == species_id, ]
        fo <- sdmEvalToolCore::make_target_path(
            rule$output$path,
            data = list(model_id = model_id, species_id = species_id)
        )
        sdmEvalToolCore::write_file(z, fo)

        if (!is.null(con)) {
            new_material <- sdmEvalToolCore::prepare_material_entry(
                model_id = model_id,
                species_id = species_id,
                component_id = "model_summary",
                user_id = user_id,
                material_settings = material_settings
            )
            sdmEvalToolCore::db_write_table(
                con = con,
                table = "materials",
                data = new_material,
                mode = "insert", # will fail if already exists
                check = TRUE
            )
        }
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
#'
#' @export
prep_observations <- function(
    x,
    species,
    model_id,
    species_id,
    user_id,
    material_settings = "[]",
    con = NULL
) {
    rule <- sdmEvalToolCore::get_comp_rule("model_fit", "upload")
    SPP <- colnames(x)[colnames(x) %in% species$species_id]
    for (species_id in SPP) {
        z <- x[x$species_id == species_id, ]
        # z <- data.frame(metric = colnames(z), value = unlist(z))
        fo <- sdmEvalToolCore::make_target_path(
            rule$output$path,
            data = list(model_id = model_id, species_id = species_id)
        )
        sdmEvalToolCore::write_file(z, fo)

        if (!is.null(con)) {
            new_material <- sdmEvalToolCore::prepare_material_entry(
                model_id = model_id,
                species_id = species_id,
                component_id = "model_fit",
                user_id = user_id,
                material_settings = material_settings
            )
            sdmEvalToolCore::db_write_table(
                con = con,
                table = "materials",
                data = new_material,
                mode = "insert", # will fail if already exists
                check = TRUE
            )
        }
    }
    invisible(TRUE)
}
