#' Handling Timestamps
#'
#' @param ms  Unix time in seconds.
#' @param tz Time zone, when `NULL` it defaults to `sdmevaltool_options()$tz`.
#' @param dt POSIXct coercible date/time value.
#' @param ... Other optional arguments passed to [as.POSIXct()].
#'
#' @examples
#' dt1 <- now()
#' timestamp_to(dt1)
#' timestamp_from(timestamp_to(dt1))
#'
#' @return
#'
#' `timestamp_from` returns [POSIXct()].
#'
#' `timestamp_to` returns Unix time as character .
#'
#' @seealso [sdmevaltool_options()] to set `tz` globally.
#'
#' @name timestamp
NULL

#' @export
#' @rdname timestamp
## unix times in seconds
## function to transform unix dates to POSIXct
timestamp_from <- function(ms, tz = NULL, ...) {
    if (is.null(tz)) {
        tz <- sdmevaltool_options()$tz
    }
    as.POSIXct(as.numeric(ms), tz = tz, origin = "1970-01-01", ...)
}

#' @export
#' @rdname timestamp
## turning POSIXct to unix time
timestamp_to <- function(dt) {
    as.integer(round(unclass(as.POSIXct(dt))))
}

#' @export
#' @rdname timestamp
now <- function() {
    Sys.time()
}
