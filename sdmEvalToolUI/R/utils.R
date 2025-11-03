prep_data <- function(lang = "english") {
  # TODO: Assign this elsewhere?
  sdmEvalToolCore::sdmevaltool_options(base = "../misc/base")

  path_data <- file.path(
    sdmEvalToolCore::sdmevaltool_options()$base,
    "sdm_evaluation_db.sqlite"
  )

  db <- DBI::dbConnect(path_data, drv = RSQLite::SQLite())
  tbl_models <- dplyr::tbl(db, "models") |>
    dplyr::collect()
  tbl_species <- dplyr::tbl(db, "species") |>
    dplyr::collect() |>
    dplyr::mutate(
      species_display = paste0(
        .data[[paste0(lang, "_name")]],
        " (",
        .data$scientific_name,
        ")"
      )
    )
  tbl_materials <- dplyr::tbl(db, "materials") |>
    dplyr::collect()

  list(
    "tbl_models" = tbl_models,
    "tbl_species" = tbl_species,
    "tbl_materials" = tbl_materials
  )
}


expand_list <- function(l, env = rlang::caller_env()) {
  rlang::env_bind(env, !!!l)
}

expand_dots <- function(..., env = rlang::caller_env()) {
  rlang::env_bind(env, !!!list(...))
}
