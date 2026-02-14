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
#' @param dbname DB name.
#' @param ... Arguments passed to [DBI::dbConnect()].
#'
#' @return A database connection.
#'
#' @export
db_connect <- function(dbname = NULL, ...) {
    if (sdmevaltool_options()$db == "sqlite") {
        if (is.null(dbname)) {
            dbname <- make_target_path("sdm_evaluation_db.sqlite")
        }
        db_con <- DBI::dbConnect(
            drv = RSQLite::SQLite(),
            dbname = dbname,
            ...
        )
    } else {
        stop("Use SQLite for now...")
    }
    db_con
}

#' Disconnect from Database
#'
#' @param con DB connection.
#' @param ... Arguments passed to [DBI::dbDisconnect()].
#'
#' @export
db_disconnect <- function(con, ...) {
    DBI::dbDisconnect(con, ...)
}

#' Get Table from DB
#'
#' @param con DB connection.
#' @param table_name Table name.
#'
#' @return A data frame with the table data.
#'
#' @export
db_read_table <- function(con, table_name) {
    dbplyr::dbplyr_edition()
    out <- dplyr::tbl(con, table_name) |>
        dplyr::collect() |>
        db_timestamp()
    jf <- sdmEvalToolCore::fields |>
        dplyr::filter(type == "jsonb", table == table_name)
    for (i in jf$field) {
        out[[i]] <- lapply(
            out[[i]],
            \(z) {
                if (is.na(z)) list() else jsonlite::fromJSON(z)
            }
        )
    }
    bf <- sdmEvalToolCore::fields |>
        dplyr::filter(type == "boolean", table == table_name)
    for (i in bf$field) {
        out[[i]] <- as.logical(out[[i]])
    }
    out
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
    dbplyr::dbplyr_edition()
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
    out <- data.frame(
        tbl_user,
        deployment_id = deployment_id,
        user_roles = tbl_access$user_roles,
        roles
    )
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
    dbplyr::dbplyr_edition()
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
    dbplyr::dbplyr_edition()
    out <- dplyr::tbl(con, "comments") |>
        dplyr::filter(.data$deployment_id == .env$deployment_id) |>
        dplyr::collect() |>
        db_timestamp()
    out
}

