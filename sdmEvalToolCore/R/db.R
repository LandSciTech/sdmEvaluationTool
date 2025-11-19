#' Determine DB type
#'
#' @param con DB connection.
#'
#' @return Character or an error.
#' @noRd
db_type <- function(con) {
    if (inherits(con, "SQLiteConnection")) {
        return("sqlite")
    }
    if (inherits(con, "PqConnection")) {
        return("postgresql")
    }
    stop("Unsupported database connection.")
}

#' Mutate Timestamps
#'
#' @param x A data frame.
#'
#' @return A data frame with `*_time` columns as date/time.
#' @noRd
db_timestamp <- function(x) {
    for (i in colnames(x)[endsWith(colnames(x), "_time")]) {
        x[[i]] <- timestamp_from(x[[i]])
    }
    x
}

#' Connect to Database
#'
#' @param ... Arguments bassed to [DBI::dbConnect()].
#'
#' @return A database connection.
#'
#' @export
db_connect <- function(...) {
    if (sdmevaltool_options()$db == "sqlite") {
        db_file <- make_target_path("sdm_evaluation_db.sqlite")
        db_con <- DBI::dbConnect(
            drv = RSQLite::SQLite(),
            dbname = db_file,
            ...
        )
    } else {
        stop("Use SQLite for now...")
    }
    db_con
}

#' Get User Info from DB
#'
#' @param con DB connection.
#' @param user_id User ID.
#' @param deployment_id Deployment ID.
#'
#' @return A data frame with user info and access roles.
#'   The `"user_roles"` attribute gives the user roles as a vector.
#'
#' @export

db_read_user_info <- function(con, user_id, deployment_id) {
    # user info
    tbl_user <- dplyr::tbl(con, "users") |>
        dplyr::filter(.data$user_id == .env$user_id) |>
        dplyr::collect() |>
        dplyr::mutate(admin = as.logical(.data$admin))
    if (nrow(tbl_user) < 0L) {
        stop("User ", sQuote(user_id), " unknown.")
    }
    # user roles
    tbl_access <- dplyr::tbl(con, "access") |>
        dplyr::filter(
            .data$deployment_id == .env$deployment_id,
            .data$user_id == .env$user_id
        ) |>
        dplyr::collect()
    if (nrow(tbl_access) < 0L) {
        stop(
            "User ",
            sQuote(user_id),
            " has no access to deployment ",
            sQuote(deployment_id)
        )
    }
    v <- strsplit(tbl_access$user_roles, ",")[[1L]]
    roles <- get_user_roles(v)
    out <- data.frame(tbl_user, user_roles = tbl_access$user_roles, roles)
    attr(out, "user_roles") <- v
    out
}


#' Get Deployment Materials from DB
#'
#' @param con DB connection.
#' @param deployment_id Deployment ID.
#'
#' @return A data frame with joined deployment materials.
#'
#' @export
db_read_deployment_materials <- function(con, deployment_id = NULL) {
    dm <- dplyr::tbl(con, "deployment_materials")

    if(!is.null(deployment_id)) {
        dm <- dplyr::filter(dm, .data$deployment_id == .env$deployment_id)
    }
    
    dm <- dm |>
        dplyr::left_join(
            dplyr::tbl(con, "deployments"),
            by = "deployment_id"
        ) |>
        dplyr::left_join(
            dplyr::tbl(con, "materials"),
            by = "material_id"
        ) |>
        dplyr::left_join(
            dplyr::tbl(con, "models"),
            by = "model_id"
        ) |>
        dplyr::left_join(
            dplyr::tbl(con, "species"),
            by = "species_id"
        ) |>
        dplyr::collect() |>
        db_timestamp()

    dm
}

#' Get Comments from DB
#'
#' @param con DB connection.
#' @param deployment_id Deployment ID.
#'
#' @return A data frame with comments for the deployment.
#'
#' @export
db_read_comments <- function(con, deployment_id) {
    out <- dplyr::tbl(con, "comments") |>
        dplyr::filter(.data$deployment_id == .env$deployment_id) |>
        dplyr::collect() |>
        db_timestamp()
    out
}

#' Get Comments from DB
#'
#' @param con DB connection.
#' @param deployment_id Deployment ID.
#'
#' @return A data frame with evaluations for the deployment.
#'
#' @export
db_read_evaluations <- function(con, deployment_id = NULL) {
  out <- dplyr::tbl(con, "evaluations")
  if(!is.null(deployment_id)) {
    out <- dplyr::filter(out, .data$deployment_id == .env$deployment_id)
  }
  
  out <- out
    dplyr::collect() |>
    db_timestamp()
  
  out
}

# TODO:
# insert new values with dplyr::rows_insert(), only for new key values
# update existing rows with dplyr::rows_update(), all values

#' Get models from DB
#'
#' @param con DB connection.
#' @param model_id Model ID (optional).
#'
#' @return A data frame with models. Optionally filtered to model_id.
#'
#' @export
db_read_models <- function(con, model_id = NULL) {
    out <- dplyr::tbl(con, "models")
    if (!is.null(model_id)) {
        out <- dplyr::filter(out, .data$model_id %in% .env$model_id)
    }
    out <- dplyr::collect(out)
    out
}

#' Get species from DB
#'
#' @param con DB connection.
#' @param species_id Species ID (optional).
#' @param lang Language, the `lang` option is used if left `NULL`.
#'
#' @return A data frame with species and display names. Optionally filtered to
#'   species_id.
#'
#' @export
db_read_species <- function(
    con,
    species_id = NULL,
    lang = NULL
) {
    if (is.null(lang)) {
        lang <- sdmevaltool_options()$lang
    }
    out <- dplyr::tbl(con, "species")
    if (!is.null(species_id)) {
        out <- dplyr::filter(out, .data$species_id %in% .env$species_id)
    }
    out <- out |>
        dplyr::collect() |>
        dplyr::mutate(
            #fmt: skip
            species_display = paste0(
                .data[[paste0(lang, "_name")]], # cannot use .env inside .data
                " (", .data$scientific_name, ")"
            )
        )
    out
}
