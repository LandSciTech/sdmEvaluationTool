#' Get File Extension
#'
#' @param path Character, a file path.
#'
#' @return Lower case file extension as string.
#'
#' @examples
#' get_file_ext("bam_v5/oven/observations.parquet")
#'
#' @export
get_file_ext <- function(path) {
  tolower(tools::file_ext(basename(path)))
}

#' Make Target Path
#'
#' @param path Character, a file path.
#' @param data List with name value pairs, the values are substituted
#'   into the path according to glue rules (with curly braces).
#' @param base Character, base path, defaults to `sdmevaltool_options()$base`
#'   when `NULL`.
#'
#' @return The path string with data values substituted.
#'
#' @examples
#' make_target_path("bam_v5/oven/observations.parquet")
#' make_target_path("{model}/{species}/observations.parquet",
#'   list(model = "bam_v5", species = "oven"))
#' make_target_path("{model}/{species}/observations.parquet",
#'   list(model = "bam_v5", species = "oven"), ".")
#'
#' @export
make_target_path <- function(path, data = list(), base = NULL) {
  if (is.null(base)) {
    base <- sdmevaltool_options()$base
  }
  path <- glue::glue_data(.x = data, path)
  file.path(base, path)
}

#' Make Directory
#'
#' @param path Character, a file path.
#' @param ... Arguments passed to [dir.create()].
#'
#' @return Create a directory recursively as a side effect,
#'   returning logical indicating the result ().
#'
#' @export
make_dir <- function(path, ...) {
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE, ...)
}

#' Read File
#'
#' @param path Character, a file path.
#' @param ... Arguments passed to the reader functions.
#'
#' @return Return the result from the file.
#'
#' @export
read_file <- function(path, ...) {
  ext <- get_file_ext(path)
  switch(
    ext,
    "csv" = utils::read.csv(path, ...),
    "rds" = base::readRDS(path, ...),
    "parquet" = arrow::read_parquet(path, ...),
    "gpkg" = sf::read_sf(path, ...),
    "tif" = terra::rast(path, ...),
    "json" = jsonlite::fromJSON(readLines(path), ...),
    "md" = readLines(path, ...),
    "rmd" = readLines(path, ...),
    "txt" = readLines(path, ...),
    stop(sprintf("File extension %s not recognized", ext))
  )
}

#' Write File
#'
#' @param x Object to write.
#' @param path Character, a file path.
#' @param ... Arguments passed to the writer functions.
#'
#' @return Writes file as a side effect.
#'
#' @export
write_file <- function(x, path, ...) {
  make_dir(path)
  ext <- get_file_ext(path)
  switch(
    ext,
    "csv" = utils::write.csv(x, path, ...),
    "rds" = base::saveRDS(x, path, ...),
    "parquet" = arrow::write_parquet(x, path, ...),
    "gpkg" = sf::write_sf(x, path, delete_dsn = file.exists(path), ...),
    "tif" = terra::writeRaster(x, path, overwrite = TRUE, ...),
    "json" = writeLines(jsonlite::toJSON(x, ...), path),
    "md" = writeLines(x, path, ...),
    "rmd" = writeLines(x, path, ...),
    "txt" = writeLines(x, path, ...),
    stop(sprintf("File extension %s not recognized", ext))
  )
}
