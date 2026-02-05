expand_list <- function(l, env = rlang::caller_env()) {
  rlang::env_bind(env, !!!l)
}

expand_dots <- function(..., env = rlang::caller_env()) {
  rlang::env_bind(env, !!!list(...))
}


pretty <- function(x) {
  x |>
    stringr::str_replace_all("_", " ") |>
    stringr::str_remove_all("id") |>
    stringr::str_to_title()
}

#' Have local data?
#'
#' Checks whether the user has local data available for this tool.
#'
#' @returns TRUE/FALSE
#'
#' @export
#' @examples
#' have_data()
have_data <- function() {
  dir.exists(sdmEvalToolCore::sdmevaltool_options()$base)
}


dummy_session <- list(ns = \(x) paste0("session-", x))

#' Temporarily skip examples
#'
#' Examples using @examplesIf, will fail if there is nothing to run (i.e.
#' becaues the example is commented out waiting for a working version).
#'
#' @returns Nothing
#'
#' @export
#' @examples
#' skip_eg()

skip_eg <- function() {
  invisible()
}


named_ids <- function(df_db, id = "id", name = "name", match = NULL) {
  if (is.null(match)) {
    pattern <- glue::glue("\\_{id}|\\_{name}")
  } else {
    pattern <- glue::glue("{match}\\_{id}|{match}\\_{name}")
  }
  type <- stringr::str_subset(colnames(df_db), pattern)

  if (
    length(type) != 2 ||
      length(unique(stringr::str_remove(type, pattern))) != 1
  ) {
    stop("Non-matching id/name column pairs", call. = FALSE)
  }
  df_db <- dplyr::select(df_db, dplyr::all_of(type)) |>
    dplyr::distinct()

  rlang::set_names(
    dplyr::pull(df_db, .data[[type[1]]]),
    dplyr::pull(df_db, .data[[type[2]]])
  )
}


#' Set sdmEvalTool options
#'
#' @param ... Named list of options to set
#'
#' @returns list of options currently set
#'
#' @export
set_options <- function(...) {
  # CLEANUP: Perhaps integrate with sdmEvalToolCore?
  opts <- getOption("sdmevaltool_options")
  o <- options("sdmevaltool_options" = utils::modifyList(opts, list(...)))
  o
}

#' Return the app language
#'
#' @returns Character. Either "english" or "french"
#'
#' @export
#' @examples
#' lang()

lang <- function() {
  sdmevaltool_options()$lang
}


identical_loose <- function(i1, i2) {
  if (!isTruthy(i1)) {
    i1 <- ""
  }
  if (!isTruthy(i2)) {
    i2 <- ""
  }

  identical(i1, i2)
}