#' Get Evaluations from DB
#'
#' @param con DB connection.
#' @param deployment_id Deployment ID.
#' @param user_id Evaluation create user IDs (multiple allowed).
#'
#' @return A data frame with evaluations for the deployment.
#'
#' @export
db_read_evaluations <- function(con, deployment_id = NULL, user_id = NULL) {
    dbplyr::dbplyr_edition()
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

#' Get models from DB
#'
#' @param con DB connection.
#' @param model_id Model ID (optional).
#'
#' @return A data frame with models. Optionally filtered to model_id.
#'
#' @export
db_read_models <- function(con, model_id = NULL) {
    dbplyr::dbplyr_edition()
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
    dbplyr::dbplyr_edition()
    out <- dplyr::tbl(con, "species")
    if (!is.null(species_id)) {
        out <- dplyr::filter(out, .data$species_id %in% .env$species_id)
    }
    out <- dplyr::collect(out)
    out
}


#' Make create table SQL statement
#'
#' @param table_name Character, table name.
#' @param force Logical, force (create even if not exists).
#'
#' @noRd
make_create_table_statement <- function(
    table_name,
    force = FALSE
) {
    if (!(table_name %in% sdmEvalToolCore::tables$table)) {
        stop("Table ", sQuote(table_name), " not part of the spec.")
    }
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
    tc <- sdmEvalToolCore::tables
    tc <- tc[tc$table == table_name, "table_constraint"]
    tc <- if (!is.na(tc)) paste0(", ", tc) else ""
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

#' Check if table exists in DB
#'
#' @param con DB connection.
#' @param table Table name.
#' @param dryrun Logical.
#'
#' @noRd
check_table_exists <- function(con, table, dryrun = FALSE) {
    ok <- DBI::dbExistsTable(con, table)
    if (!ok) {
        if (dryrun) {
            if (sdmevaltool_options()$verbose >= 1) {
                cat("Table ", sQuote(table), " does not exists.\n", sep = "")
            }
        } else {
            stop("Table ", sQuote(table), " does not exists.")
        }
    } else {
        if (sdmevaltool_options()$verbose >= 1) {
            cat("Table ", sQuote(table), " exists.\n", sep = "")
        }
    }
    invisible(ok)
}

#' Create DB tables
#'
#' @param con DB connection.
#' @param tables Character, table name.
#' @param force Logical, force (create even if not exists).
#'
#' @examples
#' con <- db_connect(":memory:")
#' db_create_tables(con, "models")
#' db_create_tables(con)
#' db_disconnect(con)
#'
#' @export
db_create_tables <- function(
    con,
    tables = NULL,
    force = FALSE
) {
    tables_exist <- DBI::dbListTables(con)
    dbtype <- sdmevaltool_options()$db
    verbose <- sdmevaltool_options()$verbose
    if (verbose >= 1) {
        cat("Creating tables in ", sQuote(dbtype), sep = "")
    }
    # DBI::dbBegin(con)
    # on.exit(DBI::dbCommit(con))
    all_tables <- sdmEvalToolCore::tables$table
    if (is.null(tables)) {
        tables <- all_tables
    }
    tables <- tables[tables %in% all_tables]
    for (table_name in tables) {
        if (verbose >= 2) {
            cat(
                "\n* Create table ",
                sQuote(table_name),
                if (table_name %in% tables_exist) " (exists)" else "",
                " ... ",
                sep = ""
            )
        }
        q <- make_create_table_statement(
            table_name = table_name,
            force = force
        )
        res <- DBI::dbSendQuery(con, q)
        DBI::dbClearResult(res)
        if (verbose) {
            cat("OK")
        }
    }
    if (verbose >= 1) {
        cat("\n")
    }
    # DBI::dbCommit(con)
    invisible(TRUE)
}

#' Write Data to an Existing Table
#'
#' Data will be inserted/updated/upserted in an existing DB table.
#'
#' @param con A database connection.
#' @param table Table name.
#' @param data Data frame to append to the DB table.
#' @param mode How to execute the write operation:
#'   insert (append) new record,
#'   update existing record, or
#'   upsert (update existing or insert if not).
#' @param check Logical, should `data` be validated?
#' @param dryrun Logical, write to a text file when `TRUE`
#'   and to the database when `FALSE`.
#'
#' @examples
#' con <- db_connect(":memory:")
#' db_create_tables(con, "models")
#' models <- data.frame(
#'     model_id = "bam_v5_can71",
#'     model_name = "BAM v5 Can 71",
#'     model_description = "BAM version 5 Canada model in BCR 71"
#' )
#' db_write_table(con, "models", models, mode = "insert")
#' db_disconnect(con)
#'
#' @return Invisible `TRUE`.
#' @export
db_write_table <- function(
    con,
    table,
    data,
    mode = c("insert", "update", "upsert"),
    check = TRUE,
    dryrun = FALSE
) {
    mode <- match.arg(mode)
    verbose <- sdmevaltool_options()$verbose
    check_table_exists(con, table, dryrun = dryrun)
    if (check) {
        check_table(data, table, dryrun = dryrun)
    }
    ks <- get_table_keys(table)
    w <- switch(
        mode,
        "insert" = "Inserting",
        "update" = "Updating",
        "upsert" = "Upserting"
    )
    if (verbose >= 1) {
        cat(w, "data to table ", sQuote(table), "... ")
    }
    if (dryrun) {
        tmp <- make_target_path("_sdm_evaluation_db.log")
        h <- sprintf(
            "--- %s data to table %s at %s ---",
            w,
            sQuote(table),
            as.character(Sys.time())
        )
        txt <- if (file.exists(tmp)) {
            c(readLines(tmp), h)
        }
        txt <- c(
            txt,
            jsonlite::toJSON(data, auto_unbox = TRUE)
        )
        res <- writeLines(txt, tmp)
    } else {
        if (mode == "insert") {
            # this can be a bulk operation (>1 rows)
            # need to make sure all columns are part of data
            if (!all(names(data) %in% ks$field)) {
                stop("All columns in data must be present according to spec.")
            }
            res <- DBI::dbAppendTable(
                con,
                name = table,
                value = data
            )
        }
        if (mode == "update") {
            # if key columns are not updated
            # columns can be missing --> these won't be updated
            # data needs to have exactly 1 row
            q <- make_update_table_statement(data, table, drop_keys = TRUE)
            res <- DBI::dbSendQuery(con, q)
            DBI::dbClearResult(res)
        }
        if (mode == "upsert") {
            # best to provide all columns to satisfy key constraints
            # key columns are not dropped
            # data needs to have exactly 1 row
            q <- make_upsert_table_statement(data, table)
            res <- DBI::dbSendQuery(con, q)
            DBI::dbClearResult(res)
        }
    }
    if (verbose >= 1) {
        cat("OK\n")
    }
    invisible(TRUE)
}

#' Get Keys for a Table
#'
#' @param table Table name.
#'
#' @return A data frame with PK/FK information.
#'
#' @noRd
get_table_keys <- function(table) {
    tb <- sdmEvalToolCore::tables
    fd <- sdmEvalToolCore::fields
    tb1 <- tb[tb$table == table, , drop = FALSE]
    fd1 <- fd[fd$table == table, , drop = FALSE]
    # FK
    fk <- fd1$field[grep("REFERENCES", fd1$constraint)]
    if (length(fk) > 0L) {
        ref <- fd1$constraint[grep("REFERENCES", fd1$constraint)]
        ref <- gsub("REFERENCES", "", ref)
        ref <- strsplit(ref, "(", fixed = TRUE)
        ref <- lapply(ref, function(z) gsub("[^[:alnum:]_]", "", z))
        fk_table <- sapply(ref, "[[", 1L)
        fk_field <- sapply(ref, "[[", 2L)
    }
    # PK
    if (is.na(tb1$table_constraint)) {
        pk <- fd1$field[grep("PRIMARY KEY", fd1$constraint)]
    } else {
        pk <- tb1$table_constraint
        pk <- gsub("PRIMARY KEY", "", pk)
        pk <- strsplit(pk, ",")[[1L]]
        pk <- gsub("[^[:alnum:]_]", "", pk)
    }
    out <- fd1[, c("table", "field", "type", "constraint")]
    out$pk <- out$field %in% pk
    if (length(fk) > 0L) {
        out$fk_table <- fk_table[match(out$field, fk_field)]
        out$fk_field <- fk_field[match(out$field, fk_field)]
    } else {
        out$fk_table <- NA_character_
        out$fk_field <- NA_character_
    }
    out
}

#' SQL to Update Table
#'
#' @param data Data frame with 1 row and with expected columns:
#'   Provide all primary key columns for the update condition,
#'   and any other column for which values are updated.
#' @param table Table name.
#' @param drop_keys Logical, should PK/FK columns be dropped.
#'
#' @return An SQL query statement.
#'
#' @noRd
make_update_table_statement <- function(data, table, drop_keys = TRUE) {
    if (nrow(data) != 1L) {
        stop("data must have exactly 1 row.")
    }
    ks <- get_table_keys(table)
    pk <- ks$field[ks$pk]
    d1 <- data[[pk[1L]]]
    if (is.character(d1)) {
        d1 <- paste0("'", d1, "'", collapse = "")
    }
    # where clause
    wd <- c(pk[1L], "=", d1)
    for (i in seq_along(pk)[-1L]) {
        d1 <- data[[pk[i]]]
        if (is.na(d1)) {
            stop("Key ", sQuote(pk[[i]]), " must not be NA.")
        } else {
            if (is.character(d1)) {
                d1 <- paste0("'", d1, "'", collapse = "")
            }
        }
        wd <- c(wd, " AND ", pk[i], "=", d1)
    }
    # updated fields
    if (drop_keys) {
        allk <- unique(c(ks$field[ks$pk], ks$field[!is.na(ks$fk_field)]))
        data <- data[, !(names(data) %in% allk), drop = FALSE]
    }
    nd <- NULL
    for (i in seq_len(ncol(data))) {
        d1 <- data[[i]]
        if (is.na(d1)) {
            d1 <- "NULL"
        } else {
            if (is.character(d1)) {
                d1 <- paste0(
                    "'",
                    gsub("'", "''", enc2utf8(d1)),
                    "'",
                    collapse = ""
                )
            }
        }
        nd <- c(nd, paste0(names(data)[i], "=", d1, collapse = ""))
    }
    q <- paste0(
        "UPDATE ",
        table,
        " SET ",
        paste0(nd, collapse = ", "),
        " WHERE ",
        paste0(wd, collapse = ""),
        ";"
    )
    q
}

#' SQL to Upsert Table
#'
#' @param data Data frame with 1 row and with all columns.
#' @param table Table name.
#'
#' @return An SQL query statement.
#'
#' @noRd
make_upsert_table_statement <- function(data, table) {
    if (nrow(data) != 1L) {
        stop("data must have exactly 1 row.")
    }
    ks <- get_table_keys(table)
    if (!all(names(data) %in% ks$field)) {
        stop("All columns in data must be present according to spec.")
    }

    pk <- ks$field[ks$pk]
    nd <- NULL
    cs <- NULL
    vs <- NULL
    for (i in seq_len(ncol(data))) {
        d1 <- data[[i]]
        if (is.na(d1)) {
            d1 <- "NULL"
        } else {
            if (is.character(d1)) {
                d1 <- paste0(
                    "'",
                    gsub("'", "''", enc2utf8(d1)),
                    "'",
                    collapse = ""
                )
            }
        }
        nd <- c(nd, paste0(names(data)[i], "=", d1, collapse = ""))
        cs <- c(cs, names(data)[i])
        vs <- c(vs, d1)
    }
    q <- paste0(
        "INSERT INTO ",
        table,
        " (",
        paste0(cs, collapse = ", "),
        ") VALUES (",
        paste0(vs, collapse = ", "),
        ") ON CONFLICT (",
        paste0(pk, collapse = ", "),
        ") DO UPDATE SET ",
        paste0(nd, collapse = ", "),
        ";"
    )
    q
}

#' Handling Boolean
#'
#' @param x An R vector.
#'
#' @export
fromBoolean <- function(x) {
    if (is.logical(x)) {
        x
    } else {
        as.logical(x)
    }
}
