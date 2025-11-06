# --- Core ---

pkg <- "sdmEvalToolCore"

conf <- yaml::read_yaml("spec/config.yml")

user_roles <- do.call(rbind, lapply(conf$roles, as.data.frame))
save(
    user_roles,
    file = file.path(pkg, "data", "user_roles.rda"),
    compress = "xz"
)

tables <- do.call(
    rbind,
    lapply(names(conf$tables), \(i) {
        l <- conf$tables[[i]]
        data.frame(table = i, name = l$name, description = l$description)
    })
)
save(tables, file = file.path(pkg, "data", "tables.rda"), compress = "xz")

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
save(fields, file = file.path(pkg, "data", "fields.rda"), compress = "xz")

cmp <- conf$components
components <- data.frame(
    component = character(0L),
    description = character(0L),
    mandatory = logical(0L),
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
save(
    components,
    file = file.path(pkg, "data", "components.rda"),
    compress = "xz"
)

default_questions <- data.frame(
    component = character(0L),
    order = integer(0L),
    type = logical(0L),
    english = character(0L),
    frenchy = character(0L)
)
for (i in names(cmp)) {
    e <- cmp[[i]][["evaluation"]]
    if (e$evaluation_allowed) {
        for (j in seq_along(e$questions)) {
            qj <- e$questions[[j]]
            q1 <- data.frame(
                component = i,
                order = qj$order,
                type = qj$type,
                english = qj$question_body$en,
                french = if (is.null(qj$question_body$fr)) {
                    ""
                } else {
                    qj$question_body$fr
                }
            )
            default_questions <- rbind(default_questions, q1)
        }
    }
}
save(
    default_questions,
    file = file.path(pkg, "data", "default_questions.rda"),
    compress = "xz"
)

devtools::document(pkg)
rcmdcheck::rcmdcheck(pkg)
# devtools::install(pkg, upgrade = "never")
# remotes::install_github("LandSciTech/sdmEvaluationTool/sdmEvalToolCore")

devtools::load_all(pkg)

# --- UI ---

pkg <- "sdmEvalToolUI"

# o <- setwd(pkg)
# local({ source("data-raw/DATASET.R", local = TRUE) })
# setwd(o)

devtools::document(pkg)
rcmdcheck::rcmdcheck(pkg)
# devtools::install(pkg, upgrade = "never")
# remotes::install_github("LandSciTech/sdmEvaluationTool/sdmEvalToolUI")

devtools::load_all(pkg)
