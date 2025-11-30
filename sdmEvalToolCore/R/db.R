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
#' @param deployment_id Deployment IDs (multiple permitted).
#' @param user_id User ID.
#'
#' @return A data frame with joined deployment materials.
#'
#' @export
db_read_deployment_materials <- function(
    con,
    deployment_id = NULL,
    user_id = NULL
) {
    dm <- dplyr::tbl(con, "deployment_materials")

    if (!is.null(deployment_id)) {
        dm <- dplyr::filter(dm, .data$deployment_id %in% .env$deployment_id)
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
        )

    if (!is.null(user_id)) {
        dm <- dplyr::filter(dm, .data$deployment_create_user == .env$user_id)
    }

    dm <- dm |>
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
#' @param user_id Evaluation create user IDs (multiple allowed).
#'
#' @return A data frame with evaluations for the deployment.
#'
#' @export
db_read_evaluations <- function(con, deployment_id = NULL, user_id = NULL) {
    out <- dplyr::tbl(con, "evaluations")
    if (!is.null(deployment_id)) {
        out <- dplyr::filter(out, .data$deployment_id == .env$deployment_id)
    }

    if (!is.null(user_id)) {
        out <- dplyr::filter(
            out,
            .data$evaluation_create_user %in% .env$user_id
        )
    }

    out <- out |>
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
#'
#' @return A data frame with species and display names. Optionally filtered to
#'   species_id.
#'
#' @export
db_read_species <- function(
    con,
    species_id = NULL
) {
    out <- dplyr::tbl(con, "species")
    if (!is.null(species_id)) {
        out <- dplyr::filter(out, .data$species_id %in% .env$species_id)
    }
    out <- dplyr::collect(out)
    out
}


#' Make table SQL statement
#'
#' @param table_name Character, table name.
#' @param force Logical, force (create even if not exists).
#'
#' @noRd
make_table_statement <- function(
    table_name,
    force = FALSE
) {
    field_types <- data.frame(
        field_type = c(
            "date",
            "jsonb",
            "real",
            "text",
            "timestamp",
            "uuid",
            "boolean"
        ),
        sqlite = c(
            "TEXT",
            "TEXT",
            "REAL",
            "TEXT",
            "INTEGER",
            "TEXT",
            "INTEGER"
        ),
        postgresql = c(
            "date",
            "jsonb",
            "real",
            "text",
            "timestamp",
            "text",
            "boolean"
        )
    )
    dbtype <- sdmevaltool_options()$db
    f <- sdmEvalToolCore::fields
    f <- f[f$table == table_name, c("field", "type", "constraint")]
    f$type <- field_types[[dbtype]][match(f$type, field_types$field_type)]
    # add here table constraints
    tc <- ""
    if (tc != "") {
        tc <- paste0(", ", tc)
    }
    v <- paste0(
        trimws(paste(f$field, f$type, f$constraint)),
        collapse = ", "
    )
    o <- paste0(
        "CREATE TABLE ",
        if (force) "" else "IF NOT EXISTS ",
        table_name,
        " (",
        v,
        tc,
        ");",
        collapse = ""
    )
    o <- gsub(" ,", ",", o, fixed = TRUE)
    o <- gsub(",);", ");", o, fixed = TRUE)
    o
}

#' Create DB tables
#'
#' @param con DB connection.
#' @param tables Character, table name.
#' @param force Logical, force (create even if not exists).
#' @param verbose Logical.
#'
#' @export
db_create_tables <- function(
    con,
    tables = NULL,
    force = FALSE,
    verbose = TRUE
) {
    tables_exist <- DBI::dbListTables(con)
    dbtype <- sdmevaltool_options()$db
    if (verbose) {
        cat("Creating tables in ", sQuote(dbtype), ":\n", sep = "")
    }
    # DBI::dbBegin(con)
    # on.exit(DBI::dbCommit(con))
    all_tables <- sdmEvalToolCore::tables$table
    if (is.null(tables)) {
        tables <- all_tables
    }
    tables <- tables[tables %in% all_tables]
    for (table_name in tables) {
        if (verbose) {
            cat(
                "* Create table ",
                sQuote(table_name),
                if (table_name %in% tables_exist) " (exists)" else "",
                " ...",
                sep = ""
            )
        }
        q <- make_table_statement(
            table_name = table_name,
            force = force
        )
        res <- DBI::dbSendQuery(con, q)
        DBI::dbClearResult(res)
        if (verbose) {
            cat(" OK\n")
        }
    }
    # DBI::dbCommit(con)
    invisible(TRUE)
}

#' Write data to a table
#'
#' Data will be appended to an existing DB table.
#'
#' @param con A database connection.
#' @param table Table name.
#' @param data Data frame to append to the DB table.
#' @param validate Logical, should `data` be validated?
#' @param verbose Logical.
#'
#' @return Invisible `TRUE`.
#' @export
db_write_table <- function(con, table, data, validate = TRUE, verbose = TRUE) {
    if (validate) {
        check_table(data, table, dryrun = FALSE, verbose = verbose)
    }
    if (verbose) {
        cat("Writing data to table", sQuote(table), "...")
    }
    out <- DBI::dbWriteTable(con, name = table, value = data, append = TRUE)
    if (verbose) {
        cat("OK\n")
    }
    invisible(out)
}
