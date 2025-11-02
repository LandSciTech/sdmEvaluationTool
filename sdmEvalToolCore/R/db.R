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
#' @param userid User ID.
#' @param deploymentid Deployment ID.
#'
#' @return A data frame with user info and access roles.
#'   The `"user_roles"` attribute gives the user roles as a vector.
#'
#' @export
db_read_user_info <- function(con, userid, deploymentid) {
    # dealing with NSE
    user_id <- admin <- deployment_id <- NULL
    # user info
    tbl_user <- dplyr::tbl(con, "users") |>
        dplyr::filter(user_id == userid) |>
        dplyr::collect() |>
        dplyr::mutate(admin = as.logical(admin))
    if (nrow(tbl_user) < 0L) {
        stop("User ", sQuote(userid), " unknown.")
    }
    # user roles
    tbl_access <- dplyr::tbl(con, "access") |>
        dplyr::filter(
            deployment_id == deploymentid,
            user_id == userid
        ) |>
        dplyr::collect()
    if (nrow(tbl_access) < 0L) {
        stop(
            "User ",
            sQuote(userid),
            " has no access to deployment ",
            sQuote(deploymentid)
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
#' @param deploymentid Deployment ID.
#'
#' @return A data frame with joined deployment materials.
#'
#' @export
db_read_deployment_materials <- function(con, deploymentid) {
    # dealing with NSE
    deployment_id <- NULL
    dm <- dplyr::tbl(con, "deployment_materials") |>
        dplyr::filter(deployment_id == deploymentid) |>
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
#' @param deploymentid Deployment ID.
#'
#' @return A data frame with comments for the deployment.
#'
#' @export
db_read_comments <- function(con, deploymentid) {
    # dealing with NSE
    deployment_id <- NULL
    out <- dplyr::tbl(con, "comments") |>
        dplyr::filter(deployment_id == deploymentid) |>
        dplyr::collect() |>
        db_timestamp()
    out
}

#' Get Comments from DB
#'
#' @param con DB connection.
#' @param deploymentid Deployment ID.
#'
#' @return A data frame with evaluations for the deployment.
#'
#' @export
db_read_evaluations <- function(con, deploymentid) {
    # dealing with NSE
    deployment_id <- NULL
    out <- dplyr::tbl(con, "evaluations") |>
        dplyr::filter(deployment_id == deploymentid) |>
        dplyr::collect() |>
        db_timestamp()
    out
}

# TODO:
# insert new values with dplyr::rows_insert(), only for new key values
# update existing rows with dplyr::rows_update(), all values
