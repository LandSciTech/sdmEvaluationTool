# --- Core --------------------------

pkg <- "sdmEvalToolCore"

# Bump version
file.edit(file.path(pkg, "DESCRIPTION"))

# Add changes to NEWS
file.edit(file.path(pkg, "NEWS.md"))

## Update data -----------------------
# update the config file before running data-raw script
file.copy(
  "spec/config.yml",
  paste0(pkg, "/inst/config.yml"),
  overwrite = TRUE
)

# update data sets based on config
o <- setwd(pkg)
local({
  source("data-raw/DATASET.R", local = TRUE)
})
setwd(o)

## Standard checks ------------------------------------------
devtools::document(pkg)
rcmdcheck::rcmdcheck(pkg)
# devtools::install(pkg, upgrade = "never")
# remotes::install_github("LandSciTech/sdmEvaluationTool/sdmEvalToolCore")

devtools::load_all(pkg)

q <- default_questions
q$values <- sapply(q$values, \(x) paste0(unlist(x), collapse = ","))
write.csv(q, row.names = FALSE, file = "_tmp/default_questions.csv")

# --- UI -----------------------------

pkg <- "sdmEvalToolUI"

# Bump version
file.edit(file.path(pkg, "DESCRIPTION"))

# Add changes to NEWS
file.edit(file.path(pkg, "NEWS.md"))

## Standard checks ------------------------------------------

# It's important to run tests and examples here as they are skipped in the
# local and CI package checks because of the data location.

devtools::test(pkg) # Use Ctrl-Shift-T to test non-interactively in the package
devtools::run_examples(pkg) # Will be skipped in package check because missing data
devtools::document(pkg)

# Package check
rcmdcheck::rcmdcheck(pkg)


# devtools::install(pkg, upgrade = "never")
# remotes::install_github("LandSciTech/sdmEvaluationTool/sdmEvalToolUI")

devtools::load_all(pkg)

# --- Up -----------------------------------

pkg <- "sdmEvalToolUp"

# o <- setwd(pkg)
# local({ source("data-raw/DATASET.R", local = TRUE) })
# setwd(o)

devtools::load_all("sdmEvalToolCore")

## Standard checks ------------------------------------------
devtools::document(pkg)
rcmdcheck::rcmdcheck(pkg)
devtools::run_examples(pkg) # Will be skipped in package check because missing data

# devtools::install(pkg, upgrade = "never")
# remotes::install_github("LandSciTech/sdmEvaluationTool/sdmEvalToolUI")

devtools::load_all(pkg)
