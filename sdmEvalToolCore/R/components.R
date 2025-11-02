#' Which Components Are Ready
#'
#' @param ready Character, component names that are ready.
#'
#' @return A data frame with components and a column telling which ones are ready.
#' The `"percent_ready"` attribute gives a percentage value of the
#' mandatory components that are ready.
#'
#' @examples
#' r <- get_comp_ready(c("observations", "model_metadata"))
#' r
#' attr(r, "percent_ready")
#'
#' @export
get_comp_ready <- function(ready = character(0L)) {
    out <- sdmEvalToolCore::components[, c("component", "mandatory")]
    out$ready <- out$component %in% ready
    attr(out, "percent_ready") <- round(
        100 * sum(out$ready & out$mandatory) / sum(out$mandatory),
        1
    )
    out
}

#' Get Rule for a Component
#'
#' @param component_id Character, component name (length 1).
#' @param rule_type CHaracter, the type of rule.
#'
#' @return A list with the rules, or `NULL`.
#'
#' @examples
#' str(get_comp_rule("observations", "upload"))
#' str(get_comp_rule("observations", "evaluation"))
#'
#' @export
get_comp_rule <- function(
    component_id,
    rule_type = c("upload", "display", "evaluation")
) {
    if (length(component_id) > 1L) {
        stop("component_id must have length of 1.")
    }
    rule_type <- match.arg(rule_type)
    cmp <- sdmEvalToolCore::components
    rownames(cmp) <- cmp$component
    if (is.na(cmp[component_id, rule_type])) {
        NULL
    } else {
        cmp[component_id, rule_type][[1L]]
    }
}
