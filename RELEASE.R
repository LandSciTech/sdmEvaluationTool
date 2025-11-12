# --- Core ---

pkg <- "sdmEvalToolCore"

# update the config file before running data-raw script
file.copy("spec/config.yml", paste0(pkg, "/inst/config/config.yml"))

# update data sets based on config
o <- setwd(pkg)
local({
    source("data-raw/DATASET.R", local = TRUE)
})
setwd(o)

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
