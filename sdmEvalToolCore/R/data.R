#' Components
#'
#' @format A data frame with component configuration (some columns are lists).
"components"

#' User Roles
#'
#' @format A data frame.
"user_roles"

#' Tables
#'
#' @format A data frame.
"tables"

#' Fields
#'
#' @format A data frame.
"fields"

#' Get Table Fields
#'
#' @param table_name Table name.
#'
#' @return A data frame.
#'
#' @examples
#' get_fields("users")
#' get_fields("components")
#' @export
get_fields <- function(table_name) {
    tab <- sdmEvalToolCore::fields
    table_name <- match.arg(table_name, unique(tab$table), several.ok = FALSE)
    tab[tab$table == table_name, colnames(tab) != "table"]
}

#' Scaffold Table
#'
#' @param table_name Table name.
#'
#' @return A data frame returned invisibly, called for the printed side effects.
#'
#' @examples
#' scaffold_table("users")
#' scaffold_table("materials")
#' @export
scaffold_table <- function(table_name) {
    tt <- get_fields(table_name)
    cat(paste0(table_name, " <- data.frame("),
        paste0("    ", tt$field[1:(nrow(tt)-1)], " = ...,"), 
        paste0("    ", tt$field[nrow(tt)], " = ...)"),
        sep = "\n")
    invisible(tt)
}
