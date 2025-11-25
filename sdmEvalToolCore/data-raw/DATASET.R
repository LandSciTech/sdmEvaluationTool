## code to prepare `DATASET` dataset goes here

conf <- yaml::read_yaml("inst/config/config.yml")

user_roles <- do.call(rbind, lapply(conf$roles, as.data.frame))

tables <- do.call(
    rbind,
    lapply(names(conf$tables), \(i) {
        l <- conf$tables[[i]]
        data.frame(table = i, name = l$name, description = l$description)
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

e <- do.call(rbind, lapply(conf$default_questions, as.data.frame))
colnames(e)[colnames(e) == "body.en"] <- "english"
colnames(e)[colnames(e) == "body.fr"] <- "french"
e$values <- NA_character_
v <- lapply(conf$question_types, \(x) x$values)
for (i in 1:nrow(e)) {
    e$values[[i]] <- if (is.list(v[[e$type[i]]])) {
        list()
    } else {
        list(v[[e$type[i]]])
    }
}
e$english <- gsub("[\r\n\t]", "", e$english)
e$french <- gsub("[\r\n\t]", "", e$french)
default_questions <- e

usethis::use_data(
    components,
    default_questions,
    fields,
    tables,
    user_roles,
    overwrite = TRUE
)
