# --- Core ---

pkg <- "sdmEvalToolCore"

conf <- yaml::read_yaml("spec/config.yml")

user_roles <- do.call(rbind, lapply(conf$roles, as.data.frame))
save(user_roles, file = file.path(pkg, "data", "user_roles.rda"), compress="xz")

tables <- do.call(rbind, lapply(names(conf$tables), \(i) {
    l <- conf$tables[[i]]
    data.frame(table=i, do.call(rbind, lapply(names(l), \(j) {
        k <- l[[j]]
        k[sapply(k, is.null)] <- NA_character_
        data.frame(field=j, as.data.frame(k))
    })))
}))
save(tables, file = file.path(pkg, "data", "tables.rda"), compress="xz")

cmp <- conf$components
components <- data.frame(
    component = character(0L),
    description = character(0L),
    mandatory = logical(0L),
    applies_to = character(0L),
    upload = character(0L),
    display = character(0L),
    evaluation = character(0L),
    reporting = character(0L))
for (i in names(cmp)) {
    l <- cmp[[i]]
    c1 <- data.frame(
        component = i,
        description = l$description,
        mandatory = l$mandatory,
        applies_to = l$applies_to,
        upload = NA_character_,
        display = NA_character_,
        evaluation = NA_character_,
        reporting = NA_character_)
    for (j in c("upload", "display", "evaluation", "reporting")) {
        if (!is.null(l[[j]]))
            c1[[j]] <- list(l[[j]])
    }
    components <- rbind(components, c1)
}
save(components, file = file.path(pkg, "data", "components.rda"), compress="xz")

devtools::document(pkg)
rcmdcheck::rcmdcheck(pkg)
# devtools::install(pkg, upgrade = "never")

devtools::load_all(pkg)

# --- UI ---

pkg <- "sdmEvalToolUI"

# o <- setwd(pkg)
# local({ source("data-raw/DATASET.R", local = TRUE) })
# setwd(o)

devtools::document(pkg)
rcmdcheck::rcmdcheck(pkg)
# devtools::install(pkg, upgrade = "never")

devtools::load_all(pkg)
