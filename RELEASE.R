# --- Core ---

pkg <- "sdmEvalToolCore"

config <- yaml::read_yaml("spec/config.yml")
save(config, file = file.path(pkg, "data", "config.rda"), compress="xz")

# o <- setwd(pkg)
# local({ source("data-raw/DATASET.R", local = TRUE) })
# setwd(o)

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
