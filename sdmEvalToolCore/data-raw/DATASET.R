## code to prepare `DATASET` dataset goes here

conf <- yaml::read_yaml("inst/config.yml")
# conf <- yaml::read_yaml("../spec/config.yml")

user_roles <- do.call(rbind, lapply(conf$roles, as.data.frame))

tables <- do.call(
  rbind,
  lapply(names(conf$tables), \(i) {
    l <- conf$tables[[i]]
    data.frame(
      table = i,
      name = l$name,
      description = l$description,
      table_constraint = if (is.null(l$table_constraint)) {
        NA_character_
      } else {
        l$table_constraint
      }
    )
  })
)

fields <- do.call(
  rbind,
  lapply(names(conf$tables), \(i) {
    l <- conf$tables[[i]]$fields
    data.frame(
      table = i,
      do.call(
        rbind,
        lapply(names(l), \(j) {
          k <- l[[j]]
          k[sapply(k, is.null)] <- NA_character_
          data.frame(field = j, as.data.frame(k))
        })
      )
    )
  })
)

# Components -------------------------------------------------------------
cmp <- conf$components
components <- data.frame(
  component = character(0L),
  description = character(0L),
  mandatory = logical(0L),
  type = character(0L),
  path = character(0L),
  upload = character(0L),
  display = character(0L),
  evaluation = character(0L)
)
for (i in names(cmp)) {
  l <- cmp[[i]]
  c1 <- data.frame(
    component = i,
    description = l$description,
    mandatory = l$mandatory,
    type = l$type,
    path = l$upload$output$path,
    upload = NA_character_,
    display = NA_character_,
    evaluation = NA_character_
  )
  for (j in c("upload", "display", "evaluation")) {
    if (!is.null(l[[j]])) {
      c1[[j]] <- list(l[[j]])
    }
  }
  components <- rbind(components, c1)
}

# Default Questions ---------------------------------------------------------
e <- do.call(
  rbind,
  lapply(conf$default_questions, \(z) {
    z$values <- NULL
    z$metadata_id <- NULL
    as.data.frame(z)
  })
)
colnames(e)[colnames(e) == "body.en"] <- "english"
colnames(e)[colnames(e) == "body.fr"] <- "french"
e$values <- NA_character_
v <- lapply(conf$question_types, \(x) x$values)
for (i in 1:nrow(e)) {
  if (is.null(conf$default_questions[[i]]$values)) {
    # if (is.list(v[[e$type[i]]])) {
    #     e$values[[i]] <- list()
    # } else {
    e$values[i] <- list(v[[e$type[i]]])
    # }
  } else {
    e$values[i] <- list(conf$default_questions[[i]]$values)
  }
}
e$metadata_id <- NA_character_
for (i in 1:nrow(e)) {
  if (!is.null(conf$default_questions[[i]]$metadata_id)) {
    e$metadata_id[i] <- list(conf$default_questions[[i]]$metadata_id)
  }
}
# e$english <- gsub("[\r\n\t]", "", e$english)
# e$french <- gsub("[\r\n\t]", "", e$french)
default_questions <- e

# Follow-up Questions ------------------------------------------------------
e <- do.call(
  rbind,
  lapply(conf$followup_questions, \(z) {
    z$values <- NULL
    as.data.frame(z)
  })
)
colnames(e)[colnames(e) == "body.en"] <- "english"
colnames(e)[colnames(e) == "body.fr"] <- "french"
e$values <- NA_character_
v <- lapply(conf$question_types, \(x) x$values)
for (i in 1:nrow(e)) {
  if (is.null(conf$followup_questions[[i]]$values)) {
    e$values[i] <- list(v[[e$type[i]]])
    # }
  } else {
    e$values[i] <- list(conf$followup_questions[[i]]$values)
  }
}
followup_questions <- e

# Save data sets -----------------------------------------------------------
usethis::use_data(
  components,
  default_questions,
  followup_questions,
  fields,
  tables,
  user_roles,
  overwrite = TRUE
)
