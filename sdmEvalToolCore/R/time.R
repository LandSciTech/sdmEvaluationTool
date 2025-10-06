#' Handling Timestamps
#'
#' @param ms  Unix time in milliseconds.
#' @param tz Time zone, when `NULL` it defaults to `sdmevaltool_options()$tz`.
#' @param dt POSIXct coercible date/time value.
#' @param ... Other optional arguments passed to [as.POSIXct()].
#'
#' @examples
#' dt1 <- as.POSIXct("2020-12-24 21:15:49 MDT")
#' dt2 <- timestamp_to(dt1)
#' dt3 <- timestamp_from(dt2)
#' stopifnot(identical(dt3, dt1))
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
## unix times in milliseconds (sec x1000)
## function to transform unix dates to POSIXct
timestamp_from <- function(ms, tz = NULL, ...) {
    if (is.null(tz))
        tz <- sdmevaltool_options()$tz
    as.POSIXct(as.numeric(ms)/1000, tz = tz, origin="1970-01-01", ...)
}

#' @export
#' @rdname timestamp
## turning POSIXct to unix time
timestamp_to <- function(dt) {
    as.character(round(unclass(as.POSIXct(dt))*1000))
}
