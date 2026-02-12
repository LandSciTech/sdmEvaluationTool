.onAttach <- function(libname, pkgname) {
    ver <- read.dcf(
        file = system.file("DESCRIPTION", package = pkgname),
        fields = c("Version")
    )
    packageStartupMessage(paste(pkgname, ver[1]))
    invisible(NULL)
}

options_set <- FALSE

.onLoad <- function(libname, pkgname) {
    if (is.null(getOption("sdmevaltool_options"))) {
        options_set <<- TRUE
        options(
            "sdmevaltool_options" = list(
                base = "./sdm_evaluation_results",
                db = "sqlite",
                tz = "", # time zone for unix dates
                lang = "english",
                verbose = 2 # 0=none, 1=sparse, 2=all
            )
        )
    }
    invisible(NULL)
}

.onUnload <- function(libpath) {
    if (options_set) {
        options("sdmevaltool_options" = NULL)
    }
    invisible(NULL)
}

#' Package Options
#'
#' @param ... Names list of options.
#' @examples
#' (sdmevaltool_options())
#'
#' @export
sdmevaltool_options <- function(...) {
    opar <- getOption("sdmevaltool_options")
    args <- list(...)
    if (length(args)) {
        if (length(args) == 1 && is.list(args[[1]])) {
            npar <- args[[1]]
        } else {
            npar <- opar
            npar[match(names(args), names(npar))] <- args
        }
        options("sdmevaltool_options" = npar)
    }
    invisible(opar)
}
