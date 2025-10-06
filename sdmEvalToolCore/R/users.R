#' Get User Roles
#'
#' @param role Character, 1 or multiple user roles.
#'
#' @return A data frame with the permissible user actions (TRUE/FALSE).
#'
#' @examples
#' str(get_user_roles(c("modeler")))
#' str(get_user_roles(c("evaluator")))
#' str(get_user_roles(c("evaluator", "modeler")))
#'
#' @export
get_user_roles <- function(role) {
    r <- sdmEvalToolCore::user_roles
    role <- tolower(role)
    rownames(r) <- tolower(r$name)
    if (length(role) < 1L)
        stop("Provide at least 1 role.")
    if (length(role) == 1L) {
        if (!(role %in% row.names(r)))
            stop(sprintf("User role %s not found.", role))
        out <- r[role,]
        out <- out[names(out) != "name"]
    } else {
        if (any(!(role %in% row.names(r))))
            stop(sprintf("User role not found.", role))
        out <- r["viewer",]
        out <- out[names(out) != "name"]
        for (i in role) {
            for (j in names(out)) {
                if (r[i,j]) {
                    out[[j]] <- TRUE
                }
            }
        }
    }

    as.data.frame(out)
}
