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
    tab <- sdmEvalToolCore::tables
    table_name <- match.arg(table_name, unique(tab$table), several.ok = FALSE)
    tab[tab$table == table_name, colnames(tab) != "table"]
}
