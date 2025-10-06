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

components <- conf$components
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
