#' Expand a list into objects in the environment
#'
#' @param l List of items to expand into objects
#' @param env Environment in which objects should be placed
#'
#' @returns Nothing. Objects now in environment
#'
#' @noRd

expand_list <- function(l, env = rlang::caller_env()) {
  rlang::env_bind(env, !!!l)
}

#' Expand a dots list into objects in the environment
#'
#' @param ... Dots list of items to expand into objects
#' @param env Environment in which objects should be placed
#'
#' @returns Nothing. Objects now in environment
#'
#' @noRd

expand_dots <- function(..., env = rlang::caller_env()) {
  rlang::env_bind(env, !!!list(...))
}


#' Have local data?
#'
#' Checks whether the user has local data available for this tool.
#' Used for examples (must be exported).
#'
#' @returns TRUE/FALSE
#'
#' @export
#' @examples
#' have_data()
have_data <- function() {
  dir.exists(sdmEvalToolCore::sdmevaltool_options()$base)
}

#' Create named lists of ids for input selections
#'
#' Lists are c(named = id) to create a input selection with 'pretty' selections
#' returning original ids.
#'
#' @param df_db Data frame or database where ID values can be found.
#' @param id Character. Pattern matching 'id' in the column name.
#' @param name Character. Pattern matching 'name' in the column name.
#' @param match Character. ID/Name preface. Optional instead of `id`/`name`,
#'   useful if there are more than one pair of id/name in the data frame.
#'
#' @returns Named character vector.
#'
#' @export
#' @examplesIf have_data()
#' df <- data.frame(
#'   species_id = c("X11", "Y22"),
#'   species_name = c("Pretty name", "Lovely name")
#' )
#'
#' named_ids(df)
#' named_ids(df, match = "species")

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
#' May not be necessary in the long run...
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


#' Loosely test if identical
#'
#' Used in [mod_utils_evaluations_server()] to loosely determine if evaluations
#' are identical between saved and inputs (to determine if the unsaved notice
#' should be used).
#'
#' @param i1 Character
#' @param i2 Character
#'
#' @returns Logical
#'
#' @export

identical_loose <- function(i1, i2) {
  if (!isTruthy(i1)) {
    i1 <- ""
  }
  if (!isTruthy(i2)) {
    i2 <- ""
  }

  identical(i1, i2)
}

#' Evaluation answers in the affirmative
#'
#' Used to determine which parts should be displayed
#'
#' @param type Character. "standard" (currently for ordinal inputs), or
#' "spatial"
#'
#' @returns Character vector of affirmative answers
#'
#' @export
#' @examples
#' affirmative()
#' affirmative("spatial")

affirmative <- function(type = "standard") {
  # CLEANUP: Put this somewhere better?

  if (type == "standard") {
    a <- c("Extremely", "Very", "Moderately", "Slightly", "Yes")
  } else if (type == "spatial") {
    a <- c(
      "Very_biased",
      "Moderately_biased",
      "Very_undersampled",
      "Moderately_undersampled",
      "Over*_prediction",
      "Under*_prediction",
      "Uncertain_but_seems_inaccurate",
      "Comment",
      "Inaccurate",
      "Greater_than_expected",
      "Less_than_expected"
    )
  }
  a
}
