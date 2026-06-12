#' Generate password
#'
#' @param length Length of the password. Default is 12.
#' @param start_with_letter Logical indicating if the password should start
#' with a letter. Default is TRUE.
#'
#' @examples
#' generate_password()
#'
#' @return A randomly generated password.
#'
#' @export
generate_password <- function(length = 12, start_with_letter = TRUE) {
  chars <- c(
    letters,
    LETTERS,
    0:9,
    "!",
    "@",
    "#",
    "$",
    "%",
    "^",
    "&",
    "*",
    "_",
    "+",
    "-",
    "="
  )
  if (start_with_letter) {
    first_char <- sample(c(letters, LETTERS), 1)
    paste0(
      first_char,
      paste0(sample(chars, length - 1, replace = TRUE), collapse = "")
    )
  } else {
    paste0(sample(chars, length, replace = TRUE), collapse = "")
  }
}

#' Make user database suitable for shinymanager
#'
#' @return A data frame with user credentials.
#' @export
make_user_db <- function() {
  con <- withr::local_db_connection(db_connect(db_path()))
  users <- sdmEvalToolCore::db_read_table(con, "users")
  users$user <- users$user_id
  users[, c("user", "password", "admin")]
}
