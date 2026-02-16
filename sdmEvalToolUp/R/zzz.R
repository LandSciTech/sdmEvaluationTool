#fmt: skip
# utils::globalVariables(c())

.onAttach <- function(libname, pkgname) {
    ver <- read.dcf(
        file = system.file("DESCRIPTION", package = pkgname),
        fields = c("Version")
    )
    packageStartupMessage(paste(pkgname, ver[1]))
    invisible(NULL)
}
