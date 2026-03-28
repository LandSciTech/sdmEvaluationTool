#' Components
#'
#' @format A data frame with component configuration (some columns are lists).
"components"

#' Default Questions
#'
#' @format A data frame with default questions.
"default_questions"

#' Follow-up Questions
#'
#' @format A data frame with follow-up questions.
"followup_questions"

#' User Roles
#'
#' @format A data frame.
"user_roles"

#' Tables
#'
#' @format A data frame.
"tables"

#' Fields
#'
#' @format A data frame.
"fields"

#' Get Table Fields
#'
#' @param table_name Table name.
#'
#' @return A data frame.
#'
#' @examples
#' get_fields("users")
#' get_fields("components")
#' @export
get_fields <- function(table_name) {
  tab <- sdmEvalToolCore::fields
  table_name <- match.arg(table_name, unique(tab$table), several.ok = FALSE)
  tab[tab$table == table_name, colnames(tab) != "table"]
}

#' Scaffold Table
#'
#' @param table_name Table name.
#'
#' @return A data frame returned invisibly, called for the printed side effects.
#'
#' @examples
#' scaffold_table("users")
#' scaffold_table("materials")
#'
#' @export
scaffold_table <- function(table_name) {
  tt <- get_fields(table_name)
  cat(
    paste0(table_name, " <- data.frame("),
    paste0("    ", tt$field[1:(nrow(tt) - 1)], " = ...,"),
    paste0("    ", tt$field[nrow(tt)], " = ...)"),
    sep = "\n"
  )
  invisible(tt)
}

#' Check Table
#'
#' @param x A data frame.
#' @param table_name Table name.
#' @param dryrun Logical, if checks fail and error is produced,
#'   unless it is a dry run.
#'
#' @return Invisible `TRUE` if all check passed.
#'
#' @examples
#' users <- data.frame(
#'     user_id = c("holden", "draper", "okoye"),
#'     user_name = c("James Holden", "Bobbie Draper", "Elvi Okoye"),
#'     user_email = c(
#'         "jim@rocinante.org",
#'         "bdraper@mcrn.gov",
#'         "okoye@rce.com"
#'     ),
#'     user_affiliation = c("Rocinante", "MCRN", "RCE"),
#'     admin = c(TRUE, FALSE, FALSE)
#' )
#' check_table(users, "users")
#'
#' models <- data.frame(
#'     model_id = "bam_v5_can71",
#'     model_name = "BAM v5 Can 71",
#'     model_description = "BAM version 5 Canada model in BCR 71"
#' )
#' check_table(models, "models")
#'
#' check_table(models, "users", dryrun = TRUE)
#'
#' @export
check_table <- function(x, table_name, dryrun = FALSE) {
  verbose <- sdmevaltool_options()$verbose
  if (verbose >= 1) {
    cat("Checking table", sQuote(table_name))
  }
  tt <- get_fields(table_name)
  ok <- TRUE
  c1 <- setdiff(colnames(x), tt$field)
  if (length(c1) > 0L) {
    ok <- FALSE
    if (verbose >= 2) {
      cat(
        "\n* [FAIL] Additional fields found:",
        paste0(c1, collapse = ", ")
      )
    }
  } else {
    if (verbose >= 2) {
      cat("\n* [OK] Checking additional fields")
    }
  }
  c2 <- setdiff(tt$field, colnames(x))
  if (length(c2) > 0L) {
    ok <- FALSE
    if (verbose >= 2) {
      cat("\n* [FAIL] Missing fields:", paste0(c2, collapse = ", "))
    }
  } else {
    if (verbose >= 2) {
      cat("\n* [OK] Checking missing fields")
    }
  }
  cn <- intersect(tt$field, colnames(x))
  for (i in cn) {
    k <- which(tt$field == i)
    ok_type <- switch(
      tt$type[k],
      "text" = is.character(x[[tt$field[k]]]),
      "boolean" = is.logical(x[[tt$field[k]]]),
      "jsonb" = is.character(x[[tt$field[k]]]),
      "timestamp" = is.integer(x[[tt$field[k]]])
    )
    if (!ok_type) {
      ok <- FALSE
      if (verbose >= 2) {
        cat(
          "\n* [FAIL] Type for field",
          sQuote(tt$field[k]),
          "should be",
          tt$type[k],
          "but found",
          typeof(x[[tt$field[k]]])
        )
      }
    } else {
      if (verbose >= 2) {
        cat(
          "\n* [OK] Checking type for field",
          sQuote(tt$field[k])
        )
      }
    }
  }
  if (verbose >= 1) {
    cat("\n")
  }
  if (!dryrun && !ok) {
    stop("Check for table ", sQuote(table_name), " FAILED")
  }
  invisible(ok)
}

#' Default Species Table
#'
#' @return Data frame.
#'
#' @examples
#' str(default_species_table_canada())
#'
#' @export
default_species_table_canada <- function() {
  x <- utils::read.csv(system.file(
    "species-canada.csv",
    package = "sdmEvalToolCore"
  ))
  x <- x[, c("code", "name_latin", "name_english", "name_french")]
  colnames(x) <- c(
    "species_id",
    "scientific_name",
    "english_name",
    "french_name"
  )
  x
}

#' Make Material ID
#'
#' @param model_id Model ID.
#' @param species_id Species ID.
#' @param component_id Component ID.
#'
#' @examples
#' make_material_id("model1", NA, "predictor_metadata")
#' make_material_id("model1", "CAWA", "predictor_raster")
#'
#' @export
make_material_id <- function(model_id, species_id, component_id, sep = "_") {
  paste0(
    model_id,
    sep,
    ifelse(is.na(species_id), "ALL", as.character(species_id)),
    sep,
    component_id
  )
}

#' Prepare Material Entry
#'
#' @param model_id Model ID.
#' @param species_id Species ID.
#' @param component_id Component ID.
#' @param user_id User ID.
#' @param material_settings Material settings.
#'
#' @examples
#' prepare_material_entry("model1", "CAWA", "predictor_raster", "testuser")
#'
#' @export
prepare_material_entry <- function(
  model_id,
  species_id,
  component_id,
  user_id,
  material_settings = "[]"
) {
  data.frame(
    material_id = make_material_id(
      model_id,
      species_id,
      component_id
    ),
    model_id = model_id,
    species_id = as.character(species_id),
    component_id = component_id,
    material_create_user = user_id,
    material_create_time = timestamp_to(now()),
    material_modify_user = NA_character_,
    material_modify_time = NA_integer_,
    material_settings = material_settings
  )
}
