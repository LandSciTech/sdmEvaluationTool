get_file_ext <- function(path) {
    fn <- basename(path)
    tolower(rev(strsplit(fn, "\\.")[[1L]])[1L])
}
# get_file_ext("bam_v5/oven/observations.parquet")

make_target_path <- function(path, data = list(), base = NULL) {
    if (is.null(base)) {
        base <- sdmevaltool_options()$base
    }
    path <- glue::glue_data(.x = data, path)
    file.path(base, path)
}
# make_target_path("bam_v5/oven/observations.parquet")
# make_target_path("{model}/{species}/observations.parquet", list(model = "bam_v5", species = "oven"))
# make_target_path("{model}/{species}/observations.parquet", list(model = "bam_v5", species = "oven"), ".")

make_dir <- function(path, ...) {
    dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE, ...)
}

read_file <- function(path, ...) {
    ext <- get_file_ext(path)
    switch(
        ext,
        "csv" = utils::read.csv(path, ...),
        "rds" = base::readRDS(path, ...),
        "parquet" = arrow::read_parquet(path, ...),
        "gpkg" = sf::read_sf(path, ...),
        "tif" = terra::rast(path, ...),
        stop(sprintf("File extension %s not recognized", ext))
    )
}

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
        stop(sprintf("File extension %s not recognized", ext))
    )
}
